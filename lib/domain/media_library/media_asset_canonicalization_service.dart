import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'package:nle_editor/data/database/app_database.dart' as db;

class MediaAssetCanonicalizationReport {
  final String projectId;
  final int scannedRows;
  final int createdRows;
  final int existingRows;
  final int skippedRows;
  final DateTime completedAt;

  const MediaAssetCanonicalizationReport({
    required this.projectId,
    required this.scannedRows,
    required this.createdRows,
    required this.existingRows,
    required this.skippedRows,
    required this.completedAt,
  });

  bool get changed => createdRows > 0;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'scannedRows': scannedRows,
        'createdRows': createdRows,
        'existingRows': existingRows,
        'skippedRows': skippedRows,
        'completedAt': completedAt.toIso8601String(),
        'changed': changed,
      };
}

class MediaAssetCanonicalizationService {
  final db.AppDatabase database;

  const MediaAssetCanonicalizationService({required this.database});

  Future<MediaAssetCanonicalizationReport> canonicalizeProject(String projectId) async {
    final sourceRows = await database.getProjectAssetsOnce(projectId);
    var createdRows = 0;
    var existingRows = 0;
    var skippedRows = 0;

    for (final row in sourceRows) {
      final current = await database.getMediaAssetById(row.id);
      if (current != null) {
        existingRows += 1;
        continue;
      }
      if (row.originalPath.trim().isEmpty) {
        skippedRows += 1;
        continue;
      }
      await database.upsertMediaAsset(_fromAssetRow(row));
      createdRows += 1;
    }

    return MediaAssetCanonicalizationReport(
      projectId: projectId,
      scannedRows: sourceRows.length,
      createdRows: createdRows,
      existingRows: existingRows,
      skippedRows: skippedRows,
      completedAt: DateTime.now(),
    );
  }

  db.MediaAssetsCompanion _fromAssetRow(db.Asset row) {
    final originalPath = row.originalPath.trim();
    final fileName = row.fileName.trim().isNotEmpty ? row.fileName.trim() : p.basename(originalPath);
    final fileInfo = {
      'fileName': fileName,
      'extension': p.extension(fileName).replaceFirst('.', ''),
      'fileSizeBytes': row.fileSize,
      'fileModifiedAt': row.lastKnownModifiedAt?.toIso8601String(),
    };
    final videoInfo = {
      'width': row.width ?? 0,
      'height': row.height ?? 0,
      'fps': row.frameRate ?? 0.0,
      'codec': row.codec ?? '',
      'colorSpace': row.colorSpace ?? row.inputColorSpace,
      'hasHdr': row.isHdr,
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

    return db.MediaAssetsCompanion(
      id: Value(row.id),
      projectId: Value(row.projectId),
      displayName: Value(fileName),
      type: Value(_mediaType(row.fileType)),
      importSource: const Value('externalReference'),
      storageMode: Value(row.importMode == 'copy' ? 'copiedIntoProject' : 'referencedExternal'),
      availability: Value(row.isMissing ? 'missing' : 'available'),
      originalPath: Value(originalPath),
      projectPath: const Value(null),
      thumbnailPath: Value(row.thumbnailPath),
      waveformCacheId: const Value(null),
      proxyPath: Value(row.proxyPath),
      proxyStatus: Value(_proxyStatus(row.proxyStatus)),
      usageState: const Value('used'),
      fileInfoJson: Value(jsonEncode(fileInfo)),
      videoInfoJson: Value(jsonEncode(videoInfo)),
      audioInfoJson: Value(jsonEncode(audioInfo)),
      timecodeInfoJson: Value(jsonEncode(timecodeInfo)),
      notes: Value(row.errorMessage),
      tagsJson: const Value('[]'),
      importedAt: Value(row.createdAt),
      updatedAt: Value(DateTime.now()),
      version: const Value(1),
    );
  }

  String _mediaType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'video':
        return 'video';
      case 'image':
      case 'photo':
        return 'image';
      case 'audio':
      case 'music':
      case 'voice':
      case 'sfx':
        return 'audio';
      default:
        return 'unknown';
    }
  }

  String _proxyStatus(String value) {
    switch (value.toLowerCase()) {
      case 'ready':
      case 'queued':
      case 'generating':
      case 'failed':
        return value.toLowerCase();
      default:
        return 'none';
    }
  }
}
