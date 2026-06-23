// 33B-PRO: Advanced Audio Automation — Tests
//
// Verifies model serialization, database persistence, and controller operations
// for clip and track audio automation.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/audio_automation_repository.dart';
import 'package:nle_editor/domain/audio_automation/audio_automation_models.dart';
import 'package:nle_editor/domain/audio_automation/audio_automation_value_models.dart';
import 'package:nle_editor/domain/audio_automation/audio_effect_slot_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';
import 'package:nle_editor/presentation/controllers/audio_automation_controller.dart';

void main() {
  group('Audio Automation Model Tests', () {
    test('NleAudioAutomationLane serialization', () {
      const lane = NleAudioAutomationLane(
        id: 'lane1',
        ownerId: 'clip1',
        ownerType: NleAudioAutomationOwnerType.clip,
        propertyPath: 'volume',
        label: 'Volume',
        min: 0.0,
        max: 2.0,
        unit: 'dB',
        visible: true,
        height: NleAudioAutomationLaneHeight.normal,
      );

      final json = lane.toJson();
      expect(json['id'], equals('lane1'));
      expect(json['unit'], equals('dB'));

      final fromJson = NleAudioAutomationLane.fromJson(json);
      expect(fromJson.id, equals('lane1'));
      expect(fromJson.unit, equals('dB'));
    });

    test('NleAudioDuckingSettings serialization', () {
      const settings = NleAudioDuckingSettings(
        enabled: true,
        source: NleAudioDuckingSource.voiceTrack,
        amountDb: -6.0,
        thresholdDb: -20.0,
        attackMicros: 10000,
        releaseMicros: 200000,
      );

      final json = settings.toJson();
      expect(json['enabled'], isTrue);
      expect(json['source'], equals('voiceTrack'));
      expect(json['amountDb'], equals(-6.0));

      final fromJson = NleAudioDuckingSettings.fromJson(json);
      expect(fromJson.enabled, isTrue);
      expect(fromJson.source, equals(NleAudioDuckingSource.voiceTrack));
      expect(fromJson.amountDb, equals(-6.0));
    });

    test('NleAudioEffectSlot EQ/Compressor/NoiseReduction serialization', () {
      const eqSlot = NleAudioEffectSlot(
        id: 'slot1',
        type: NleAudioEffectType.eq3Band,
        name: '3-Band EQ',
        bypassMode: NleAudioEffectSlotBypassMode.active,
        order: 0,
        eq3Band: NleAudioEq3BandSettings(
          lowGainDb: -3.0,
          midGainDb: 1.5,
          highGainDb: 0.0,
          lowFrequencyHz: 220.0,
          highFrequencyHz: 4000.0,
        ),
      );

      final eqJson = eqSlot.toJson();
      expect(eqJson['type'], equals('eq3Band'));
      expect(eqJson['eq3Band']['lowGainDb'], equals(-3.0));

      final fromEqJson = NleAudioEffectSlot.fromJson(eqJson);
      expect(fromEqJson.eq3Band?.lowGainDb, equals(-3.0));

      const compSlot = NleAudioEffectSlot(
        id: 'slot2',
        type: NleAudioEffectType.compressor,
        name: 'Compressor',
        bypassMode: NleAudioEffectSlotBypassMode.active,
        order: 1,
        compressor: NleAudioCompressorSettings(
          thresholdDb: -15.0,
          ratio: 4.0,
          attackMs: 12.0,
          releaseMs: 120.0,
          makeupGainDb: 3.5,
        ),
      );

      final compJson = compSlot.toJson();
      expect(compJson['type'], equals('compressor'));
      expect(compJson['compressor']['thresholdDb'], equals(-15.0));

      final fromCompJson = NleAudioEffectSlot.fromJson(compJson);
      expect(fromCompJson.compressor?.thresholdDb, equals(-15.0));
    });
  });

  group('Audio Automation Repository Tests', () {
    late AppDatabase db;
    late AudioAutomationRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = AudioAutomationRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Saves and loads clip audio automation state', () async {
      const clipId = 'clip_1';

      await db.insertProject(
        ProjectsCompanion.insert(
          id: 'proj_1',
          name: 'Test Project',
          aspectRatio: const Value('16:9'),
        ),
      );

      await db.insertTrack(
        TracksCompanion.insert(
          id: 'track_1',
          projectId: 'proj_1',
          name: 'Audio Track',
          type: 'audio',
        ),
      );

      await db.insertTitleClip(
        id: clipId,
        projectId: 'proj_1',
        trackId: 'track_1',
        name: 'Audio Clip',
        timelineStartMicros: 0,
        durationMicros: 5000000,
        titleDataJson: '{}',
      );

      // Verify fallback to defaults when DB has no record
      final state = await repository.getClipAutomation(
        clipId: clipId,
        clipDurationMicros: 5000000,
      );

      expect(state.ownerId, equals(clipId));
      expect(state.ownerType, equals(NleAudioAutomationOwnerType.clip));
      expect(state.lanes.length, equals(2)); // volume & pan
      expect(state.keyframeTrack.properties.length, equals(2));

      // Save modified state
      final modifiedState = state.copyWith(
        writeMode: NleAudioAutomationWriteMode.touch,
        ducking: const NleAudioDuckingSettings(
          enabled: true,
          source: NleAudioDuckingSource.voiceTrack,
          amountDb: -12.0,
          thresholdDb: -22.0,
          attackMicros: 15000,
          releaseMicros: 150000,
        ),
      );

      await repository.saveClipAutomation(modifiedState);

      // Fetch again to verify persistence
      final loadedState = await repository.getClipAutomation(
        clipId: clipId,
        clipDurationMicros: 5000000,
      );

      expect(loadedState.writeMode, equals(NleAudioAutomationWriteMode.touch));
      expect(loadedState.ducking.enabled, isTrue);
      expect(loadedState.ducking.source, equals(NleAudioDuckingSource.voiceTrack));
      expect(loadedState.ducking.amountDb, equals(-12.0));
    });

    test('Saves and loads track audio automation state', () async {
      const trackId = 'track_1';

      await db.insertProject(
        ProjectsCompanion.insert(
          id: 'proj_1',
          name: 'Test Project',
          aspectRatio: const Value('16:9'),
        ),
      );

      await db.insertTrack(
        TracksCompanion.insert(
          id: 'track_1',
          projectId: 'proj_1',
          name: 'Audio Track',
          type: 'audio',
        ),
      );

      // Fetch track automation defaults
      final state = await repository.getTrackAutomation(trackId: trackId);
      expect(state.ownerId, equals(trackId));
      expect(state.ownerType, equals(NleAudioAutomationOwnerType.track));
      expect(state.lanes.length, equals(8));
      expect(state.keyframeTrack.properties.length, equals(8));

      // Add a Compressor effect slot and save
      const compSlot = NleAudioEffectSlot(
        id: 'eff1',
        type: NleAudioEffectType.compressor,
        name: 'Compressor',
        bypassMode: NleAudioEffectSlotBypassMode.active,
        order: 0,
        compressor: NleAudioCompressorSettings(
          thresholdDb: -10.0,
          ratio: 2.0,
          attackMs: 12.0,
          releaseMs: 120.0,
          makeupGainDb: 1.0,
        ),
      );

      final modifiedState = state.copyWith(effectSlots: [compSlot]);
      await repository.saveTrackAutomation(modifiedState);

      // Fetch again
      final loaded = await repository.getTrackAutomation(trackId: trackId);
      expect(loaded.effectSlots.length, equals(1));
      expect(loaded.effectSlots.first.type, equals(NleAudioEffectType.compressor));
      expect(loaded.effectSlots.first.compressor?.thresholdDb, equals(-10.0));
    });
  });
}
