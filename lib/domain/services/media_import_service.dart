import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/data/repositories/project_repository.dart';
import 'package:nle_editor/domain/services/media_metadata_service.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';
import 'package:nle_editor/domain/services/thumbnail_service.dart';
import 'package:nle_editor/domain/services/waveform_service.dart';
import 'package:nle_editor/domain/services/background_media_generation_queue.dart';

class MediaImportService {
  final AssetRepository _assetRepository;
  final ProjectRepository _projectRepository;
  final ProjectStorageService _projectStorageService;
  final MediaMetadataService _metadataService;
  final ThumbnailService _thumbnailService;
  final BackgroundMediaGenerationQueue _generationQueue;
  final AppPermissionService _permissionService;

  MediaImportService(
    this._assetRepository,
    this._projectRepository,
    this._projectStorageService,
    this._metadataService,
    this._thumbnailService,
    WaveformService _,
    this._generationQueue,
    this._permissionService,
  );

  static const _uuid = Uuid();

  Future<List<String>> pickAndImportMedia(String projectId, {String mediaType = 'all'}) async {
    // 1. Request granular permission based on the requested type
    String permissionType;
    switch (mediaType) {
      case 'video':
        permissionType = AppPermissionType.mediaVideos;
        break;
      case 'audio':
        permissionType = AppPermissionType.mediaAudio;
        break;
      case 'image':
        permissionType = AppPermissionType.mediaImages;
        break;
      default:
        permissionType = AppPermissionType.mediaLibrary; // fallback to general
    }

    final hasPermission = await _permissionService.ensureHasAccess(permissionType, projectId: projectId);
    if (!hasPermission) {
      throw Exception('Permission denied to access $mediaType media.');
    }

    // 2. Launch FilePicker with appropriate type filtering
    FileType fileType = FileType.custom;
    List<String>? allowedExtensions;

    switch (mediaType) {
      case 'video':
        fileType = FileType.video;
        break;
      case 'audio':
        fileType = FileType.audio;
        break;
      case 'image':
        fileType = FileType.image;
        break;
      default:
        fileType = FileType.custom;
        allowedExtensions = [
          'mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm',
          'jpg', 'jpeg', 'png', 'webp', 'heic',
          'mp3', 'wav', 'm4a', 'aac', 'flac',
        ];
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: fileType,
      allowedExtensions: allowedExtensions,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return [];

    final folders = await _projectStorageService.getProjectFolders(projectId);
    final importedIds = <String>[];

    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;

      // De-duplicate: skip if already imported
      final existing =
          await _assetRepository.getAssetByOriginalPath(projectId, path);
      if (existing != null) {
        importedIds.add(existing.id);
        continue;
      }

      final assetId = _uuid.v4();
      final fileType = _inferFileType(file.extension ?? p.extension(path));
      final actualFile = File(path);

      var size = file.size;
      DateTime? modifiedAt;

      try {
        if (await actualFile.exists()) {
          size = await actualFile.length();
          modifiedAt = await actualFile.lastModified();
        }
      } catch (_) {}

      await _assetRepository.insertAsset(
        AssetsCompanion.insert(
          id: assetId,
          projectId: projectId,
          originalPath: path,
          fileName: file.name,
          fileSize: Value(size),
          fileType: fileType,
          hasVideo: Value(fileType == 'video'),
          hasAudio: Value(fileType == 'audio' || fileType == 'video'),
          importStatus: const Value('scanning'),
          thumbnailStatus:
              Value(fileType == 'audio' ? 'not_needed' : 'pending'),
          waveformStatus: Value(fileType == 'image' ? 'not_needed' : 'pending'),
          proxyStatus: Value(fileType == 'video' ? 'needed' : 'not_needed'),
          lastKnownModifiedAt: Value(modifiedAt),
        ),
      );

      importedIds.add(assetId);

      // Scan metadata + generate caches (async, non-blocking for caller)
      _scanAndGenerateCaches(
        assetId: assetId,
        sourcePath: path,
        fileType: fileType,
        folders: folders,
      ).ignore();
    }

    if (importedIds.isNotEmpty) {
      await _projectRepository.touchProject(projectId);
    }

    return importedIds;
  }

  Future<void> _scanAndGenerateCaches({
    required String assetId,
    required String sourcePath,
    required String fileType,
    required ProjectStoragePaths folders,
  }) async {
    try {
      final metadata = await _metadataService.extract(
        path: sourcePath,
        fileType: fileType,
      );

      await _assetRepository.updateAssetFields(
        assetId,
        AssetsCompanion(
          durationMicros: Value(metadata.durationMicros),
          width: Value(metadata.width),
          height: Value(metadata.height),
          frameRate: Value(metadata.frameRate),
          codec: Value(metadata.codec),
          audioCodec: Value(metadata.audioCodec),
          audioChannels: Value(metadata.audioChannels),
          audioSampleRate: Value(metadata.audioSampleRate),
          rotation: Value(metadata.rotation),
          hasVideo: Value(metadata.hasVideo),
          hasAudio: Value(metadata.hasAudio),
          mimeType: Value(metadata.mimeType),
          importStatus: const Value('ready'),
        ),
      );

      if (fileType == 'image') {
        await _assetRepository.updateAssetFields(
          assetId,
          const AssetsCompanion(thumbnailStatus: Value('generating')),
        );

        final thumbnailPath = await _thumbnailService.generateThumbnail(
          sourcePath: sourcePath,
          outputDirectory: folders.thumbnails,
          assetId: assetId,
          fileType: fileType,
        );

        await _assetRepository.updateAssetFields(
          assetId,
          AssetsCompanion(
            thumbnailPath: Value(thumbnailPath),
            thumbnailStatus: Value(thumbnailPath == null ? 'failed' : 'ready'),
          ),
        );
      } else if (fileType == 'video') {
        _generationQueue.queueThumbnailStrip(
          assetId: assetId,
          sourcePath: sourcePath,
          outputDirectory: folders.thumbnails,
          durationMicros: metadata.durationMicros ?? 0,
        );
        _generationQueue.queueWaveform(
          assetId: assetId,
          sourcePath: sourcePath,
          outputDirectory: folders.waveforms,
        );
      } else if (fileType == 'audio') {
        _generationQueue.queueWaveform(
          assetId: assetId,
          sourcePath: sourcePath,
          outputDirectory: folders.waveforms,
        );
      }
    } catch (e) {
      await _assetRepository.updateAssetFields(
        assetId,
        AssetsCompanion(
          importStatus: const Value('failed'),
          errorMessage: Value(e.toString()),
        ),
      );
    }
  }

  String _inferFileType(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');

    const videoExts = {'mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'};
    const imageExts = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
    const audioExts = {'mp3', 'wav', 'm4a', 'aac', 'flac'};

    if (videoExts.contains(ext)) return 'video';
    if (imageExts.contains(ext)) return 'image';
    if (audioExts.contains(ext)) return 'audio';
    return 'unknown';
  }
}
