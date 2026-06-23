import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/color_curve_repository.dart';
import 'package:nle_editor/domain/color_curves/color_curve_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final colorCurveRepositoryProvider = Provider<ColorCurveRepository>((ref) {
  return ColorCurveRepository(
    database: ref.watch(databaseProvider),
  );
});

final clipColorCurveStackProvider =
    FutureProvider.family<NleColorCurveStack, String>((ref, clipId) {
  return ref.watch(colorCurveRepositoryProvider).getCurveStack(clipId);
});
