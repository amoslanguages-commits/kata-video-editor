// 33B-PRO: Advanced Audio Automation — Repository
//
// Reads and writes [NleAudioAutomationState] as JSON to the Drift database.
// Falls back to a freshly-built default state when no persisted data exists.

import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/audio_automation/audio_automation_models.dart';
import 'package:nle_editor/domain/audio_automation/audio_automation_property_factory.dart';
import 'package:nle_editor/domain/audio_automation/audio_automation_value_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

class AudioAutomationRepository {
  final db.AppDatabase database;
  final AudioAutomationPropertyFactory propertyFactory;

  const AudioAutomationRepository({
    required this.database,
    this.propertyFactory = const AudioAutomationPropertyFactory(),
  });

  // ── Clip Automation ───────────────────────────────────────────────────────

  Future<NleAudioAutomationState> getClipAutomation({
    required String clipId,
    required int clipDurationMicros,
  }) async {
    final raw = await database.getClipAudioAutomationJson(clipId);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        return NleAudioAutomationState.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {
        // Fall through to default.
      }
    }

    return _defaultClipAutomation(
      clipId: clipId,
      clipDurationMicros: clipDurationMicros,
    );
  }

  Future<void> saveClipAutomation(NleAudioAutomationState automation) {
    return database.updateClipAudioAutomationJson(
      clipId: automation.ownerId,
      automationJson: jsonEncode(automation.toJson()),
    );
  }

  // ── Track Automation ──────────────────────────────────────────────────────

  Future<NleAudioAutomationState> getTrackAutomation({
    required String trackId,
  }) async {
    final raw = await database.getTrackAudioAutomationJson(trackId);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        return NleAudioAutomationState.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {
        // Fall through to default.
      }
    }

    return _defaultTrackAutomation(trackId: trackId);
  }

  Future<void> saveTrackAutomation(NleAudioAutomationState automation) {
    return database.updateTrackAudioAutomationJson(
      trackId: automation.ownerId,
      automationJson: jsonEncode(automation.toJson()),
    );
  }

  // ── Defaults ──────────────────────────────────────────────────────────────

  NleAudioAutomationState _defaultClipAutomation({
    required String clipId,
    required int clipDurationMicros,
  }) {
    return NleAudioAutomationState(
      ownerId: clipId,
      ownerType: NleAudioAutomationOwnerType.clip,
      writeMode: NleAudioAutomationWriteMode.read,
      ducking: const NleAudioDuckingSettings.off(),
      effectSlots: const [],
      lanes: propertyFactory.clipLanes(clipId: clipId),
      keyframeTrack: NleKeyframeTrack(
        ownerId: clipId,
        ownerType: NleKeyframeOwnerType.audioClip,
        properties: propertyFactory.clipProperties(clipId: clipId),
        clipDurationMicros: clipDurationMicros,
        version: 1,
      ),
      version: 1,
    );
  }

  NleAudioAutomationState _defaultTrackAutomation({
    required String trackId,
  }) {
    return NleAudioAutomationState(
      ownerId: trackId,
      ownerType: NleAudioAutomationOwnerType.track,
      writeMode: NleAudioAutomationWriteMode.read,
      ducking: const NleAudioDuckingSettings.off(),
      effectSlots: const [],
      lanes: propertyFactory.trackLanes(trackId: trackId),
      keyframeTrack: NleKeyframeTrack(
        ownerId: trackId,
        ownerType: NleKeyframeOwnerType.audioTrack,
        properties: propertyFactory.trackProperties(trackId: trackId),
        clipDurationMicros: 0,
        version: 1,
      ),
      version: 1,
    );
  }
}
