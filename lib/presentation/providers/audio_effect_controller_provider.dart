import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';
import 'package:nle_editor/presentation/controllers/audio_effect_controller.dart';
import 'package:nle_editor/presentation/providers/audio_effect_providers.dart';

class AudioEffectControllerArgs {
  final String ownerId;
  final NleAudioEffectRackOwnerType ownerType;

  const AudioEffectControllerArgs({
    required this.ownerId,
    required this.ownerType,
  });

  @override
  bool operator ==(Object other) {
    return other is AudioEffectControllerArgs &&
        other.ownerId == ownerId &&
        other.ownerType == ownerType;
  }

  @override
  int get hashCode => Object.hash(ownerId, ownerType);
}

final audioEffectControllerProvider =
    StateNotifierProvider.family<
        AudioEffectController,
        AudioEffectRackState,
        AudioEffectControllerArgs>((ref, args) {
  return AudioEffectController(
    ownerId: args.ownerId,
    ownerType: args.ownerType,
    repository: ref.watch(audioEffectRepositoryProvider),
  );
});
