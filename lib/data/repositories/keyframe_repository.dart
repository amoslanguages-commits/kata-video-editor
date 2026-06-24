import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/keyframes/default_keyframe_property_factory.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

class KeyframeRepository {
  final db.AppDatabase database;
  final DefaultKeyframePropertyFactory defaultFactory;

  const KeyframeRepository(
    this.database, {
    this.defaultFactory = const DefaultKeyframePropertyFactory(),
  });

  // ---------- Original Database-Backed Keyframes (for KeyframeCommandService) ----------

  Stream<List<db.Keyframe>> watchClipKeyframes(String clipId) {
    return database.watchClipKeyframes(clipId);
  }

  Future<List<db.Keyframe>> getClipKeyframes(String clipId) {
    return database.getClipKeyframes(clipId);
  }

  Future<List<db.Keyframe>> getClipParameterKeyframes({
    required String clipId,
    required String parameter,
  }) {
    return database.getClipParameterKeyframes(
      clipId: clipId,
      parameter: parameter,
    );
  }

  Future<void> insertKeyframe(db.KeyframesCompanion keyframe) {
    return database.insertKeyframe(keyframe);
  }

  Future<void> updateKeyframeFields(String keyframeId, db.KeyframesCompanion companion) {
    return database.updateKeyframeFields(keyframeId, companion);
  }

  Future<int> deleteKeyframe(String keyframeId) {
    return database.deleteKeyframe(keyframeId);
  }

  Future<int> deleteClipKeyframes(String clipId) {
    return database.deleteClipKeyframes(clipId);
  }

  // ---------- 32E-PRO: Keyframe Tracks (JSON-Backed) ----------

  Future<NleKeyframeTrack> getTrackForClip({
    required String clipId,
    required String clipType,
    required int clipDurationMicros,
  }) async {
    final raw = await database.getClipKeyframeTrackJson(clipId);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        return NleKeyframeTrack.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {}
    }

    final ownerType = _ownerTypeForClip(clipType);

    return NleKeyframeTrack(
      ownerId: clipId,
      ownerType: ownerType,
      clipDurationMicros: clipDurationMicros,
      properties: ownerType == NleKeyframeOwnerType.title
          ? defaultFactory.titleProperties(ownerId: clipId)
          : defaultFactory.overlayProperties(ownerId: clipId),
      version: 1,
    );
  }

  Future<void> saveTrack(NleKeyframeTrack track) async {
    await database.updateClipKeyframeTrackJson(
      clipId: track.ownerId,
      keyframeTrackJson: jsonEncode(track.toJson()),
    );
  }

  Future<NleKeyframeTrack> updateKeyframeTrack({
    required String clipId,
    required String clipType,
    required int clipDurationMicros,
    required NleKeyframeTrack Function(NleKeyframeTrack current) transform,
  }) async {
    final current = await getTrackForClip(
      clipId: clipId,
      clipType: clipType,
      clipDurationMicros: clipDurationMicros,
    );

    final updated = transform(current).copyWith(version: current.version + 1);
    await saveTrack(updated);
    return updated;
  }

  NleKeyframeOwnerType _ownerTypeForClip(String clipType) {
    switch (clipType) {
      case 'text':
        return NleKeyframeOwnerType.title;
      default:
        return NleKeyframeOwnerType.overlay;
    }
  }
}
