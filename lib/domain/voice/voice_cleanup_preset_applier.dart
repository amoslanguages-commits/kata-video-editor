import 'package:nle_editor/data/repositories/audio_effect_repository.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_preset_factory.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';
import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';

class VoiceCleanupPresetApplier {
  final AudioEffectRepository effectRepository;

  const VoiceCleanupPresetApplier({
    required this.effectRepository,
  });

  Future<void> applyToAudioClip({
    required String audioClipId,
    required NleVoiceCleanupPreset preset,
  }) async {
    if (preset == NleVoiceCleanupPreset.none) return;

    final chain = await effectRepository.getClipChain(audioClipId);

    final chainPreset = _mapPreset(preset);

    if (chainPreset == null) return;

    await effectRepository.applyPreset(
      chain: chain,
      preset: chainPreset,
    );
  }

  NleAudioEffectChainPresetId? _mapPreset(NleVoiceCleanupPreset preset) {
    switch (preset) {
      case NleVoiceCleanupPreset.none:
        return null;

      case NleVoiceCleanupPreset.cleanVoice:
        return NleAudioEffectChainPresetId.cleanVoice;

      case NleVoiceCleanupPreset.podcastVoice:
        return NleAudioEffectChainPresetId.podcastVoice;

      case NleVoiceCleanupPreset.noisyRoomCleanup:
        return NleAudioEffectChainPresetId.noisyRoomCleanup;

      case NleVoiceCleanupPreset.loudSocialVoice:
        return NleAudioEffectChainPresetId.loudSocial;

      case NleVoiceCleanupPreset.warmNarration:
        return NleAudioEffectChainPresetId.podcastVoice;
    }
  }
}
