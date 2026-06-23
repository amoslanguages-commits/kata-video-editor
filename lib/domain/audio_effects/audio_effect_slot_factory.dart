import 'package:uuid/uuid.dart';

import 'package:nle_editor/domain/audio_effects/audio_effect_chain_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_settings_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';

class AudioEffectSlotFactory {
  static const _uuid = Uuid();

  const AudioEffectSlotFactory();

  NleAudioEffectSlot create({
    required NleAudioEffectType type,
    required int order,
  }) {
    switch (type) {
      case NleAudioEffectType.eq3Band:
        return NleAudioEffectSlot(
          id: _uuid.v4(),
          type: type,
          name: '3-Band EQ',
          order: order,
          bypassMode: NleAudioEffectBypassMode.active,
          wetMix: 1.0,
          eq3Band: const NleEq3BandEffectSettings.flat(),
        );

      case NleAudioEffectType.compressor:
        return NleAudioEffectSlot(
          id: _uuid.v4(),
          type: type,
          name: 'Compressor',
          order: order,
          bypassMode: NleAudioEffectBypassMode.active,
          wetMix: 1.0,
          compressor: const NleCompressorEffectSettings.voice(),
        );

      case NleAudioEffectType.limiter:
        return NleAudioEffectSlot(
          id: _uuid.v4(),
          type: type,
          name: 'Limiter',
          order: order,
          bypassMode: NleAudioEffectBypassMode.active,
          wetMix: 1.0,
          limiter: const NleLimiterEffectSettings.defaultLimiter(),
        );

      case NleAudioEffectType.noiseGate:
        return NleAudioEffectSlot(
          id: _uuid.v4(),
          type: type,
          name: 'Noise Gate',
          order: order,
          bypassMode: NleAudioEffectBypassMode.active,
          wetMix: 1.0,
          noiseGate: const NleNoiseGateEffectSettings.voiceClean(),
        );

      case NleAudioEffectType.noiseReduction:
        return NleAudioEffectSlot(
          id: _uuid.v4(),
          type: type,
          name: 'Noise Reduction',
          order: order,
          bypassMode: NleAudioEffectBypassMode.active,
          wetMix: 1.0,
          noiseReduction: const NleNoiseReductionEffectSettings.light(),
        );

      case NleAudioEffectType.reverb:
        return NleAudioEffectSlot(
          id: _uuid.v4(),
          type: type,
          name: 'Reverb',
          order: order,
          bypassMode: NleAudioEffectBypassMode.active,
          wetMix: 0.25,
          reverb: const NleReverbEffectSettings.smallRoom(),
        );

      case NleAudioEffectType.pitchTempo:
        return NleAudioEffectSlot(
          id: _uuid.v4(),
          type: type,
          name: 'Pitch / Tempo',
          order: order,
          bypassMode: NleAudioEffectBypassMode.active,
          wetMix: 1.0,
          pitchTempo: const NlePitchTempoEffectSettings.identity(),
        );

      case NleAudioEffectType.voiceEnhancer:
        return NleAudioEffectSlot(
          id: _uuid.v4(),
          type: type,
          name: 'Voice Enhancer',
          order: order,
          bypassMode: NleAudioEffectBypassMode.active,
          wetMix: 1.0,
          voiceEnhancer: const NleVoiceEnhancerEffectSettings.creatorVoice(),
        );
    }
  }
}
