import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/presentation/controllers/overlay_clip_controller.dart';
import 'package:nle_editor/presentation/providers/overlay_clip_providers.dart';

final overlayClipControllerProvider =
    StateNotifierProvider.family<OverlayClipController, OverlayClipState, String>(
  (ref, clipId) {
    return OverlayClipController(
      clipId: clipId,
      repository: ref.watch(overlayClipRepositoryProvider),
    );
  },
);
