import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/keyframe_repository.dart';
import 'package:nle_editor/presentation/controllers/keyframe_controller.dart';
import 'package:nle_editor/presentation/providers/database_providers.dart';

final keyframeRepositoryProvider = Provider<KeyframeRepository>((ref) {
  return KeyframeRepository(ref.watch(appDatabaseProvider));
});

class KeyframeControllerArgs {
  final String clipId;
  final String clipType;
  final int clipDurationMicros;

  const KeyframeControllerArgs({
    required this.clipId,
    required this.clipType,
    required this.clipDurationMicros,
  });

  @override
  bool operator ==(Object other) {
    return other is KeyframeControllerArgs &&
        other.clipId == clipId &&
        other.clipType == clipType &&
        other.clipDurationMicros == clipDurationMicros;
  }

  @override
  int get hashCode => Object.hash(
        clipId,
        clipType,
        clipDurationMicros,
      );
}

final keyframeControllerProvider = StateNotifierProvider.family<
    KeyframeController,
    KeyframeEditorState,
    KeyframeControllerArgs>((ref, args) {
  return KeyframeController(
    clipId: args.clipId,
    clipType: args.clipType,
    clipDurationMicros: args.clipDurationMicros,
    repository: ref.watch(keyframeRepositoryProvider),
  );
});
