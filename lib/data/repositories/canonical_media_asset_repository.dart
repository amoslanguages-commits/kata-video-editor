import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'package:nle_editor/data/database/app_database.dart' as db;

/// Canonical repository for project media.
///
/// Production media code should use `MediaAssets` as the source of truth.
/// Older `Assets` rows are migrated into this model through an explicit sync
/// step so the app no longer runs two independent asset systems.
class CanonicalMediaAssetRepository {
  final db.AppDatabase _db;

  const CanonicalMediaAssetRepository(this._db);

  Stream<List<db.MediaAsset>> watchProjectMedia(String projectId) {
    return (_db.select(_db.mediaAssets)
          ..where((tbl) => tbl.projectId.equals(projectId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.importedAt)]))
        .watch();
  }

  Future<List<db.MediaAsset>> getProjectMedia(String projectId) {
    return (_db.select(_db.mediaAssets)
          ..where((tbl) => tbl.projectId.equals(projectId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.importedAt)]))
        .get();
  }

  Future<List<db.MediaAsset>> getMediaByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(const []);
    return (_db.select(_db.mediaAssets)..where((tbl) => tbl.id.isIn(ids))).get();
  }

  Future<db.MediaAsset?> getMedia(String id) {
    return (_db.select(_db.mediaAssets)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsert(db.MediaAssetsCompanion asset) {
    return _db.into(_db.mediaAssets).insertOnConflictUpdate(asset);
  }

  Future<void> update(String id, db.MediaAssetsCompanion companion) {
    return (_db.update(_db.mediaAssets)..where((tbl) => tbl.id.equals(id))).write(
      companion.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> setProxyReady({
    required String id,
    required String proxyPath,
    int? width,
    int? height,
    String? codec,
    int? fileSizeBytes,
  }) {
    final metadata = {
      'path': proxyPath,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (codec != null) 'codec': codec,
      if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    return update(
      id,
      db.MediaAssetsCompanion(
        proxyPath: Value(proxyPath),
        proxyStatus: const Value('ready'),
        proxyMetadataJson: Value(jsonEncode(metadata)),
        proxyError: const Value(null),
        proxyCreatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setProxyFailed({required String id, required String error}) {
    return update(
      id,
      db.MediaAssetsCompanion(
        proxyStatus: const Value('failed'),
        proxyError: Value(error),
      ),
    );
  }

  Future<void> setAvailability({
    required String id,
    required String availability,
    String? notes,
  }) {
    return update(
      id,
      db.MediaAssetsCompanion(
        availability: Value(availability),
        notes: notes == null ? const Value.absent() : Value(notes),
      ),
    );
  }

  Future<int> syncProjectAssetsIntoCanonicalMedia(String projectId) async {
    final existing = await getProjectMedia(projectId);
    final existingIds = existing.map((asset) => asset.id).toSet();
    final sourceAssets = await _db.getProjectAssets(projectId);
    var inserted = 0;
    for (final asset in sourceAssets) {
      if (existingIds.contains(asset.id)) continue;
      await upsert(_fromProjectAsset(asset));
      inserted++;
    }
    return inserted;
  }

  db.MediaAssetsCompanion _fromProjectAsset(db.Asset asset) {
    final extension = p.extension(asset.fileName).replaceFirst('.', '').toLowerCase();
    final fileInfo = {
      'fileName': asset.fileName,
      'extension': extension,
      'fileSizeBytes': asset.fileSize,
      'mimeType': asset.mimeType,
    };
    final videoInfo = {
      'width': asset.width ?? 0,
      'height': asset.height ?? 0,
      'fps': asset.frameRate ?? 0.0,
      'codec': asset.codec ?? '',
      'colorSpace': asset.colorSpace ?? '',
      'hasHdr': asset.isHdr,
      'rotationDegrees': asset.rotation,
      'isVariableFrameRate': asset.isVariableFrameRate,
    };
    final audioInfo = {
      'sampleRate': asset.audioSampleRate ?? 0,
      'channelCount': asset.audioChannels ?? 0,
      'codec': asset.audioCodec ?? '',
      'bitrate': asset.bitrate ?? 0,
    };
    final timecodeInfo = {
      'fps': asset.frameRate ?? 30.0,
      'durationMicros': asset.durationMicros ?? 0,
      'startTimecodeMicros': 0,
    };

    return db.MediaAssetsCompanion.insert(
      id: asset.id,
      projectId: asset.projectId,
      displayName: asset.fileName,
      type: _type(asset),
      importSource: asset.originalUri == null ? 'filePicker' : 'photoLibrary',
      storageMode: asset.importMode == 'copy' ? 'copiedIntoProject' : 'referencedExternal',
      availability: asset.isMissing ? 'missing' : 'available',
      originalPath: Value(asset.originalPath),
      projectPath: const Value(null),
      thumbnailPath: Value(asset.thumbnailPath),
      waveformCacheId: const Value(null),
      proxyPath: Value(asset.proxyPath),
      proxyStatus: Value(_proxyStatus(asset.proxyStatus)),
      usageState: const Value('used'),
      fileInfoJson: jsonEncode(fileInfo),
      videoInfoJson: jsonEncode(videoInfo),
      audioInfoJson: jsonEncode(audioInfo),
      timecodeInfoJson: jsonEncode(timecodeInfo),
      notes: Value(asset.errorMessage),
      tagsJson: const Value('[]'),
      importedAt: asset.createdAt,
      updatedAt: asset.createdAt,
      proxyMetadataJson: const Value(null),
      proxyError: const Value(null),
      proxyCreatedAt: const Value(null),
    );
  }

  String _type(db.Asset asset) {
    final lower = asset.fileType.toLowerCase();
    if (lower == 'video' || asset.hasVideo) return 'video';
    if (lower == 'audio' || asset.hasAudio) return 'audio';
    if (lower == 'image') return 'image';
    return 'unknown';
  }

  String _proxyStatus(String status) {
    switch (status) {
      case 'processing':
        return 'generating';
      case 'ready':
        return 'ready';
      case 'failed':
        return 'failed';
      case 'needed':
      case 'pending':
      case 'queued':
        return 'queued';
      default:
        return 'none';
    }
  }
}
