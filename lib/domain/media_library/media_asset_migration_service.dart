import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'package:nle_editor/data/database/app_database.dart' as db;

/// One-way migration from existing project asset rows into the canonical
/// `MediaAssets` table.
///
/// This service is intentionally explicit: it does not create a second asset
/// runtime. Run it during project open/import upgrade, then keep production code
/// on `MediaAssets`.
class MediaAssetMigrationService {
  final db.AppDatabase database;

  const MediaAssetMigrationService({required this.database});

  Future<int> migrateProject(String projectId) async {
    final existing = await database.getMediaAssetsForProject(projectId);
    final existingIds = existing.map((asset) => asset.id).toSet();
    final sourceRows = await database.getProjectAssets(projectId);
    var migrated = 0;
    for (final row in sourceRows) {
      if (existingIds.contains(row.id)) continue;
      await database.upsertMediaAsset(_toMediaAsset(row));
      migrated++;
    }
    return migrated;
  }

  db.MediaAssetsCompanion _toMediaAsset(db.Asset row) {
    final extension = p.extension(row.fileName).replaceFirst('.', '').toLowerCase();
    final fileInfo = {
      'fileName': row.fileName,
      'extension': extension,
      'fileSizeBytes': row.fileSize,
      'mimeType': row.mimeType,
    };
    final videoInfo = {
      'width': row.width ?? 0,
      'height': row.height ?? 0,
      'fps': row.frameRate ?? 0.0,
      'codec': row.codec ?? '',
      'colorSpace': row.colorSpace ?? '',
      'hasHdr': row.isHdr,
      'rotationDegrees': row.rotation,
      'isVariableFrameRate': row.isVariableFrameRate,
    };
    final audioInfo = {
      'sampleRate': row.audioSampleRate ?? 0,
      'channelCount': row.audioChannels ?? 0,
      'codec': row.audioCodec ?? '',
      'bitrate': row.bitrate ?? 0,
    };
    final timecodeInfo = {
      'fps': row.frameRate ?? 30.0,
      'durationMicros': row.durationMicros ?? 0,
      'startTimecodeMicros': 0,
    };

    return db.MediaAssetsCompanion.insert(
      id: row.id,
      projectId: row.projectId,
      displayName: row.fileName,
      type: _type(row),
      importSource: row.originalUri == null ? 'filePicker' : 'photoLibrary',
      storageMode: row.importMode == 'copy' ? 'copiedIntoProject' : 'referencedExternal',
      availability: row.isMissing ? 'missing' : 'available',
      originalPath: Value(row.originalPath),
      projectPath: const Value(null),
      thumbnailPath: Value(row.thumbnailPath),
      waveformCacheId: const Value(null),
      proxyPath: Value(row.proxyPath),
      proxyStatus: Value(_proxyStatus(row.proxyStatus)),
      usageState: const Value('used'),
      fileInfoJson: jsonEncode(fileInfo),
      videoInfoJson: jsonEncode(videoInfo),
      audioInfoJson: jsonEncode(audioInfo),
      timecodeInfoJson: jsonEncode(timecodeInfo),
      notes: Value(row.errorMessage),
      tagsJson: const Value('[]'),
      importedAt: row.createdAt,
      updatedAt: row.createdAt,
      proxyMetadataJson: const Value(null),
      proxyError: const Value(null),
      proxyCreatedAt: const Value(null),
    );
  }

  String _type(db.Asset row) {
    final lower = row.fileType.toLowerCase();
    if (lower == 'video' || row.hasVideo) return 'video';
    if (lower == 'audio' || row.hasAudio) return 'audio';
    if (lower == 'image') return 'image';
    return 'unknown';
  }

  String _proxyStatus(String value) {
    switch (value) {
      case 'ready':
        return 'ready';
      case 'processing':
      case 'generating':
        return 'generating';
      case 'failed':
        return 'failed';
      case 'needed':
      case 'queued':
      case 'pending':
        return 'queued';
      default:
        return 'none';
    }
  }
}
