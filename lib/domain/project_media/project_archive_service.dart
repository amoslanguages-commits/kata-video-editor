import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/data/repositories/project_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/project_media/project_media_health_service.dart';
import 'package:nle_editor/domain/project_media/project_media_management_models.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

/// 34C-PRO: Creates portable local archives for projects.
///
/// Archive format is a folder package, not a zip, to avoid large in-memory zip
/// creation on mobile devices. A future export layer can zip this folder if the
/// user explicitly requests a single package file.
class ProjectArchiveService {
  final ProjectRepository projectRepository;
  final MediaAssetRepository mediaRepository;
  final TimelineRepository timelineRepository;
  final ProjectStorageService storageService;
  final ProjectMediaHealthService healthService;

  const ProjectArchiveService({
    required this.projectRepository,
    required this.mediaRepository,
    required this.timelineRepository,
    required this.storageService,
    required this.healthService,
  });

  Future<NleProjectArchiveResult> createArchive({
    required String projectId,
    NleProjectArchiveMode mode = NleProjectArchiveMode.usedMediaOnly,
    String? destinationDirectoryPath,
  }) async {
    final project = await projectRepository.getProject(projectId);
    if (project == null) {
      throw StateError('Project not found: $projectId');
    }

    final health = await healthService.scanProject(projectId);
    final allAssets = await mediaRepository.getAssets(projectId);
    final clips = await timelineRepository.getProjectClips(projectId);
    final usedAssetIds = clips
        .map((clip) => clip.assetId)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    final archiveAssets = switch (mode) {
      NleProjectArchiveMode.fullProject => allAssets,
      NleProjectArchiveMode.usedMediaOnly =>
        allAssets.where((asset) => usedAssetIds.contains(asset.id)).toList(),
      NleProjectArchiveMode.manifestOnly => <NleMediaAsset>[],
    };

    final paths = await storageService.getProjectFolders(projectId);
    final destinationRoot = destinationDirectoryPath ?? paths.exports;
    final safeProjectName = storageService.sanitizeFileName(project.name);
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final archiveRoot = p.join(
      destinationRoot,
      '${safeProjectName}_archive_$timestamp.kata_project',
    );

    final archiveDir = Directory(archiveRoot);
    final mediaDir = Directory(p.join(archiveRoot, 'media'));
    final sidecarDir = Directory(p.join(archiveRoot, 'sidecars'));

    await archiveDir.create(recursive: true);
    await mediaDir.create(recursive: true);
    await sidecarDir.create(recursive: true);

    var copiedFiles = 0;
    var skippedFiles = 0;
    var copiedBytes = 0;
    final warnings = <String>[];

    for (final asset in archiveAssets) {
      final sourcePath = asset.resolvedEditPath;
      if (sourcePath == null || sourcePath.trim().isEmpty) {
        skippedFiles++;
        warnings.add('Skipped ${asset.displayName}: no source path.');
        continue;
      }

      final source = File(sourcePath);
      if (!await source.exists()) {
        skippedFiles++;
        warnings.add('Skipped ${asset.displayName}: missing file at $sourcePath.');
        continue;
      }

      final fileName = _archiveFileName(asset);
      final destination = File(p.join(mediaDir.path, fileName));
      await destination.parent.create(recursive: true);
      await source.copy(destination.path);
      copiedFiles++;
      copiedBytes += await destination.length();

      copiedBytes += await _copyOptionalSidecar(
        sourcePath: asset.thumbnailPath,
        destinationDirectory: sidecarDir.path,
        prefix: '${asset.id}_thumbnail',
      );
      copiedBytes += await _copyOptionalSidecar(
        sourcePath: asset.proxyPath,
        destinationDirectory: sidecarDir.path,
        prefix: '${asset.id}_proxy',
      );
    }

    final manifest = _buildManifest(
      project: project,
      mode: mode,
      assets: allAssets,
      clips: clips,
      storage: health.storage.toJson(),
    );

    final manifestFile = File(p.join(archiveRoot, 'kata_project_manifest.json'));
    await manifestFile.writeAsString(manifest.toJsonString(), flush: true);

    final healthFile = File(p.join(archiveRoot, 'media_health_report.json'));
    await healthFile.writeAsString(health.toJsonString(), flush: true);

    return NleProjectArchiveResult(
      archiveRootPath: archiveRoot,
      manifestPath: manifestFile.path,
      copiedFiles: copiedFiles,
      skippedFiles: skippedFiles,
      copiedBytes: copiedBytes,
      warnings: warnings,
    );
  }

  NleProjectArchiveManifest _buildManifest({
    required db.Project project,
    required NleProjectArchiveMode mode,
    required List<NleMediaAsset> assets,
    required List<db.Clip> clips,
    required Map<String, dynamic> storage,
  }) {
    return NleProjectArchiveManifest(
      schema: 'kata.project_archive',
      version: 1,
      projectId: project.id,
      projectName: project.name,
      createdAt: DateTime.now(),
      mode: mode,
      assets: assets.map((asset) => asset.toJson()).toList(),
      clips: clips.map(_clipToJson).toList(),
      storage: storage,
    );
  }

  Map<String, dynamic> _clipToJson(db.Clip clip) {
    return {
      'id': clip.id,
      'projectId': clip.projectId,
      'trackId': clip.trackId,
      'assetId': clip.assetId,
      'clipType': clip.clipType,
      'timelineStartMicros': clip.timelineStartMicros,
      'timelineEndMicros': clip.timelineEndMicros,
      'sourceInMicros': clip.sourceInMicros,
      'sourceOutMicros': clip.sourceOutMicros,
      'speed': clip.speed,
      'isReversed': clip.isReversed,
      'isLinked': clip.isLinked,
      'linkedClipId': clip.linkedClipId,
    };
  }

  String _archiveFileName(NleMediaAsset asset) {
    final rawName = asset.fileInfo.fileName.trim().isNotEmpty
        ? asset.fileInfo.fileName
        : asset.displayName;
    final safeName = rawName.replaceAll(RegExp(r'[^\w\s\.\-\(\)]'), '_');
    return '${asset.id}_$safeName';
  }

  Future<int> _copyOptionalSidecar({
    required String? sourcePath,
    required String destinationDirectory,
    required String prefix,
  }) async {
    if (sourcePath == null || sourcePath.trim().isEmpty) return 0;
    final source = File(sourcePath);
    if (!await source.exists()) return 0;

    final extension = p.extension(source.path);
    final destination = File(p.join(destinationDirectory, '$prefix$extension'));
    await source.copy(destination.path);
    return destination.length();
  }
}
