import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/secondary_grade_repository.dart';
import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final secondaryGradeRepositoryProvider =
    Provider<SecondaryGradeRepository>((ref) {
  return SecondaryGradeRepository(
    database: ref.watch(databaseProvider),
  );
});

final clipSecondaryGradeStackProvider =
    FutureProvider.family<NleSecondaryGradeStack, String>((ref, clipId) {
  return ref.watch(secondaryGradeRepositoryProvider).getStack(clipId);
});
