import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/media_library/media_bin_models.dart';

/// Repository for the canonical project media model.
///
/// Production media code writes to `MediaAssets`. Timeline/render/export code must
/// treat this repository as the authoritative asset lifecycle source.
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
        projectPath: Value(asset.projectPath),
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

  NleMediaAsset _assetFromRow(db.MediaAsset row) {
    final fileInfo = _decodeMap(row.fileInfoJson);
    final videoInfo = _decodeMap(row.videoInfoJson);
    final audioInfo = _decodeMap(row.audioInfoJson);
    final timecodeInfo = _decodeMap(row.timecodeInfoJson);
    final tags = _decodeStringList(row.tagsJson);

    return NleMediaAsset(
      id: row.id,
      projectId: row.projectId,
      displayName: row.displayName,
      type: _enumByName(NleMediaAssetType.values, row.type, NleMediaAssetType.unknown),
      importSource: _enumByName(NleMediaImportSource.values, row.importSource, NleMediaImportSource.filePicker),
      storageMode: _enumByName(NleMediaStorageMode.values, row.storageMode, NleMediaStorageMode.copiedIntoProject),
      availability: _enumByName(NleMediaAvailability.values, row.availability, NleMediaAvailability.available),
      originalPath: row.originalPath,
      projectPath: row.projectPath,
      thumbnailPath: row.thumbnailPath,
      waveformCacheId: row.waveformCacheId,
      proxyPath: row.proxyPath,
      proxyStatus: _enumByName(NleProxyStatus.values, row.proxyStatus, NleProxyStatus.none),
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
