import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/presentation/controllers/color_curve_controller.dart';
import 'package:nle_editor/presentation/providers/color_curve_providers.dart';

final colorCurveControllerProvider =
    StateNotifierProvider.family<
        ColorCurveController,
        ColorCurveState,
        String>((ref, clipId) {
  return ColorCurveController(
    clipId: clipId,
    repository: ref.watch(colorCurveRepositoryProvider),
  );
});
