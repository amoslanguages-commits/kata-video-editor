import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/audio_effect_repository.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_chain_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';
import 'package:nle_editor/presentation/providers/database_providers.dart';

final audioEffectRepositoryProvider = Provider<AudioEffectRepository>((ref) {
  return AudioEffectRepository(
    database: ref.watch(appDatabaseProvider),
  );
});

class AudioEffectChainArgs {
  final String ownerId;
  final NleAudioEffectRackOwnerType ownerType;

  const AudioEffectChainArgs({
    required this.ownerId,
    required this.ownerType,
  });

  @override
  bool operator ==(Object other) {
    return other is AudioEffectChainArgs &&
        other.ownerId == ownerId &&
        other.ownerType == ownerType;
  }

  @override
  int get hashCode => Object.hash(ownerId, ownerType);
}

final audioEffectChainProvider =
    FutureProvider.family<NleAudioEffectChain, AudioEffectChainArgs>((ref, args) {
  final repo = ref.watch(audioEffectRepositoryProvider);

  switch (args.ownerType) {
    case NleAudioEffectRackOwnerType.clip:
      return repo.getClipChain(args.ownerId);

    case NleAudioEffectRackOwnerType.track:
      return repo.getTrackChain(args.ownerId);

    case NleAudioEffectRackOwnerType.master:
      return repo.getMasterChain(args.ownerId);
  }
});
