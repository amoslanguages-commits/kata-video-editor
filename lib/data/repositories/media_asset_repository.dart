import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/media_library/media_bin_models.dart';

class MediaAssetRepository {
  final db.AppDatabase database;

  const MediaAssetRepository({
    required this.database,
  });

  Future<List<NleMediaAsset>> getAssets(String projectId) async {
    final rows = await database.getMediaAssetsForProject(projectId);
    return rows.map(_assetFromRow).toList();
  }

  Future<NleMediaAsset?> getAsset(String assetId) async {
    final row = await database.getMediaAssetById(assetId);
    if (row == null) return null;
    return _assetFromRow(row);
  }

  Future<void> saveAsset(NleMediaAsset asset) {
    return database.upsertMediaAsset(
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

  Future<void> deleteAsset(String assetId) {
    return database.deleteMediaAssetById(assetId);
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
    return database.linkAssetToBin(
      assetId: assetId,
      binId: binId,
    );
  }

  NleMediaAsset _assetFromRow(db.MediaAsset row) {
    return NleMediaAsset(
      id: row.id,
      projectId: row.projectId,
      displayName: row.displayName,
      type: _enumByName(
        NleMediaAssetType.values,
        row.type,
        NleMediaAssetType.unknown,
      ),
      importSource: _enumByName(
        NleMediaImportSource.values,
        row.importSource,
        NleMediaImportSource.filePicker,
      ),
      storageMode: _enumByName(
        NleMediaStorageMode.values,
        row.storageMode,
        NleMediaStorageMode.copiedIntoProject,
      ),
      availability: _enumByName(
        NleMediaAvailability.values,
        row.availability,
        NleMediaAvailability.available,
      ),
      originalPath: row.originalPath,
      projectPath: row.projectPath,
      thumbnailPath: row.thumbnailPath,
      waveformCacheId: row.waveformCacheId,
      proxyPath: row.proxyPath,
      proxyStatus: _enumByName(
        NleProxyStatus.values,
        row.proxyStatus,
        NleProxyStatus.none,
      ),
      usageState: _enumByName(
        NleMediaUsageState.values,
        row.usageState,
        NleMediaUsageState.unused,
      ),
      fileInfo: NleMediaFileInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.fileInfoJson) as Map),
      ),
      videoInfo: NleMediaVideoInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.videoInfoJson) as Map),
      ),
      audioInfo: NleMediaAudioInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.audioInfoJson) as Map),
      ),
      timecodeInfo: NleMediaTimecodeInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.timecodeInfoJson) as Map),
      ),
      notes: row.notes,
      tags: (jsonDecode(row.tagsJson) as List)
          .map((item) => item.toString())
          .toList(),
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

  T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    final string = name?.toString();
    if (string == null) return fallback;

    for (final value in values) {
      if (value.name == string) return value;
    }

    return fallback;
  }
}
