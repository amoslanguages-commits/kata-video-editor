import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/presentation/controllers/primary_grade_controller.dart';
import 'package:nle_editor/presentation/providers/primary_grade_providers.dart';

final primaryGradeControllerProvider =
    StateNotifierProvider.family<
        PrimaryGradeController,
        PrimaryGradeState,
        String>((ref, clipId) {
  return PrimaryGradeController(
    clipId: clipId,
    repository: ref.watch(primaryGradeRepositoryProvider),
  );
});
