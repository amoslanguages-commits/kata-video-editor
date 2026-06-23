import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/domain/cache/cache_index_models.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

class CacheIndexService {
  final ProjectStorageService projectStorageService;
  final AssetRepository assetRepository;

  const CacheIndexService({
    required this.projectStorageService,
    required this.assetRepository,
  });

  Future<String> indexPathForProject(String projectId) async {
    final folders = await projectStorageService.getProjectFolders(projectId);
    return p.join(folders.root, 'cache_index.json');
  }

  Future<CacheIndexSnapshot> loadIndex(String projectId) async {
    final indexPath = await indexPathForProject(projectId);
    final file = File(indexPath);
    if (!await file.exists()) {
      return rebuildIndex(projectId);
    }
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return CacheIndexSnapshot.fromJson(json);
    } catch (_) {
      return rebuildIndex(projectId);
    }
  }

  Future<CacheIndexSnapshot> rebuildIndex(String projectId) async {
    final folders = await projectStorageService.getProjectFolders(projectId);
    final assets = await assetRepository.getProjectAssets(projectId);
    final entriesByPath = <String, CacheIndexEntry>{};

    Future<void> addReferencedAssetEntry({
      required Asset asset,
      required String? path,
      required String kind,
      Map<String, dynamic> metadata = const {},
    }) async {
      final normalized = _normalizePath(path);
      if (normalized == null) return;
      entriesByPath[normalized] = await _entryForFile(
        projectId: projectId,
        assetId: asset.id,
        kind: kind,
        path: normalized,
        referencedByDatabase: true,
        metadata: {
          'source': 'asset_reference',
          'fileName': asset.fileName,
          ...metadata,
        },
      );
    }

    for (final asset in assets) {
      await addReferencedAssetEntry(
        asset: asset,
        path: asset.thumbnailPath,
        kind: CacheEntryKind.thumbnail,
      );
      await addReferencedAssetEntry(
        asset: asset,
        path: asset.waveformPath,
        kind: CacheEntryKind.waveform,
      );
      await addReferencedAssetEntry(
        asset: asset,
        path: asset.proxyPath,
        kind: CacheEntryKind.proxy,
        metadata: {
          if (asset.proxyWidth != null) 'proxyWidth': asset.proxyWidth,
          if (asset.proxyHeight != null) 'proxyHeight': asset.proxyHeight,
          if (asset.proxyCodec != null) 'proxyCodec': asset.proxyCodec,
        },
      );
    }

    await _scanFolder(
      projectId: projectId,
      rootPath: folders.thumbnails,
      kind: CacheEntryKind.thumbnail,
      entriesByPath: entriesByPath,
    );
    await _scanFolder(
      projectId: projectId,
      rootPath: folders.timelineThumbnails,
      kind: CacheEntryKind.timelineThumbnail,
      entriesByPath: entriesByPath,
    );
    await _scanFolder(
      projectId: projectId,
      rootPath: folders.waveforms,
      kind: CacheEntryKind.waveform,
      entriesByPath: entriesByPath,
    );
    await _scanFolder(
      projectId: projectId,
      rootPath: folders.proxies,
      kind: CacheEntryKind.proxy,
      entriesByPath: entriesByPath,
    );
    await _scanFolder(
      projectId: projectId,
      rootPath: folders.temp,
      kind: CacheEntryKind.temp,
      entriesByPath: entriesByPath,
    );
    await _scanFolder(
      projectId: projectId,
      rootPath: folders.autosaves,
      kind: CacheEntryKind.autosave,
      entriesByPath: entriesByPath,
    );
    await _scanFolder(
      projectId: projectId,
      rootPath: folders.exports,
      kind: CacheEntryKind.export,
      entriesByPath: entriesByPath,
    );

    final snapshot = CacheIndexSnapshot(
      projectId: projectId,
      generatedAt: DateTime.now(),
      entries: entriesByPath.values.toList()
        ..sort((a, b) => a.path.compareTo(b.path)),
    );
    await _writeIndex(snapshot);
    return snapshot;
  }

  Future<void> registerAssetCacheEntry({
    required String projectId,
    required String assetId,
    required String path,
    required String kind,
    Map<String, dynamic> metadata = const {},
  }) async {
    final normalized = _normalizePath(path);
    if (normalized == null) return;
    final current = await loadIndex(projectId);
    final entries = current.entries.where((entry) => entry.path != normalized).toList();
    entries.add(await _entryForFile(
      projectId: projectId,
      assetId: assetId,
      kind: kind,
      path: normalized,
      referencedByDatabase: true,
      metadata: {'source': 'native_event', ...metadata},
    ));
    await _writeIndex(CacheIndexSnapshot(
      projectId: projectId,
      generatedAt: DateTime.now(),
      entries: entries..sort((a, b) => a.path.compareTo(b.path)),
    ));
  }

  Future<void> touchCacheEntry({
    required String projectId,
    required String path,
  }) async {
    final normalized = _normalizePath(path);
    if (normalized == null) return;
    final current = await loadIndex(projectId);
    final now = DateTime.now();
    final entries = current.entries.map((entry) {
      if (entry.path != normalized) return entry;
      return entry.copyWith(lastAccessedAt: now);
    }).toList();
    await _writeIndex(CacheIndexSnapshot(
      projectId: projectId,
      generatedAt: now,
      entries: entries,
    ));
  }

  Future<CacheCleanupReport> cleanupProjectCache(
    String projectId, {
    CacheCleanupPolicy policy = CacheCleanupPolicy.conservative,
  }) async {
    final startedAt = DateTime.now();
    final folders = await projectStorageService.getProjectFolders(projectId);
    final before = await rebuildIndex(projectId);
    final deleteQueue = _selectCleanupCandidates(before, policy, folders);
    var deletedBytes = 0;
    var deletedFiles = 0;
    final deletedPaths = <String>[];
    final failedPaths = <String>[];
    final retainedPaths = before.entries.map((entry) => entry.path).toSet();

    for (final entry in deleteQueue) {
      if (!_isDisposablePath(entry.path, folders, includeExports: policy.includeExports)) {
        failedPaths.add(entry.path);
        continue;
      }
      if (policy.dryRun) {
        deletedBytes += entry.bytes;
        deletedFiles += entry.exists ? 1 : 0;
        deletedPaths.add(entry.path);
        retainedPaths.remove(entry.path);
        continue;
      }
      try {
        final file = File(entry.path);
        if (await file.exists()) {
          final bytes = await file.length();
          await file.delete();
          deletedBytes += bytes;
          deletedFiles++;
        }
        deletedPaths.add(entry.path);
        retainedPaths.remove(entry.path);
        await _clearAssetReference(projectId, entry);
      } catch (_) {
        failedPaths.add(entry.path);
      }
    }

    final after = policy.dryRun ? before : await rebuildIndex(projectId);
    final completedAt = DateTime.now();
    return CacheCleanupReport(
      projectId: projectId,
      startedAt: startedAt,
      completedAt: completedAt,
      dryRun: policy.dryRun,
      beforeBytes: before.totalBytes,
      afterBytes: policy.dryRun ? before.totalBytes - deletedBytes : after.totalBytes,
      deletedBytes: deletedBytes,
      deletedFiles: deletedFiles,
      deletedPaths: deletedPaths,
      failedPaths: failedPaths,
      retainedPaths: retainedPaths.toList()..sort(),
    );
  }

  List<CacheIndexEntry> _selectCleanupCandidates(
    CacheIndexSnapshot index,
    CacheCleanupPolicy policy,
    ProjectStoragePaths folders,
  ) {
    final now = DateTime.now();
    final staleTempCutoff = now.subtract(Duration(days: policy.staleTempAgeDays));
    final queue = <CacheIndexEntry>[];
    final queuedPaths = <String>{};

    bool allowed(CacheIndexEntry entry) {
      if (entry.pinned) return false;
      if (!entry.exists) return false;
      if (entry.kind == CacheEntryKind.export && !policy.includeExports) return false;
      if (policy.allowedKinds != null && !policy.allowedKinds!.contains(entry.kind)) return false;
      return _isDisposablePath(entry.path, folders, includeExports: policy.includeExports);
    }

    void enqueue(CacheIndexEntry entry) {
      if (!allowed(entry)) return;
      if (queuedPaths.add(entry.path)) queue.add(entry);
    }

    for (final entry in index.entries) {
      if (entry.kind == CacheEntryKind.temp && entry.modifiedAt.isBefore(staleTempCutoff)) {
        enqueue(entry);
      }
      if (policy.purgeOrphans && !entry.referencedByDatabase && _isGeneratedCacheKind(entry.kind)) {
        enqueue(entry);
      }
    }

    final autosaves = index.entries
        .where((entry) => entry.kind == CacheEntryKind.autosave && allowed(entry))
        .toList()
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    for (var i = policy.keepNewestAutosaves; i < autosaves.length; i++) {
      enqueue(autosaves[i]);
    }

    if (policy.maxCacheBytes != null) {
      var projectedBytes = index.totalBytes - queue.fold<int>(0, (sum, entry) => sum + entry.bytes);
      if (projectedBytes > policy.maxCacheBytes!) {
        final remaining = index.entries
            .where((entry) => allowed(entry) && !queuedPaths.contains(entry.path))
            .toList()
          ..sort(_cleanupPriorityCompare);
        for (final entry in remaining) {
          if (projectedBytes <= policy.maxCacheBytes!) break;
          enqueue(entry);
          projectedBytes -= entry.bytes;
        }
      }
    }

    queue.sort(_cleanupPriorityCompare);
    return queue;
  }

  int _cleanupPriorityCompare(CacheIndexEntry a, CacheIndexEntry b) {
    final priority = <String, int>{
      CacheEntryKind.temp: 0,
      CacheEntryKind.thumbnail: 1,
      CacheEntryKind.timelineThumbnail: 1,
      CacheEntryKind.waveform: 2,
      CacheEntryKind.proxy: 3,
      CacheEntryKind.autosave: 4,
      CacheEntryKind.export: 5,
      CacheEntryKind.other: 6,
    };
    final p = (priority[a.kind] ?? 99).compareTo(priority[b.kind] ?? 99);
    if (p != 0) return p;
    return a.lastAccessedAt.compareTo(b.lastAccessedAt);
  }

  bool _isGeneratedCacheKind(String kind) {
    return kind == CacheEntryKind.proxy ||
        kind == CacheEntryKind.thumbnail ||
        kind == CacheEntryKind.timelineThumbnail ||
        kind == CacheEntryKind.waveform ||
        kind == CacheEntryKind.temp;
  }

  Future<void> _scanFolder({
    required String projectId,
    required String rootPath,
    required String kind,
    required Map<String, CacheIndexEntry> entriesByPath,
  }) async {
    final directory = Directory(rootPath);
    if (!await directory.exists()) return;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = p.normalize(entity.path);
      if (p.basename(path) == 'cache_index.json') continue;
      entriesByPath.putIfAbsent(path, () {
        final stat = entity.statSync();
        return CacheIndexEntry(
          id: _entryId(projectId, path),
          projectId: projectId,
          assetId: null,
          kind: kind,
          path: path,
          bytes: stat.size,
          createdAt: stat.changed,
          modifiedAt: stat.modified,
          lastAccessedAt: stat.accessed,
          exists: true,
          pinned: false,
          referencedByDatabase: false,
          metadata: const {'source': 'disk_scan'},
        );
      });
    }
  }

  Future<CacheIndexEntry> _entryForFile({
    required String projectId,
    required String? assetId,
    required String kind,
    required String path,
    required bool referencedByDatabase,
    required Map<String, dynamic> metadata,
  }) async {
    final file = File(path);
    if (await file.exists()) {
      final stat = await file.stat();
      return CacheIndexEntry(
        id: _entryId(projectId, path),
        projectId: projectId,
        assetId: assetId,
        kind: kind,
        path: path,
        bytes: stat.size,
        createdAt: stat.changed,
        modifiedAt: stat.modified,
        lastAccessedAt: stat.accessed,
        exists: true,
        pinned: false,
        referencedByDatabase: referencedByDatabase,
        metadata: metadata,
      );
    }
    final now = DateTime.now();
    return CacheIndexEntry(
      id: _entryId(projectId, path),
      projectId: projectId,
      assetId: assetId,
      kind: kind,
      path: path,
      bytes: 0,
      createdAt: now,
      modifiedAt: now,
      lastAccessedAt: now,
      exists: false,
      pinned: false,
      referencedByDatabase: referencedByDatabase,
      metadata: metadata,
    );
  }

  Future<void> _writeIndex(CacheIndexSnapshot snapshot) async {
    final indexPath = await indexPathForProject(snapshot.projectId);
    final file = File(indexPath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(snapshot.toJson()), flush: true);
  }

  Future<void> _clearAssetReference(String projectId, CacheIndexEntry entry) async {
    if (!entry.referencedByDatabase) return;
    final assets = await assetRepository.getProjectAssets(projectId);
    for (final asset in assets) {
      if (entry.kind == CacheEntryKind.proxy && asset.proxyPath == entry.path) {
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
      } else if (entry.kind == CacheEntryKind.thumbnail && asset.thumbnailPath == entry.path) {
        await assetRepository.updateAssetFields(
          asset.id,
          const AssetsCompanion(
            thumbnailPath: Value<String?>(null),
            thumbnailStatus: Value('pending'),
          ),
        );
      } else if (entry.kind == CacheEntryKind.waveform && asset.waveformPath == entry.path) {
        await assetRepository.updateAssetFields(
          asset.id,
          const AssetsCompanion(
            waveformPath: Value<String?>(null),
            waveformStatus: Value('pending'),
          ),
        );
      }
    }
  }

  bool _isDisposablePath(
    String path,
    ProjectStoragePaths folders, {
    required bool includeExports,
  }) {
    final normalized = p.normalize(path);
    final roots = <String>[
      folders.thumbnails,
      folders.timelineThumbnails,
      folders.waveforms,
      folders.proxies,
      folders.temp,
      folders.autosaves,
      if (includeExports) folders.exports,
    ].map(p.normalize).toList();
    return roots.any((root) => p.equals(normalized, root) || p.isWithin(root, normalized));
  }

  String? _normalizePath(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    return p.normalize(path.trim());
  }

  String _entryId(String projectId, String path) {
    return base64Url.encode(utf8.encode('$projectId|$path')).replaceAll('=', '');
  }

  String _proxyStatusAfterDelete(Asset asset) {
    final width = asset.width ?? 0;
    final height = asset.height ?? 0;
    final isLargeResolution = width >= 1920 || height >= 1080;
    final isLargeFile = asset.fileSize > 300 * 1024 * 1024;
    return isLargeResolution || isLargeFile ? 'needed' : 'not_needed';
  }
}
