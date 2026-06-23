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

    // Compatibility bridge:
    // Older timeline and preview code still reads from the legacy Assets table.
    // Keep that table mirrored until the whole app is fully migrated to
    // MediaAssets as the single source of truth.
    await _mirrorToLegacyAssetsTable(asset);
  }

  Future<void> deleteAsset(String assetId) async {
    await database.deleteMediaAssetById(assetId);
    await database.deleteAsset(assetId);
  }

  Future<void> setAvailability({
    required String assetId,
    required NleMediaAvailability availability,
  }) async {
    await database.updateMediaAssetAvailability(
      assetId: assetId,
      availability: availability.name,
    );

    await database.markAssetAvailable(assetId);
    if (availability != NleMediaAvailability.available) {
      await database.markAssetMissing(assetId, availability.name);
    }
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

  Future<void> _mirrorToLegacyAssetsTable(NleMediaAsset asset) async {
    final sourcePath = asset.projectPath ?? asset.originalPath;
    if (sourcePath == null || sourcePath.trim().isEmpty) return;

    final fileName = asset.fileInfo.fileName.trim().isNotEmpty
        ? asset.fileInfo.fileName.trim()
        : asset.displayName.trim().isNotEmpty
            ? asset.displayName.trim()
            : asset.id;

    await database.into(database.assets).insertOnConflictUpdate(
          db.AssetsCompanion.insert(
            id: asset.id,
            projectId: asset.projectId,
            originalPath: sourcePath,
            originalUri: Value(asset.originalPath),
            fileName: fileName,
            fileSize: Value(asset.fileInfo.fileSizeBytes),
            fileType: asset.type.name,
            durationMicros: Value(
              asset.durationMicros > 0 ? asset.durationMicros : null,
            ),
            width: Value(
              asset.videoInfo.width > 0 ? asset.videoInfo.width : null,
            ),
            height: Value(
              asset.videoInfo.height > 0 ? asset.videoInfo.height : null,
            ),
            frameRate: Value(
              asset.videoInfo.fps > 0 ? asset.videoInfo.fps : null,
            ),
            codec: Value(
              asset.videoInfo.codec.trim().isEmpty
                  ? null
                  : asset.videoInfo.codec.trim(),
            ),
            audioCodec: Value(
              asset.audioInfo.codec.trim().isEmpty
                  ? null
                  : asset.audioInfo.codec.trim(),
            ),
            bitrate: Value(
              asset.audioInfo.bitrate > 0 ? asset.audioInfo.bitrate : null,
            ),
            colorSpace: Value(
              asset.videoInfo.colorSpace.trim().isEmpty
                  ? null
                  : asset.videoInfo.colorSpace.trim(),
            ),
            audioChannels: Value(
              asset.audioInfo.channelCount > 0
                  ? asset.audioInfo.channelCount
                  : null,
            ),
            audioSampleRate: Value(
              asset.audioInfo.sampleRate > 0 ? asset.audioInfo.sampleRate : null,
            ),
            hasVideo: Value(asset.isVideo || asset.isImage),
            hasAudio: Value(asset.isVideo || asset.isAudio),
            thumbnailPath: Value(asset.thumbnailPath),
            waveformPath: Value(asset.waveformCacheId),
            proxyPath: Value(asset.proxyPath),
            proxyStatus: Value(_legacyProxyStatus(asset.proxyStatus)),
            importMode: Value(asset.storageMode.name),
            importStatus: const Value('imported'),
            isMissing: Value(asset.isMissing),
            errorMessage: Value(asset.isMissing ? asset.availability.name : null),
            inputColorSpace: Value(
              asset.videoInfo.colorSpace.trim().isEmpty
                  ? 'auto'
                  : asset.videoInfo.colorSpace.trim(),
            ),
            isHdr: Value(asset.videoInfo.hasHdr),
            lastKnownModifiedAt: Value(asset.fileInfo.fileModifiedAt),
          ),
        );
  }

  String _legacyProxyStatus(NleProxyStatus status) {
    return switch (status) {
      NleProxyStatus.none => 'not_needed',
      NleProxyStatus.queued => 'queued',
      NleProxyStatus.generating => 'generating',
      NleProxyStatus.ready => 'ready',
      NleProxyStatus.failed => 'failed',
    };
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
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  List<String> _decodeStringList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    } catch (_) {}

    return const <String>[];
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
