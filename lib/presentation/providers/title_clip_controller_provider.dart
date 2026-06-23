import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/presentation/controllers/title_clip_controller.dart';
import 'package:nle_editor/presentation/providers/title_clip_providers.dart';

final titleClipControllerProvider =
    StateNotifierProvider.family<TitleClipController, TitleClipState, String>(
  (ref, clipId) {
    return TitleClipController(
      clipId: clipId,
      repository: ref.watch(titleClipRepositoryProvider),
    );
  },
);
