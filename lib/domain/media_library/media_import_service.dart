import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/media_library/media_import_models.dart';
import 'package:nle_editor/domain/media_library/media_project_path_service.dart';
import 'package:nle_editor/domain/media_library/media_type_detector.dart';
import 'package:nle_editor/platform/media/native_media_scanner_service.dart';

class MediaImportService {
  final MediaAssetRepository repository;
  final MediaProjectPathService pathService;
  final MediaTypeDetector typeDetector;
  final NativeMediaScannerService nativeScanner;

  const MediaImportService({
    required this.repository,
    this.pathService = const MediaProjectPathService(),
    this.typeDetector = const MediaTypeDetector(),
    this.nativeScanner = const NativeMediaScannerService(),
  });

  Future<List<String>> pickAndImportMedia(String projectId) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm',
        'jpg', 'jpeg', 'png', 'webp', 'heic',
        'mp3', 'wav', 'm4a', 'aac', 'flac',
      ],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return [];

    final paths = result.files.map((f) => f.path).whereType<String>().toList();
    if (paths.isEmpty) return [];

    final request = NleMediaImportRequest(
      projectId: projectId,
      sourcePaths: paths,
      importSource: NleMediaImportSource.filePicker,
      storageMode: NleMediaStorageMode.copiedIntoProject,
      generateThumbnails: true,
      generateWaveforms: true,
      detectDuplicates: true,
      createProxyPlaceholder: false,
    );

    final importResult = await importFiles(request);
    
    final failedItems = importResult.items.where((item) => !item.success).toList();
    if (failedItems.isNotEmpty) {
      throw Exception('Import failed: ${failedItems.first.error}');
    }

    return importResult.items
        .where((item) => item.success)
        .map((item) => item.asset!.id)
        .toList();
  }

  Future<NleMediaImportResult> importFiles(
    NleMediaImportRequest request,
  ) async {
    final results = <NleMediaImportItemResult>[];

    for (final sourcePath in request.sourcePaths) {
      try {
        final item = await _importSingleFile(
          request: request,
          sourcePath: sourcePath,
        );

        results.add(item);
      } catch (error, st) {
        print('MediaImportService error importing single file: $error\n$st');
        results.add(
          NleMediaImportItemResult(
            sourcePath: sourcePath,
            success: false,
            duplicate: false,
            error: error.toString(),
          ),
        );
      }
    }

    return NleMediaImportResult(items: results);
  }

  Future<NleMediaImportItemResult> _importSingleFile({
    required NleMediaImportRequest request,
    required String sourcePath,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      return NleMediaImportItemResult(
        sourcePath: sourcePath,
        success: false,
        duplicate: false,
        error: 'File does not exist.',
      );
    }

    // Check duplicates if enabled
    if (request.detectDuplicates) {
      final existingAssets = await repository.getAssets(request.projectId);
      for (final asset in existingAssets) {
        if (asset.originalPath == sourcePath) {
          // If copied, verify the copied file actually exists. If not, re-import.
          final checkPath = asset.projectPath ?? asset.originalPath;
          if (checkPath != null && await File(checkPath).exists()) {
            // Update availability to available
            if (asset.availability != NleMediaAvailability.available) {
              await repository.setAvailability(
                assetId: asset.id,
                availability: NleMediaAvailability.available,
              );
            }
            return NleMediaImportItemResult(
              sourcePath: sourcePath,
              asset: asset,
              success: true,
              duplicate: true,
            );
          }
        }
      }
    }

    final assetId = const Uuid().v4();
    final type = typeDetector.detectFromPath(sourcePath);
    final stat = await sourceFile.stat();
    final scan = await nativeScanner.scan(sourcePath);

    final projectPath =
        request.storageMode == NleMediaStorageMode.copiedIntoProject
            ? await pathService.createImportedMediaPath(
                projectId: request.projectId,
                type: type,
                assetId: assetId,
                originalPath: sourcePath,
              )
            : null;

    if (projectPath != null) {
      final destFile = File(projectPath);
      if (!await destFile.parent.exists()) {
        await destFile.parent.create(recursive: true);
      }
      await sourceFile.copy(projectPath);
    }

    final editablePath = projectPath ?? sourcePath;

    String? thumbnailPath;

    if (request.generateThumbnails &&
        (type == NleMediaAssetType.video || type == NleMediaAssetType.image)) {
      final thumbTarget = await pathService.createThumbnailPath(
        projectId: request.projectId,
        assetId: assetId,
      );

      final thumbDir = Directory(p.dirname(thumbTarget));
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      thumbnailPath = await nativeScanner.generateThumbnail(
        path: editablePath,
        outputPath: thumbTarget,
        width: 512,
        height: 512,
      );
    }

    final importedAt = DateTime.now();
    final fileName = p.basename(sourcePath);
    final extension = p.extension(sourcePath).replaceFirst('.', '').toLowerCase();

    final asset = NleMediaAsset(
      id: assetId,
      projectId: request.projectId,
      displayName: fileName,
      type: scan.type == NleMediaAssetType.unknown ? type : scan.type,
      importSource: request.importSource,
      storageMode: request.storageMode,
      availability: NleMediaAvailability.available,
      originalPath: sourcePath,
      projectPath: projectPath,
      thumbnailPath: thumbnailPath,
      waveformCacheId: null,
      proxyPath: request.createProxyPlaceholder
          ? await pathService.createProxyPath(
              projectId: request.projectId,
              assetId: assetId,
            )
          : null,
      proxyStatus: request.createProxyPlaceholder
          ? NleProxyStatus.queued
          : NleProxyStatus.none,
      usageState: NleMediaUsageState.unused,
      fileInfo: NleMediaFileInfo(
        fileName: fileName,
        extension: extension,
        fileSizeBytes: stat.size,
        checksum: null,
        fileCreatedAt: stat.changed,
        fileModifiedAt: stat.modified,
      ),
      videoInfo: NleMediaVideoInfo(
        width: scan.width,
        height: scan.height,
        fps: scan.fps,
        codec: scan.videoCodec,
        colorSpace: scan.colorSpace,
        hasHdr: scan.hasHdr,
      ),
      audioInfo: NleMediaAudioInfo(
        sampleRate: scan.sampleRate,
        channelCount: scan.channelCount,
        codec: scan.audioCodec,
        bitrate: scan.bitrate,
      ),
      timecodeInfo: NleMediaTimecodeInfo(
        fps: scan.fps <= 0 ? 30.0 : scan.fps,
        durationMicros: scan.durationMicros,
        startTimecodeMicros: 0,
      ),
      notes: null,
      tags: const [],
      importedAt: importedAt,
      updatedAt: importedAt,
      version: 1,
    );

    await repository.saveAsset(asset);

    // Link to target bin if specified
    if (request.targetBinId != null) {
      await repository.linkAssetToBin(
        assetId: assetId,
        binId: request.targetBinId!,
      );
    } else {
      // By default, link to type-specific default bins
      final bins = await repository.getBins(request.projectId);
      final targetBinName = switch (asset.type) {
        NleMediaAssetType.video => 'Videos',
        NleMediaAssetType.audio => 'Audio',
        NleMediaAssetType.image => 'Images',
        _ => null,
      };

      if (targetBinName != null && bins.isNotEmpty) {
        final targetBin = bins.firstWhere((b) => b.name == targetBinName, orElse: () => bins.first);
        await repository.linkAssetToBin(
          assetId: assetId,
          binId: targetBin.id,
        );
      }
    }

    return NleMediaImportItemResult(
      sourcePath: sourcePath,
      asset: asset,
      success: true,
      duplicate: false,
    );
  }
}
