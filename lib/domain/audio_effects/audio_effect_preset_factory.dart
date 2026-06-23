import 'package:nle_editor/domain/audio_effects/audio_effect_chain_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_settings_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_slot_factory.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';

enum NleAudioEffectChainPresetId {
  cleanVoice,
  podcastVoice,
  warmMusic,
  loudSocial,
  noisyRoomCleanup,
  cinematicSpace,
}

class AudioEffectPresetFactory {
  final AudioEffectSlotFactory slotFactory;

  const AudioEffectPresetFactory({
    this.slotFactory = const AudioEffectSlotFactory(),
  });

  NleAudioEffectChain createChainPreset({
    required NleAudioEffectChainPresetId preset,
    required String ownerId,
    required NleAudioEffectRackOwnerType ownerType,
  }) {
    switch (preset) {
      case NleAudioEffectChainPresetId.cleanVoice:
        return NleAudioEffectChain(
          ownerId: ownerId,
          ownerType: ownerType,
          enabled: true,
          version: 1,
          slots: [
            slotFactory
                .create(type: NleAudioEffectType.noiseGate, order: 0),
            slotFactory.create(type: NleAudioEffectType.eq3Band, order: 1)
                .copyWith(
              eq3Band: const NleEq3BandEffectSettings.voicePresence(),
            ),
            slotFactory
                .create(type: NleAudioEffectType.compressor, order: 2)
                .copyWith(
              compressor: const NleCompressorEffectSettings.voice(),
            ),
            slotFactory.create(type: NleAudioEffectType.limiter, order: 3),
          ],
        );

      case NleAudioEffectChainPresetId.podcastVoice:
        return NleAudioEffectChain(
          ownerId: ownerId,
          ownerType: ownerType,
          enabled: true,
          version: 1,
          slots: [
            slotFactory.create(type: NleAudioEffectType.eq3Band, order: 0)
                .copyWith(
              eq3Band: const NleEq3BandEffectSettings.voicePresence(),
            ),
            slotFactory
                .create(type: NleAudioEffectType.voiceEnhancer, order: 1),
            slotFactory
                .create(type: NleAudioEffectType.compressor, order: 2),
            slotFactory.create(type: NleAudioEffectType.limiter, order: 3),
          ],
        );

      case NleAudioEffectChainPresetId.warmMusic:
        return NleAudioEffectChain(
          ownerId: ownerId,
          ownerType: ownerType,
          enabled: true,
          version: 1,
          slots: [
            slotFactory.create(type: NleAudioEffectType.eq3Band, order: 0)
                .copyWith(
              eq3Band: const NleEq3BandEffectSettings.musicWarmth(),
            ),
            slotFactory
                .create(type: NleAudioEffectType.compressor, order: 1)
                .copyWith(
              compressor: const NleCompressorEffectSettings.musicGlue(),
            ),
          ],
        );

      case NleAudioEffectChainPresetId.loudSocial:
        return NleAudioEffectChain(
          ownerId: ownerId,
          ownerType: ownerType,
          enabled: true,
          version: 1,
          slots: [
            slotFactory
                .create(type: NleAudioEffectType.compressor, order: 0),
            slotFactory.create(type: NleAudioEffectType.limiter, order: 1),
          ],
        );

      case NleAudioEffectChainPresetId.noisyRoomCleanup:
        return NleAudioEffectChain(
          ownerId: ownerId,
          ownerType: ownerType,
          enabled: true,
          version: 1,
          slots: [
            slotFactory
                .create(type: NleAudioEffectType.noiseReduction, order: 0)
                .copyWith(
              noiseReduction: const NleNoiseReductionEffectSettings.strong(),
            ),
            slotFactory
                .create(type: NleAudioEffectType.noiseGate, order: 1),
            slotFactory
                .create(type: NleAudioEffectType.voiceEnhancer, order: 2),
            slotFactory.create(type: NleAudioEffectType.limiter, order: 3),
          ],
        );

      case NleAudioEffectChainPresetId.cinematicSpace:
        return NleAudioEffectChain(
          ownerId: ownerId,
          ownerType: ownerType,
          enabled: true,
          version: 1,
          slots: [
            slotFactory.create(type: NleAudioEffectType.eq3Band, order: 0),
            slotFactory
                .create(type: NleAudioEffectType.reverb, order: 1)
                .copyWith(
              reverb: const NleReverbEffectSettings.bigSpace(),
            ),
          ],
        );
    }
  }
}
