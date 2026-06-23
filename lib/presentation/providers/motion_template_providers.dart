import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/motion_template_repository.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_models.dart';
import 'package:nle_editor/presentation/controllers/motion_template_controller.dart';
export 'package:nle_editor/presentation/controllers/motion_template_controller.dart';
import 'package:nle_editor/presentation/providers/database_providers.dart';

final motionTemplateRepositoryProvider = Provider<MotionTemplateRepository>((ref) {
  return MotionTemplateRepository(
    database: ref.watch(appDatabaseProvider),
  );
});

final motionTemplatePacksProvider = FutureProvider<List<NleMotionTemplatePack>>((ref) {
  return ref.watch(motionTemplateRepositoryProvider).getTemplatePacks();
});

final motionTemplateControllerProvider =
    StateNotifierProvider<MotionTemplateController, MotionTemplateBrowserState>((ref) {
  return MotionTemplateController(
    repository: ref.watch(motionTemplateRepositoryProvider),
  );
});
