import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/media_library/media_bin_models.dart';

class NleResolvedMediaAsset {
  final NleMediaAsset asset;
  final String selectedMediaPath;
  final String? resolvedPath;
  final bool usingProxy;

  const NleResolvedMediaAsset({
    required this.asset,
    required this.selectedMediaPath,
    required this.resolvedPath,
    required this.usingProxy,
  });

  Map<String, dynamic> toRenderJson() {
    return {
      'id': asset.id,
      'type': asset.type.name,
      'originalPath': asset.originalPath,
      'resolvedPath': resolvedPath,
      'selectedMediaPath': selectedMediaPath,
      'usingProxy': usingProxy,
      'width': asset.videoInfo.width,
      'height': asset.videoInfo.height,
      'durationMicros': asset.timecodeInfo.durationMicros,
      'hasVideo': asset.isVideo || asset.videoInfo.hasResolution,
      'hasAudio': asset.isAudio || asset.audioInfo.channelCount > 0,
    };
  }
}

/// Repository for the canonical project media model.
///
/// `MediaAssets` is the only authoritative model for import/proxy/cache/render
/// and export. The old `Assets` table is read only as a migration source through
/// [migrateLegacyAssetsForProject]; new pipeline code must not resolve file paths
/// directly from legacy rows.
class MediaAssetRepository {
  final db.AppDatabase database;

  const MediaAssetRepository({required this.database});

  Future<List<NleMediaAsset>> getAssets(String projectId) async {
    final rows = await database.getMediaAssetsForProject(projectId);
    return rows.map(_assetFromRow).toList();
  }

  Future<NleMediaAsset?> getAsset(String assetId) async {
    final row = await database.getMediaAssetById(assetId);
    if (row == null) return null;
    return _assetFromRow(row);
  }

  Future<NleMediaAsset> requireAsset(String assetId) async {
    final asset = await getAsset(assetId);
    if (asset == null) {
      throw StateError('Media asset not found: $assetId');
    }
    return asset;
  }

  Future<List<NleMediaAsset>> getAssetsByIds(List<String> assetIds) async {
    final rows = await database.getMediaAssetsByIds(assetIds);
    return rows.map(_assetFromRow).toList();
  }

  Future<void> saveAsset(NleMediaAsset asset) async {
    await database.upsertMediaAsset(
      db.MediaAssetsCompanion(
        id: Value(asset.id),
        projectId: Value(asset.projectId),
        displayName: Value(asset.displayName),
        type: Value(asset.type.name),
        importSource: Value(asset.importSource.name),
        storageMode: Value(asset.storageMode.name),
        availability: Value(asset.availability.name),
        originalPath: Value(asset.originalPath),
        projectPath: Value(asset.projectPath ?? asset.resolvedPath),
        thumbnailPath: Value(asset.thumbnailPath),
        waveformCacheId: Value(asset.waveformCacheId),
        proxyPath: Value(asset.proxyPath),
        proxyStatus: Value(asset.proxyStatus.name),
        usageState: Value(asset.usageState.name),
        fileInfoJson: Value(jsonEncode(asset.fileInfo.toJson())),
        videoInfoJson: Value(jsonEncode(asset.videoInfo.toJson())),
        audioInfoJson: Value(jsonEncode(asset.audioInfo.toJson())),
        timecodeInfoJson: Value(jsonEncode(asset.timecodeInfo.toJson())),
        notes: Value(asset.notes),
        tagsJson: Value(jsonEncode(asset.tags)),
        importedAt: Value(asset.importedAt),
        updatedAt: Value(DateTime.now()),
        version: Value(asset.version),
      ),
    );
  }

  Future<NleMediaAsset> importAsset({
    required String projectId,
    required String sourcePath,
    String? displayName,
    NleMediaAssetType type = NleMediaAssetType.unknown,
    NleMediaImportSource importSource = NleMediaImportSource.filePicker,
    NleMediaStorageMode storageMode = NleMediaStorageMode.referencedExternal,
    String? projectPath,
    int fileSizeBytes = 0,
    DateTime? fileModifiedAt,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final fileName = _fileNameFromPath(sourcePath);
    final resolvedPath = _firstNonBlank(projectPath, sourcePath);
    final asset = NleMediaAsset(
      id: const Uuid().v4(),
      projectId: projectId,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : fileName,
      type: type,
      importSource: importSource,
      storageMode: storageMode,
      availability: NleMediaAvailability.available,
      lifecycleState: NleMediaLifecycleState.imported,
      originalPath: sourcePath,
      projectPath: projectPath,
      resolvedPath: resolvedPath,
      selectedMediaPath: resolvedPath,
      proxyStatus: NleProxyStatus.none,
      usageState: NleMediaUsageState.unused,
      fileInfo: NleMediaFileInfo(
        fileName: fileName,
        extension: _extensionFromPath(fileName),
        fileSizeBytes: fileSizeBytes,
        fileModifiedAt: fileModifiedAt,
      ),
      videoInfo: const NleMediaVideoInfo.empty(),
      audioInfo: const NleMediaAudioInfo.empty(),
      timecodeInfo: const NleMediaTimecodeInfo.empty(),
      notes: null,
      tags: tags,
      importedAt: now,
      updatedAt: now,
      version: 1,
    );

    await saveAsset(asset);
    return asset;
  }

  Future<NleMediaAsset> markAnalyzed({
    required String assetId,
    NleMediaFileInfo? fileInfo,
    NleMediaVideoInfo? videoInfo,
    NleMediaAudioInfo? audioInfo,
    NleMediaTimecodeInfo? timecodeInfo,
  }) async {
    final asset = await requireAsset(assetId);
    final analyzed = asset.copyWith(
      lifecycleState: NleMediaLifecycleState.analyzed,
      fileInfo: fileInfo,
      videoInfo: videoInfo,
      audioInfo: audioInfo,
      timecodeInfo: timecodeInfo,
      updatedAt: DateTime.now(),
    );
    await saveAsset(analyzed);
    return analyzed;
  }

  Future<void> removeAsset(String assetId) async {
    await database.deleteMediaAssetById(assetId);
  }

  Future<void> setAvailability({
    required String assetId,
    required NleMediaAvailability availability,
  }) {
    return database.updateMediaAssetAvailability(
      assetId: assetId,
      availability: availability.name,
    );
  }

  Future<void> setUsageState({
    required String assetId,
    required NleMediaUsageState usageState,
  }) {
    return database.updateMediaAssetUsageState(
      assetId: assetId,
      usageState: usageState.name,
    );
  }

  Future<void> markProxyNeeded({
    required String assetId,
    String? reason,
  }) {
    return database.updateMediaAssetProxyStatus(
      assetId: assetId,
      proxyStatus: NleProxyStatus.queued.name,
      proxyError: reason,
    );
  }

  Future<void> enqueueProxyJob({
    required String projectId,
    required String assetId,
    required String outputPath,
    required Map<String, dynamic> spec,
    String reason = 'auto',
    String priority = 'normal',
  }) async {
    final asset = await requireAsset(assetId);
    final sourcePath = resolvePath(asset);
    if (sourcePath == null) {
      throw StateError('Cannot enqueue proxy for unresolved asset: $assetId');
    }

    await markProxyNeeded(assetId: assetId, reason: reason);
    await database.upsertProxyJob(
      db.ProxyJobsCompanion(
        id: Value(const Uuid().v4()),
        projectId: Value(projectId),
        assetId: Value(assetId),
        sourcePath: Value(sourcePath),
        outputPath: Value(outputPath),
        status: Value(NleProxyStatus.queued.name),
        reason: Value(reason),
        priority: Value(priority),
        specJson: Value(jsonEncode(spec)),
        progress: const Value(0.0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setProxyReady({
    required String assetId,
    required String proxyPath,
    Map<String, dynamic> metadata = const {},
  }) {
    return database.updateMediaAssetProxyReady(
      assetId: assetId,
      proxyPath: proxyPath,
      proxyMetadataJson: jsonEncode(metadata),
    );
  }

  Future<void> setProxyFailed({
    required String assetId,
    required String error,
  }) {
    return database.updateMediaAssetProxyStatus(
      assetId: assetId,
      proxyStatus: NleProxyStatus.failed.name,
      proxyError: error,
    );
  }

  Future<void> clearProxy({required String assetId}) {
    return database.clearMediaAssetProxy(assetId: assetId);
  }

  Future<NleMediaAsset> markMissing({
    required String assetId,
    String? message,
  }) async {
    final asset = await requireAsset(assetId);
    final missing = asset.copyWith(
      availability: NleMediaAvailability.missing,
      lifecycleState: NleMediaLifecycleState.missing,
      selectedMediaPath: '',
      updatedAt: DateTime.now(),
    );
    await saveAsset(missing.copyWith(notes: message ?? asset.notes));
    return missing;
  }

  Future<NleMediaAsset> relinkAsset({
    required String assetId,
    required String resolvedPath,
  }) async {
    final asset = await requireAsset(assetId);

    // Important: relink writes the new usable path into the canonical resolved
    // slot while preserving originalPath as the import-time source reference.
    final relinked = asset.copyWith(
      availability: NleMediaAvailability.available,
      lifecycleState: NleMediaLifecycleState.relinked,
      projectPath: resolvedPath,
      resolvedPath: resolvedPath,
      selectedMediaPath: resolvedPath,
      updatedAt: DateTime.now(),
    );
    await saveAsset(relinked);
    return relinked;
  }

  String? resolvePath(NleMediaAsset asset) {
    if (asset.availability != NleMediaAvailability.available) return null;
    return _firstNonBlank(
      asset.resolvedPath,
      asset.projectPath,
      asset.originalPath,
    );
  }

  String? selectMediaPath(
    NleMediaAsset asset, {
    bool preferProxy = true,
  }) {
    if (asset.availability != NleMediaAvailability.available) return null;

    final proxyPath = _cleanPath(asset.proxyPath);
    if (preferProxy &&
        asset.proxyStatus == NleProxyStatus.ready &&
        proxyPath != null) {
      return proxyPath;
    }

    return resolvePath(asset);
  }

  Future<NleResolvedMediaAsset?> resolveAssetForRender({
    required String assetId,
    bool preferProxy = true,
  }) async {
    final asset = await getAsset(assetId);
    if (asset == null) return null;
    return _resolveForRender(asset, preferProxy: preferProxy);
  }

  Future<Map<String, NleResolvedMediaAsset>> resolveAssetsForRender({
    required Iterable<String> assetIds,
    bool preferProxy = true,
  }) async {
    final uniqueIds = assetIds.where((id) => id.trim().isNotEmpty).toSet();
    if (uniqueIds.isEmpty) return const <String, NleResolvedMediaAsset>{};

    final assets = await getAssetsByIds(uniqueIds.toList());
    final resolved = <String, NleResolvedMediaAsset>{};
    for (final asset in assets) {
      final item = _resolveForRender(asset, preferProxy: preferProxy);
      if (item != null) {
        resolved[asset.id] = item;
      }
    }
    return resolved;
  }

  Future<int> migrateLegacyAssetsForProject(String projectId) async {
    final legacyRows = await database.getProjectAssetsOnce(projectId);
    var migrated = 0;

    for (final legacy in legacyRows) {
      final existing = await database.getMediaAssetById(legacy.id);
      if (existing != null) continue;

      await saveAsset(_assetFromLegacyRow(legacy));
      migrated += 1;
    }

    return migrated;
  }

  Future<List<NleMediaBin>> getBins(String projectId) async {
    final rows = await database.getMediaBinsForProject(projectId);
    return rows.map(_binFromRow).toList();
  }

  Future<void> saveBin(NleMediaBin bin) {
    return database.upsertMediaBin(
      db.MediaBinsCompanion(
        id: Value(bin.id),
        projectId: Value(bin.projectId),
        name: Value(bin.name),
        parentBinId: Value(bin.parentBinId),
        sortIndex: Value(bin.sortIndex),
        smartBin: Value(bin.smartBin),
        smartQuery: Value(bin.smartQuery),
        createdAt: Value(bin.createdAt),
        updatedAt: Value(DateTime.now()),
        version: Value(bin.version),
      ),
    );
  }

  Future<void> linkAssetToBin({
    required String assetId,
    required String binId,
  }) {
    return database.linkAssetToBin(assetId: assetId, binId: binId);
  }

  NleResolvedMediaAsset? _resolveForRender(
    NleMediaAsset asset, {
    required bool preferProxy,
  }) {
    final resolvedPath = resolvePath(asset);
    final selectedPath = selectMediaPath(asset, preferProxy: preferProxy);
    if (selectedPath == null) return null;

    return NleResolvedMediaAsset(
      asset: asset.copyWith(
        resolvedPath: resolvedPath,
        selectedMediaPath: selectedPath,
      ),
      selectedMediaPath: selectedPath,
      resolvedPath: resolvedPath,
      usingProxy: _cleanPath(asset.proxyPath) == selectedPath &&
          asset.proxyStatus == NleProxyStatus.ready,
    );
  }

  NleMediaAsset _assetFromRow(db.MediaAsset row) {
    final fileInfo = _decodeMap(row.fileInfoJson);
    final videoInfo = _decodeMap(row.videoInfoJson);
    final audioInfo = _decodeMap(row.audioInfoJson);
    final timecodeInfo = _decodeMap(row.timecodeInfoJson);
    final tags = _decodeStringList(row.tagsJson);
    final availability = _enumByName(
      NleMediaAvailability.values,
      row.availability,
      NleMediaAvailability.available,
    );
    final proxyStatus = _enumByName(
      NleProxyStatus.values,
      row.proxyStatus,
      NleProxyStatus.none,
    );
    final resolvedPath = availability == NleMediaAvailability.available
        ? _firstNonBlank(row.projectPath, row.originalPath)
        : null;
    final selectedPath = _selectPathFromParts(
      availability: availability,
      proxyStatus: proxyStatus,
      proxyPath: row.proxyPath,
      resolvedPath: resolvedPath,
    );

    return NleMediaAsset(
      id: row.id,
      projectId: row.projectId,
      displayName: row.displayName,
      type: _enumByName(NleMediaAssetType.values, row.type, NleMediaAssetType.unknown),
      importSource: _enumByName(NleMediaImportSource.values, row.importSource, NleMediaImportSource.filePicker),
      storageMode: _enumByName(NleMediaStorageMode.values, row.storageMode, NleMediaStorageMode.copiedIntoProject),
      availability: availability,
      lifecycleState: _deriveLifecycle(
        availability: availability,
        proxyStatus: proxyStatus,
        fileInfo: fileInfo,
        videoInfo: videoInfo,
        audioInfo: audioInfo,
        timecodeInfo: timecodeInfo,
      ),
      originalPath: row.originalPath,
      projectPath: row.projectPath,
      resolvedPath: resolvedPath,
      selectedMediaPath: selectedPath,
      thumbnailPath: row.thumbnailPath,
      waveformCacheId: row.waveformCacheId,
      proxyPath: row.proxyPath,
      proxyStatus: proxyStatus,
      usageState: _enumByName(NleMediaUsageState.values, row.usageState, NleMediaUsageState.unused),
      fileInfo: NleMediaFileInfo.fromJson(fileInfo),
      videoInfo: NleMediaVideoInfo.fromJson(videoInfo),
      audioInfo: NleMediaAudioInfo.fromJson(audioInfo),
      timecodeInfo: NleMediaTimecodeInfo.fromJson(timecodeInfo),
      notes: row.notes,
      tags: tags,
      importedAt: row.importedAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }

  NleMediaAsset _assetFromLegacyRow(db.Asset row) {
    final type = _assetTypeFromLegacyType(row.fileType);
    final proxyStatus = _proxyStatusFromLegacy(row.proxyStatus, row.proxyPath);
    final resolvedPath = _firstNonBlank(row.originalPath);
    final selectedPath = _selectPathFromParts(
      availability: row.isMissing
          ? NleMediaAvailability.missing
          : NleMediaAvailability.available,
      proxyStatus: proxyStatus,
      proxyPath: row.proxyPath,
      resolvedPath: resolvedPath,
    );

    return NleMediaAsset(
      id: row.id,
      projectId: row.projectId,
      displayName: row.fileName,
      type: type,
      importSource: NleMediaImportSource.externalReference,
      storageMode: row.importMode == 'copy'
          ? NleMediaStorageMode.copiedIntoProject
          : NleMediaStorageMode.referencedExternal,
      availability: row.isMissing
          ? NleMediaAvailability.missing
          : NleMediaAvailability.available,
      lifecycleState: row.isMissing
          ? NleMediaLifecycleState.missing
          : _legacyLifecycle(row, proxyStatus),
      originalPath: row.originalPath,
      projectPath: null,
      resolvedPath: resolvedPath,
      selectedMediaPath: selectedPath,
      thumbnailPath: row.thumbnailPath,
      waveformCacheId: row.waveformPath,
      proxyPath: row.proxyPath,
      proxyStatus: proxyStatus,
      usageState: NleMediaUsageState.unused,
      fileInfo: NleMediaFileInfo(
        fileName: row.fileName,
        extension: _extensionFromPath(row.fileName),
        fileSizeBytes: row.fileSize,
        fileModifiedAt: row.lastKnownModifiedAt,
      ),
      videoInfo: NleMediaVideoInfo(
        width: row.width ?? 0,
        height: row.height ?? 0,
        fps: row.frameRate ?? 0.0,
        codec: row.codec ?? '',
        colorSpace: row.colorSpace ?? '',
        hasHdr: row.isHdr,
      ),
      audioInfo: NleMediaAudioInfo(
        sampleRate: row.audioSampleRate ?? 0,
        channelCount: row.audioChannels ?? 0,
        codec: row.audioCodec ?? '',
        bitrate: row.bitrate ?? 0,
      ),
      timecodeInfo: NleMediaTimecodeInfo(
        fps: row.frameRate ?? 30.0,
        durationMicros: row.durationMicros ?? 0,
        startTimecodeMicros: 0,
      ),
      notes: row.errorMessage,
      tags: const <String>[],
      importedAt: row.createdAt,
      updatedAt: DateTime.now(),
      version: 1,
    );
  }

  NleMediaBin _binFromRow(db.MediaBin row) {
    return NleMediaBin(
      id: row.id,
      projectId: row.projectId,
      name: row.name,
      parentBinId: row.parentBinId,
      sortIndex: row.sortIndex,
      smartBin: row.smartBin,
      smartQuery: row.smartQuery,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }

  NleMediaLifecycleState _deriveLifecycle({
    required NleMediaAvailability availability,
    required NleProxyStatus proxyStatus,
    required Map<String, dynamic> fileInfo,
    required Map<String, dynamic> videoInfo,
    required Map<String, dynamic> audioInfo,
    required Map<String, dynamic> timecodeInfo,
  }) {
    if (availability == NleMediaAvailability.missing) {
      return NleMediaLifecycleState.missing;
    }
    if (proxyStatus == NleProxyStatus.ready) {
      return NleMediaLifecycleState.proxyReady;
    }
    if (proxyStatus == NleProxyStatus.queued ||
        proxyStatus == NleProxyStatus.generating) {
      return NleMediaLifecycleState.proxyNeeded;
    }
    if (_hasAnalysisData(fileInfo, videoInfo, audioInfo, timecodeInfo)) {
      return NleMediaLifecycleState.analyzed;
    }
    return NleMediaLifecycleState.imported;
  }

  NleMediaLifecycleState _legacyLifecycle(
    db.Asset row,
    NleProxyStatus proxyStatus,
  ) {
    if (proxyStatus == NleProxyStatus.ready) {
      return NleMediaLifecycleState.proxyReady;
    }
    if (proxyStatus == NleProxyStatus.queued ||
        proxyStatus == NleProxyStatus.generating) {
      return NleMediaLifecycleState.proxyNeeded;
    }
    if (row.durationMicros != null || row.width != null || row.height != null) {
      return NleMediaLifecycleState.analyzed;
    }
    return NleMediaLifecycleState.imported;
  }

  bool _hasAnalysisData(
    Map<String, dynamic> fileInfo,
    Map<String, dynamic> videoInfo,
    Map<String, dynamic> audioInfo,
    Map<String, dynamic> timecodeInfo,
  ) {
    return fileInfo.isNotEmpty ||
        videoInfo.isNotEmpty ||
        audioInfo.isNotEmpty ||
        timecodeInfo.isNotEmpty;
  }

  NleMediaAssetType _assetTypeFromLegacyType(String raw) {
    switch (raw.toLowerCase()) {
      case 'video':
      case 'movie':
        return NleMediaAssetType.video;
      case 'audio':
      case 'music':
      case 'voice':
      case 'sfx':
        return NleMediaAssetType.audio;
      case 'image':
      case 'photo':
      case 'picture':
        return NleMediaAssetType.image;
    }
    return NleMediaAssetType.unknown;
  }

  NleProxyStatus _proxyStatusFromLegacy(String raw, String? proxyPath) {
    final normalized = raw.toLowerCase().trim();
    if (_cleanPath(proxyPath) != null &&
        (normalized == 'ready' || normalized == 'proxy_ready')) {
      return NleProxyStatus.ready;
    }
    switch (normalized) {
      case 'ready':
      case 'proxy_ready':
      case 'done':
        return _cleanPath(proxyPath) == null
            ? NleProxyStatus.none
            : NleProxyStatus.ready;
      case 'queued':
      case 'pending':
      case 'needed':
      case 'proxy_needed':
        return NleProxyStatus.queued;
      case 'generating':
      case 'processing':
      case 'running':
        return NleProxyStatus.generating;
      case 'failed':
      case 'error':
        return NleProxyStatus.failed;
    }
    return NleProxyStatus.none;
  }

  String? _selectPathFromParts({
    required NleMediaAvailability availability,
    required NleProxyStatus proxyStatus,
    required String? proxyPath,
    required String? resolvedPath,
  }) {
    if (availability != NleMediaAvailability.available) return null;
    final cleanProxy = _cleanPath(proxyPath);
    if (proxyStatus == NleProxyStatus.ready && cleanProxy != null) {
      return cleanProxy;
    }
    return _cleanPath(resolvedPath);
  }

  Map<String, dynamic> _decodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  List<String> _decodeStringList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((item) => item.toString()).toList();
    } catch (_) {}
    return const <String>[];
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/').where((part) => part.isNotEmpty);
    return segments.isEmpty ? 'Media' : segments.last;
  }

  String _extensionFromPath(String path) {
    final name = _fileNameFromPath(path);
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  String? _firstNonBlank(String? first, [String? second, String? third]) {
    for (final value in [first, second, third]) {
      final clean = _cleanPath(value);
      if (clean != null) return clean;
    }
    return null;
  }

  String? _cleanPath(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
    final string = name?.toString();
    if (string == null) return fallback;
    for (final value in values) {
      if (value.name == string) return value;
    }
    return fallback;
  }
}
