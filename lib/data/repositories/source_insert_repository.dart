// lib/data/repositories/source_insert_repository.dart
//
// 29F: Inserts a source in/out range selection onto the timeline.

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/source_preview/source_preview_models.dart';

class SourceInsertException implements Exception {
  final String message;
  const SourceInsertException(this.message);

  @override
  String toString() => message;
}

class SourceInsertRepository {
  final db.AppDatabase database;

  const SourceInsertRepository({required this.database});

  /// Inserts a clip from [asset]'s [inPointMicros]..[outPointMicros] range
  /// onto the timeline at [timelineStartMicros].
  ///
  /// Uses [preferredTrackId] if provided, otherwise auto-selects the first
  /// compatible track.  Returns the new clip id.
  Future<String> insertSelectedRange({
    required String projectId,
    required SourcePreviewAsset asset,
    required int inPointMicros,
    required int outPointMicros,
    required int timelineStartMicros,
    String? preferredTrackId,
  }) async {
    final safeIn  = inPointMicros.clamp(0, asset.durationMicros);
    final safeOut = outPointMicros.clamp(safeIn + 1, asset.durationMicros);

    if (safeOut <= safeIn) {
      throw const SourceInsertException('Invalid source range: out ≤ in.');
    }

    if (asset.hasVideo && asset.hasAudio) {
      // Find video track
      final videoTrackId = preferredTrackId ??
          (await database.getFirstCompatibleTrackForAsset(
            projectId: projectId,
            assetType: 'video',
          ))
              ?.id;

      // Find audio track
      final audioTrackId = (await database.getFirstCompatibleTrackForAsset(
            projectId: projectId,
            assetType: 'audio',
          ))
              ?.id;

      if (videoTrackId == null || audioTrackId == null) {
        throw const SourceInsertException(
          'Missing compatible video or audio tracks for linked insertion.',
        );
      }

      return database.insertLinkedSourceRangeClips(
        projectId: projectId,
        assetId: asset.id,
        name: asset.name,
        videoTrackId: videoTrackId,
        audioTrackId: audioTrackId,
        timelineStartMicros: timelineStartMicros,
        sourceStartMicros: safeIn,
        sourceEndMicros: safeOut,
      );
    } else {
      // Original single-track logic for purely video/image or purely audio
      final trackId = preferredTrackId ??
          (await database.getFirstCompatibleTrackForAsset(
            projectId: projectId,
            assetType: asset.assetType,
          ))
              ?.id;

      if (trackId == null) {
        throw const SourceInsertException(
          'No compatible timeline track found for this asset type.',
        );
      }

      return database.insertSourceRangeClip(
        projectId: projectId,
        assetId: asset.id,
        assetType: asset.assetType,
        name: asset.name,
        trackId: trackId,
        timelineStartMicros: timelineStartMicros,
        sourceStartMicros: safeIn,
        sourceEndMicros: safeOut,
      );
    }
  }
}
