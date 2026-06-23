import 'dart:io';

import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';
import 'package:nle_editor/domain/storage/project_storage_report.dart';

class CacheStorageService {
  final ProjectStorageService projectStorageService;
  final AssetRepository assetRepository;

  CacheStorageService({
    required this.projectStorageService,
    required this.assetRepository,
  });

  Future<ProjectStorageReport> calculateProjectStorage(String projectId) async {
    final folders = await projectStorageService.getProjectFolders(projectId);

    final thumbnails = await _calculateFolder(folders.thumbnails);
    final timelineThumbnails = await _calculateFolder(folders.timelineThumbnails);
    final waveforms = await _calculateFolder(folders.waveforms);
    final proxies = await _calculateFolder(folders.proxies);
    final exports = await _calculateFolder(folders.exports);
    final temp = await _calculateFolder(folders.temp);
    final autosaves = await _calculateFolder(folders.autosaves);

    final knownBytes = thumbnails.bytes +
        timelineThumbnails.bytes +
        waveforms.bytes +
        proxies.bytes +
        exports.bytes +
        temp.bytes +
        autosaves.bytes;

    final root = await _calculateFolder(folders.root);

    final otherBytes = (root.bytes - knownBytes).clamp(0, 1 << 62);
    final otherFiles = (root.files -
            thumbnails.files -
            timelineThumbnails.files -
            waveforms.files -
            proxies.files -
            exports.files -
            temp.files -
            autosaves.files)
        .clamp(0, 1 << 62);

    return ProjectStorageReport(
      projectId: projectId,
      totalBytes: root.bytes,
      thumbnailsBytes: thumbnails.bytes,
      timelineThumbnailsBytes: timelineThumbnails.bytes,
      waveformsBytes: waveforms.bytes,
      proxiesBytes: proxies.bytes,
      exportsBytes: exports.bytes,
      tempBytes: temp.bytes,
      autosavesBytes: autosaves.bytes,
      otherBytes: otherBytes,
      thumbnailFileCount: thumbnails.files,
      timelineThumbnailFileCount: timelineThumbnails.files,
      waveformFileCount: waveforms.files,
      proxyFileCount: proxies.files,
      exportFileCount: exports.files,
      tempFileCount: temp.files,
      autosaveFileCount: autosaves.files,
      otherFileCount: otherFiles,
      calculatedAt: DateTime.now(),
    );
  }

  Future<CacheClearResult> clearThumbnails(String projectId) async {
    final folders = await projectStorageService.getProjectFolders(projectId);

    final deleted = await _deleteDirectoryContents(folders.thumbnails);
    final deletedTimeline = await _deleteDirectoryContents(folders.timelineThumbnails);

    await _ensureDirectory(folders.thumbnails);
    await _ensureDirectory(folders.timelineThumbnails);

    final assets = await assetRepository.getProjectAssets(projectId);

    for (final asset in assets) {
      if (asset.fileType == 'video' || asset.fileType == 'image') {
        await assetRepository.updateAssetFields(
          asset.id,
          const AssetsCompanion(
            thumbnailPath: Value<String?>(null),
            thumbnailStatus: Value('pending'),
          ),
        );
      }
    }

    return CacheClearResult(
      projectId: projectId,
      action: 'clear_thumbnails',
      deletedBytes: deleted.bytes + deletedTimeline.bytes,
      deletedFiles: deleted.files + deletedTimeline.files,
      success: true,
      message: 'Thumbnail cache cleared.',
    );
  }

  Future<CacheClearResult> clearWaveforms(String projectId) async {
    final folders = await projectStorageService.getProjectFolders(projectId);
    final deleted = await _deleteDirectoryContents(folders.waveforms);

    await _ensureDirectory(folders.waveforms);

    final assets = await assetRepository.getProjectAssets(projectId);

    for (final asset in assets) {
      if (asset.fileType == 'video' || asset.fileType == 'audio' || asset.hasAudio) {
        await assetRepository.updateAssetFields(
          asset.id,
          const AssetsCompanion(
            waveformPath: Value<String?>(null),
            waveformStatus: Value('pending'),
          ),
        );
      }
    }

    return CacheClearResult(
      projectId: projectId,
      action: 'clear_waveforms',
      deletedBytes: deleted.bytes,
      deletedFiles: deleted.files,
      success: true,
      message: 'Waveform cache cleared.',
    );
  }

  Future<CacheClearResult> clearProxies(String projectId) async {
    final folders = await projectStorageService.getProjectFolders(projectId);
    final deleted = await _deleteDirectoryContents(folders.proxies);

    await _ensureDirectory(folders.proxies);

    final assets = await assetRepository.getProjectAssets(projectId);

    for (final asset in assets) {
      if (asset.fileType == 'video') {
        await assetRepository.updateAssetFields(
          asset.id,
          AssetsCompanion(
            proxyPath: const Value<String?>(null),
            proxyStatus: Value(_proxyStatusAfterDelete(asset)),
            proxyWidth: const Value<int?>(null),
            proxyHeight: const Value<int?>(null),
            proxyCodec: const Value<String?>(null),
            proxyFileSize: const Value<int?>(null),
          ),
        );
      }
    }

    return CacheClearResult(
      projectId: projectId,
      action: 'clear_proxies',
      deletedBytes: deleted.bytes,
      deletedFiles: deleted.files,
      success: true,
      message: 'Proxy cache cleared.',
    );
  }

  Future<CacheClearResult> clearTemporaryExportFiles(String projectId) async {
    final folders = await projectStorageService.getProjectFolders(projectId);
    final deleted = await _deleteDirectoryContents(folders.temp);

    await _ensureDirectory(folders.temp);

    return CacheClearResult(
      projectId: projectId,
      action: 'clear_temp',
      deletedBytes: deleted.bytes,
      deletedFiles: deleted.files,
      success: true,
      message: 'Temporary render files cleared.',
    );
  }

  Future<CacheClearResult> clearOldAutosaves(
    String projectId, {
    int keepNewestCount = 5,
    bool keepLatest = true,
  }) async {
    final folders = await projectStorageService.getProjectFolders(projectId);
    final autosaveDir = Directory(folders.autosaves);

    if (!await autosaveDir.exists()) {
      await autosaveDir.create(recursive: true);

      return CacheClearResult(
        projectId: projectId,
        action: 'clear_old_autosaves',
        deletedBytes: 0,
        deletedFiles: 0,
        success: true,
        message: 'No autosaves to clear.',
      );
    }

    final files = <File>[];

    await for (final entity in autosaveDir.list(recursive: false, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.json')) {
        files.add(entity);
      }
    }

    files.sort((a, b) {
      final aModified = a.lastModifiedSync();
      final bModified = b.lastModifiedSync();
      return bModified.compareTo(aModified);
    });

    final protectedPaths = <String>{};

    if (keepLatest) {
      protectedPaths.add('${folders.autosaves}/latest.autosave.json');
    }

    for (var i = 0; i < files.length && i < keepNewestCount; i++) {
      protectedPaths.add(files[i].path);
    }

    var deletedBytes = 0;
    var deletedFiles = 0;

    for (final file in files) {
      if (protectedPaths.contains(file.path)) {
        continue;
      }

      try {
        final length = await file.length();
        await file.delete();
        deletedBytes += length;
        deletedFiles++;
      } catch (_) {}
    }

    return CacheClearResult(
      projectId: projectId,
      action: 'clear_old_autosaves',
      deletedBytes: deletedBytes,
      deletedFiles: deletedFiles,
      success: true,
      message: 'Old autosaves cleared.',
    );
  }

  Future<CacheClearResult> deleteProjectCacheSafely(
    String projectId, {
    bool includeExports = false,
  }) async {
    final folders = await projectStorageService.getProjectFolders(projectId);

    var deletedBytes = 0;
    var deletedFiles = 0;

    final thumbnail = await _deleteDirectoryContents(folders.thumbnails);
    final timelineThumbnail = await _deleteDirectoryContents(folders.timelineThumbnails);
    final waveform = await _deleteDirectoryContents(folders.waveforms);
    final proxy = await _deleteDirectoryContents(folders.proxies);
    final temp = await _deleteDirectoryContents(folders.temp);
    final autosaves = await _deleteDirectoryContents(folders.autosaves);

    deletedBytes += thumbnail.bytes;
    deletedBytes += timelineThumbnail.bytes;
    deletedBytes += waveform.bytes;
    deletedBytes += proxy.bytes;
    deletedBytes += temp.bytes;
    deletedBytes += autosaves.bytes;

    deletedFiles += thumbnail.files;
    deletedFiles += timelineThumbnail.files;
    deletedFiles += waveform.files;
    deletedFiles += proxy.files;
    deletedFiles += temp.files;
    deletedFiles += autosaves.files;

    if (includeExports) {
      final exports = await _deleteDirectoryContents(folders.exports);
      deletedBytes += exports.bytes;
      deletedFiles += exports.files;
    }

    await _recreateProjectCacheFolders(folders);

    final assets = await assetRepository.getProjectAssets(projectId);

    for (final asset in assets) {
      await assetRepository.updateAssetFields(
        asset.id,
        AssetsCompanion(
          thumbnailPath: const Value<String?>(null),
          waveformPath: const Value<String?>(null),
          proxyPath: const Value<String?>(null),
          thumbnailStatus: Value(
            asset.fileType == 'video' || asset.fileType == 'image'
                ? 'pending'
                : 'not_needed',
          ),
          waveformStatus: Value(
            asset.fileType == 'video' || asset.fileType == 'audio' || asset.hasAudio
                ? 'pending'
                : 'not_needed',
          ),
          proxyStatus: Value(
            asset.fileType == 'video' ? _proxyStatusAfterDelete(asset) : 'not_needed',
          ),
          proxyWidth: const Value<int?>(null),
          proxyHeight: const Value<int?>(null),
          proxyCodec: const Value<String?>(null),
          proxyFileSize: const Value<int?>(null),
        ),
      );
    }

    return CacheClearResult(
      projectId: projectId,
      action: includeExports ? 'delete_project_cache_with_exports' : 'delete_project_cache',
      deletedBytes: deletedBytes,
      deletedFiles: deletedFiles,
      success: true,
      message: includeExports
          ? 'Project cache and app-generated exports cleared.'
          : 'Project cache cleared. Export files were kept.',
    );
  }

  Future<bool> hasLowStorageWarning({
    required int availableBytes,
    required int estimatedNeededBytes,
  }) async {
    return availableBytes < estimatedNeededBytes;
  }

  String _proxyStatusAfterDelete(Asset asset) {
    final width = asset.width ?? 0;
    final height = asset.height ?? 0;

    final isLargeResolution = width >= 1920 || height >= 1080;
    final isLargeFile = asset.fileSize > 300 * 1024 * 1024;

    if (isLargeResolution || isLargeFile) {
      return 'needed';
    }

    return 'not_needed';
  }

  Future<FolderStorageStat> _calculateFolder(String path) async {
    final directory = Directory(path);

    if (!await directory.exists()) {
      return FolderStorageStat.empty;
    }

    var bytes = 0;
    var files = 0;

    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            bytes += await entity.length();
            files++;
          } catch (_) {}
        }
      }
    } catch (_) {
      return FolderStorageStat.empty;
    }

    return FolderStorageStat(
      bytes: bytes,
      files: files,
    );
  }

  Future<FolderStorageStat> _deleteDirectoryContents(String path) async {
    final directory = Directory(path);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
      return FolderStorageStat.empty;
    }

    var deletedBytes = 0;
    var deletedFiles = 0;

    try {
      await for (final entity in directory.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          try {
            final length = await entity.length();
            await entity.delete();
            deletedBytes += length;
            deletedFiles++;
          } catch (_) {}
        } else if (entity is Directory) {
          final stat = await _calculateFolder(entity.path);

          try {
            await entity.delete(recursive: true);
            deletedBytes += stat.bytes;
            deletedFiles += stat.files;
          } catch (_) {}
        }
      }
    } catch (_) {}

    return FolderStorageStat(
      bytes: deletedBytes,
      files: deletedFiles,
    );
  }

  Future<void> _ensureDirectory(String path) async {
    final directory = Directory(path);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<void> _recreateProjectCacheFolders(ProjectStoragePaths folders) async {
    await _ensureDirectory(folders.root);
    await _ensureDirectory(folders.thumbnails);
    await _ensureDirectory(folders.timelineThumbnails);
    await _ensureDirectory(folders.waveforms);
    await _ensureDirectory(folders.proxies);
    await _ensureDirectory(folders.exports);
    await _ensureDirectory(folders.autosaves);
    await _ensureDirectory(folders.temp);
  }
}
