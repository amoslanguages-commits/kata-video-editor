import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/audio_effect_repository.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_chain_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_settings_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_preset_factory.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_slot_factory.dart';
import 'package:nle_editor/presentation/controllers/audio_effect_controller.dart';

void main() {
  group('Audio Effect Value & Settings Model Tests', () {
    test('NleAudioEffectParameter serialization', () {
      const parameter = NleAudioEffectParameter(
        id: 'param_1',
        label: 'Threshold',
        type: NleAudioEffectParameterType.gainDb,
        value: -12.0,
        min: -60.0,
        max: 0.0,
        unit: 'dB',
      );

      final json = parameter.toJson();
      expect(json['id'], equals('param_1'));
      expect(json['value'], equals(-12.0));

      final fromJson = NleAudioEffectParameter.fromJson(json);
      expect(fromJson.id, equals('param_1'));
      expect(fromJson.value, equals(-12.0));
      expect(fromJson.type, equals(NleAudioEffectParameterType.gainDb));
    });

    test('NleEq3BandEffectSettings serialization', () {
      const settings = NleEq3BandEffectSettings(
        lowGainDb: -2.0,
        midGainDb: 3.5,
        highGainDb: 1.0,
        lowFrequencyHz: 180.0,
        highFrequencyHz: 4200.0,
      );

      final json = settings.toJson();
      expect(json['lowGainDb'], equals(-2.0));
      expect(json['midGainDb'], equals(3.5));

      final fromJson = NleEq3BandEffectSettings.fromJson(json);
      expect(fromJson.lowGainDb, equals(-2.0));
      expect(fromJson.midGainDb, equals(3.5));
    });

    test('NleCompressorEffectSettings serialization', () {
      const settings = NleCompressorEffectSettings(
        thresholdDb: -24.0,
        ratio: 4.5,
        attackMs: 5.0,
        releaseMs: 180.0,
        makeupGainDb: 2.0,
        kneeDb: 6.0,
      );

      final json = settings.toJson();
      expect(json['thresholdDb'], equals(-24.0));
      expect(json['ratio'], equals(4.5));

      final fromJson = NleCompressorEffectSettings.fromJson(json);
      expect(fromJson.thresholdDb, equals(-24.0));
      expect(fromJson.ratio, equals(4.5));
    });

    test('NleLimiterEffectSettings serialization', () {
      const settings = NleLimiterEffectSettings(
        ceilingDb: -1.5,
        releaseMs: 120.0,
        truePeakSafe: true,
      );

      final json = settings.toJson();
      expect(json['ceilingDb'], equals(-1.5));
      expect(json['truePeakSafe'], isTrue);

      final fromJson = NleLimiterEffectSettings.fromJson(json);
      expect(fromJson.ceilingDb, equals(-1.5));
      expect(fromJson.truePeakSafe, isTrue);
    });

    test('NleNoiseGateEffectSettings serialization', () {
      const settings = NleNoiseGateEffectSettings(
        thresholdDb: -48.0,
        reductionDb: -24.0,
        attackMs: 2.0,
        releaseMs: 220.0,
      );

      final json = settings.toJson();
      expect(json['thresholdDb'], equals(-48.0));
      expect(json['reductionDb'], equals(-24.0));

      final fromJson = NleNoiseGateEffectSettings.fromJson(json);
      expect(fromJson.thresholdDb, equals(-48.0));
      expect(fromJson.reductionDb, equals(-24.0));
    });

    test('NleNoiseReductionEffectSettings serialization', () {
      const settings = NleNoiseReductionEffectSettings(
        amount: 0.65,
        voiceOptimized: true,
      );

      final json = settings.toJson();
      expect(json['amount'], equals(0.65));
      expect(json['voiceOptimized'], isTrue);

      final fromJson = NleNoiseReductionEffectSettings.fromJson(json);
      expect(fromJson.amount, equals(0.65));
      expect(fromJson.voiceOptimized, isTrue);
    });

    test('NleReverbEffectSettings serialization', () {
      const settings = NleReverbEffectSettings(
        roomSize: 0.5,
        damping: 0.4,
        wet: 0.25,
        dry: 0.75,
      );

      final json = settings.toJson();
      expect(json['roomSize'], equals(0.5));
      expect(json['wet'], equals(0.25));

      final fromJson = NleReverbEffectSettings.fromJson(json);
      expect(fromJson.roomSize, equals(0.5));
      expect(fromJson.wet, equals(0.25));
    });

    test('NlePitchTempoEffectSettings serialization', () {
      const settings = NlePitchTempoEffectSettings(
        pitchSemitones: -3.0,
        tempoMultiplier: 1.25,
        preserveFormants: false,
      );

      final json = settings.toJson();
      expect(json['pitchSemitones'], equals(-3.0));
      expect(json['preserveFormants'], isFalse);

      final fromJson = NlePitchTempoEffectSettings.fromJson(json);
      expect(fromJson.pitchSemitones, equals(-3.0));
      expect(fromJson.preserveFormants, isFalse);
    });

    test('NleVoiceEnhancerEffectSettings serialization', () {
      const settings = NleVoiceEnhancerEffectSettings(
        clarity: 0.6,
        body: 0.4,
        air: 0.5,
        deEss: 0.3,
      );

      final json = settings.toJson();
      expect(json['clarity'], equals(0.6));
      expect(json['deEss'], equals(0.3));

      final fromJson = NleVoiceEnhancerEffectSettings.fromJson(json);
      expect(fromJson.clarity, equals(0.6));
      expect(fromJson.deEss, equals(0.3));
    });
  });

  group('Audio Effect Chain and Slots Tests', () {
    test('NleAudioEffectSlot with EQ serialization', () {
      const slot = NleAudioEffectSlot(
        id: 'slot_1',
        type: NleAudioEffectType.eq3Band,
        name: '3-Band EQ',
        order: 0,
        bypassMode: NleAudioEffectBypassMode.active,
        wetMix: 0.8,
        eq3Band: NleEq3BandEffectSettings(
          lowGainDb: -1.0,
          midGainDb: 2.0,
          highGainDb: 0.5,
          lowFrequencyHz: 200.0,
          highFrequencyHz: 4400.0,
        ),
      );

      final json = slot.toJson();
      expect(json['id'], equals('slot_1'));
      expect(json['wetMix'], equals(0.8));
      expect(json['eq3Band']['lowGainDb'], equals(-1.0));

      final fromJson = NleAudioEffectSlot.fromJson(json);
      expect(fromJson.id, equals('slot_1'));
      expect(fromJson.wetMix, equals(0.8));
      expect(fromJson.eq3Band?.lowGainDb, equals(-1.0));
    });

    test('NleAudioEffectChain JSON Roundtrip', () {
      const chain = NleAudioEffectChain(
        ownerId: 'clip_123',
        ownerType: NleAudioEffectRackOwnerType.clip,
        enabled: true,
        version: 1,
        slots: [
          NleAudioEffectSlot(
            id: 'slot_1',
            type: NleAudioEffectType.noiseGate,
            name: 'Noise Gate',
            order: 0,
            bypassMode: NleAudioEffectBypassMode.active,
            wetMix: 1.0,
            noiseGate: NleNoiseGateEffectSettings(
              thresholdDb: -40.0,
              reductionDb: -15.0,
              attackMs: 5.0,
              releaseMs: 150.0,
            ),
          ),
        ],
      );

      final json = chain.toJson();
      expect(json['ownerId'], equals('clip_123'));
      expect(json['slots'].length, equals(1));

      final fromJson = NleAudioEffectChain.fromJson(json);
      expect(fromJson.ownerId, equals('clip_123'));
      expect(fromJson.slots.length, equals(1));
      expect(fromJson.slots.first.noiseGate?.thresholdDb, equals(-40.0));
    });
  });

  group('Audio Effect Repository & Controller tests', () {
    late AppDatabase db;
    late AudioEffectRepository repository;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = AudioEffectRepository(database: db);

      // Seed project, track, and clip
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
        id: 'clip_1',
        projectId: 'proj_1',
        trackId: 'track_1',
        name: 'Audio Clip',
        timelineStartMicros: 0,
        durationMicros: 10000000,
        titleDataJson: '{}',
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Saves and retrieves effect chains in DB', () async {
      var clipChain = await repository.getClipChain('clip_1');
      expect(clipChain.slots, isEmpty);

      clipChain = await repository.addSlot(
        chain: clipChain,
        type: NleAudioEffectType.eq3Band,
      );
      expect(clipChain.slots.length, equals(1));

      // Reload
      final reloadedChain = await repository.getClipChain('clip_1');
      expect(reloadedChain.slots.length, equals(1));
      expect(reloadedChain.slots.first.type, equals(NleAudioEffectType.eq3Band));
    });

    test('Applies presets to chain', () async {
      var clipChain = await repository.getClipChain('clip_1');
      clipChain = await repository.applyPreset(
        chain: clipChain,
        preset: NleAudioEffectChainPresetId.cleanVoice,
      );

      expect(clipChain.slots.length, equals(4));
      expect(clipChain.slots[0].type, equals(NleAudioEffectType.noiseGate));
      expect(clipChain.slots[1].type, equals(NleAudioEffectType.eq3Band));
    });

    test('AudioEffectController state modifications', () async {
      final controller = AudioEffectController(
        ownerId: 'clip_1',
        ownerType: NleAudioEffectRackOwnerType.clip,
        repository: repository,
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.loading, isFalse);
      expect(controller.state.chain?.slots, isEmpty);

      // Add slot
      await controller.addEffect(NleAudioEffectType.reverb);
      expect(controller.state.chain?.slots.length, equals(1));
      expect(controller.state.selectedSlotId, isNotNull);
      expect(controller.state.selectedSlot?.type, equals(NleAudioEffectType.reverb));

      // Toggle bypass
      final slotId = controller.state.selectedSlotId!;
      await controller.toggleBypass(slotId);
      expect(controller.state.selectedSlot?.bypassMode, equals(NleAudioEffectBypassMode.bypassed));

      // Remove slot
      await controller.removeEffect(slotId);
      expect(controller.state.chain?.slots, isEmpty);
    });
  });
}
