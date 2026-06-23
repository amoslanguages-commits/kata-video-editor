import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/primary_grade_repository.dart';
import 'package:nle_editor/domain/color_grade/primary_grade_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final primaryGradeRepositoryProvider = Provider<PrimaryGradeRepository>((ref) {
  return PrimaryGradeRepository(
    database: ref.watch(databaseProvider),
  );
});

final clipPrimaryGradeProvider =
    FutureProvider.family<NlePrimaryGrade, String>((ref, clipId) {
  return ref.watch(primaryGradeRepositoryProvider).getPrimaryGrade(clipId);
});
