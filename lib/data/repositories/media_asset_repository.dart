import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/media_library/media_asset_lifecycle.dart';
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
      'projectPath': asset.projectPath,
      'proxyPath': asset.proxyPath,
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
/// All production import, proxy, cache, render, and export code should read and
/// write media through `MediaAssets`. The older clip-facing asset rows are only
/// accepted as source records for project import into this canonical model.
class MediaAssetRepository {
  final db.AppDatabase database;

  const MediaAssetRepository({required this.database});

  Future<List<NleMediaAsset>> getAssets(String projectId) async {
    final rows = await database.getMediaAssetsForProject(projectId);
    return rows.map(_assetFromRow).toList();
  }

  Future<List<NleMediaAsset>> getAssetsByIds(List<String> assetIds) async {
    final rows = await database.getMediaAssetsByIds(assetIds);
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

  Future<void> removeAsset(String assetId) async {
    await database.deleteMediaAssetById(assetId);
  }

  Future<void> importExistingProjectAssetRecords(String projectId) async {
    final existing = await database.getProjectAssetsOnce(projectId);
    for (final asset in existing) {
      final current = await database.getMediaAssetById(asset.id);
      if (current != null) continue;
      final now = DateTime.now();
      await database.upsertMediaAsset(
        db.MediaAssetsCompanion(
          id: Value(asset.id),
          projectId: Value(asset.projectId),
          displayName: Value(asset.fileName),
          type: Value(_mediaTypeFromAsset(asset.fileType)),
          importSource: const Value('filePicker'),
          storageMode: Value(asset.importMode == 'copy' ? 'copiedIntoProject' : 'referencedExternal'),
          availability: Value(asset.isMissing ? 'missing' : 'available'),
          originalPath: Value(asset.originalPath),
          projectPath: const Value(null),
          thumbnailPath: Value(asset.thumbnailPath),
          waveformCacheId: Value(asset.waveformPath),
          proxyPath: Value(asset.proxyPath),
          proxyStatus: Value(_proxyStatusFromAsset(asset.proxyStatus)),
          usageState: const Value('used'),
          fileInfoJson: Value(jsonEncode({
            'fileName': asset.fileName,
            'extension': _extension(asset.fileName),
            'fileSizeBytes': asset.fileSize,
            'fileModifiedAt': asset.lastKnownModifiedAt?.toIso8601String(),
          })),
          videoInfoJson: Value(jsonEncode({
            'width': asset.width ?? 0,
            'height': asset.height ?? 0,
            'fps': asset.frameRate ?? 0.0,
            'codec': asset.codec ?? '',
            'colorSpace': asset.colorSpace ?? '',
            'hasHdr': asset.isHdr,
          })),
          audioInfoJson: Value(jsonEncode({
            'sampleRate': asset.audioSampleRate ?? 0,
            'channelCount': asset.audioChannels ?? 0,
            'codec': asset.audioCodec ?? '',
            'bitrate': asset.bitrate ?? 0,
          })),
          timecodeInfoJson: Value(jsonEncode({
            'fps': asset.frameRate ?? 30.0,
            'durationMicros': asset.durationMicros ?? 0,
            'startTimecodeMicros': 0,
          })),
          notes: Value(asset.errorMessage),
          tagsJson: const Value('[]'),
          importedAt: Value(asset.createdAt),
          updatedAt: Value(now),
          version: const Value(1),
        ),
      );
    }
  }

  Future<int> migrateLegacyAssetsForProject(String projectId) async {
    final before = await database.getMediaAssetsForProject(projectId);
    await importExistingProjectAssetRecords(projectId);
    final after = await database.getMediaAssetsForProject(projectId);
    return after.length - before.length;
  }

  Future<void> markAnalyzed({
    required String assetId,
    required NleMediaFileInfo fileInfo,
    required NleMediaVideoInfo videoInfo,
    required NleMediaAudioInfo audioInfo,
    required NleMediaTimecodeInfo timecodeInfo,
  }) async {
    await database.upsertMediaAsset(
      db.MediaAssetsCompanion(
        id: Value(assetId),
        fileInfoJson: Value(jsonEncode(fileInfo.toJson())),
        videoInfoJson: Value(jsonEncode(videoInfo.toJson())),
        audioInfoJson: Value(jsonEncode(audioInfo.toJson())),
        timecodeInfoJson: Value(jsonEncode(timecodeInfo.toJson())),
        availability: const Value('available'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markProxyNeeded({required String assetId}) {
    return database.updateMediaAssetProxyStatus(
      assetId: assetId,
      proxyStatus: NleProxyStatus.none.name,
      proxyError: null,
    );
  }

  Future<void> markProxyQueued({required String assetId}) {
    return database.updateMediaAssetProxyStatus(
      assetId: assetId,
      proxyStatus: NleProxyStatus.queued.name,
      proxyError: null,
    );
  }

  Future<void> markProxyGenerating({required String assetId}) {
    return database.updateMediaAssetProxyStatus(
      assetId: assetId,
      proxyStatus: NleProxyStatus.generating.name,
      proxyError: null,
    );
  }

  Future<void> markMissing({
    required String assetId,
    String? lastKnownPath,
  }) async {
    await setAvailability(assetId: assetId, availability: NleMediaAvailability.missing);
    final asset = await getAsset(assetId);
    if (asset == null) return;
    await database.upsertMissingMediaRecord(
      db.MissingMediaRecordsCompanion(
        assetId: Value(assetId),
        projectId: Value(asset.projectId),
        lastKnownPath: Value(lastKnownPath ?? asset.resolvedOriginalPath),
        detectedAt: Value(DateTime.now()),
        resolved: const Value(false),
      ),
    );
  }

  Future<void> markRelinked({
    required String assetId,
    required String originalPath,
  }) async {
    final asset = await requireAsset(assetId);
    await saveAsset(
      asset.copyWith(
        availability: NleMediaAvailability.available,
        projectPath: originalPath,
        resolvedPath: originalPath,
        selectedMediaPath: originalPath,
      ),
    );
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

  String? resolvePath(NleMediaAsset asset) {
    if (asset.availability != NleMediaAvailability.available) return null;
    return _firstNonBlank(asset.resolvedPath, asset.projectPath, asset.originalPath);
  }

  String? selectMediaPath(NleMediaAsset asset, {bool preferProxy = true}) {
    if (asset.availability != NleMediaAvailability.available) return null;
    final proxy = _cleanPath(asset.proxyPath);
    if (preferProxy && asset.proxyStatus == NleProxyStatus.ready && proxy != null) {
      return proxy;
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
    final ids = assetIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <String, NleResolvedMediaAsset>{};
    final assets = await getAssetsByIds(ids);
    final resolved = <String, NleResolvedMediaAsset>{};
    for (final asset in assets) {
      final item = _resolveForRender(asset, preferProxy: preferProxy);
      if (item != null) resolved[asset.id] = item;
    }
    return resolved;
  }

  Future<List<Map<String, dynamic>>> getLifecycleReport(String projectId) async {
    final assets = await getAssets(projectId);
    return assets.map((asset) => asset.lifecycleJson()).toList();
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

  Future<void> linkAssetToBin({required String assetId, required String binId}) {
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
      asset: asset.copyWith(resolvedPath: resolvedPath, selectedMediaPath: selectedPath),
      selectedMediaPath: selectedPath,
      resolvedPath: resolvedPath,
      usingProxy: _cleanPath(asset.proxyPath) == selectedPath && asset.proxyStatus == NleProxyStatus.ready,
    );
  }

  NleMediaAsset _assetFromRow(db.MediaAsset row) {
    final fileInfo = _decodeMap(row.fileInfoJson);
    final videoInfo = _decodeMap(row.videoInfoJson);
    final audioInfo = _decodeMap(row.audioInfoJson);
    final timecodeInfo = _decodeMap(row.timecodeInfoJson);
    final tags = _decodeStringList(row.tagsJson);
    final availability = _enumByName(NleMediaAvailability.values, row.availability, NleMediaAvailability.available);
    final proxyStatus = _enumByName(NleProxyStatus.values, row.proxyStatus, NleProxyStatus.none);
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

  String _mediaTypeFromAsset(String value) {
    final type = value.toLowerCase();
    if (type == 'photo') return 'image';
    if (type == 'music' || type == 'voice' || type == 'sfx') return 'audio';
    if (type == 'video' || type == 'image' || type == 'audio') return type;
    return 'unknown';
  }

  String _proxyStatusFromAsset(String value) {
    switch (value) {
      case 'ready':
        return NleProxyStatus.ready.name;
      case 'generating':
        return NleProxyStatus.generating.name;
      case 'queued':
      case 'pending':
        return NleProxyStatus.queued.name;
      case 'failed':
        return NleProxyStatus.failed.name;
      default:
        return NleProxyStatus.none.name;
    }
  }

  String _extension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index < 0 || index == fileName.length - 1) return '';
    return fileName.substring(index + 1).toLowerCase();
  }

  String? _selectPathFromParts({
    required NleMediaAvailability availability,
    required NleProxyStatus proxyStatus,
    required String? proxyPath,
    required String? resolvedPath,
  }) {
    if (availability != NleMediaAvailability.available) return null;
    final proxy = _cleanPath(proxyPath);
    if (proxyStatus == NleProxyStatus.ready && proxy != null) return proxy;
    return _cleanPath(resolvedPath);
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

  T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
    final string = name?.toString();
    if (string == null) return fallback;
    for (final value in values) {
      if (value.name == string) return value;
    }
    return fallback;
  }
}
