import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/editor_history/editor_history_executor.dart';
import 'package:nle_editor/domain/editor_history/editor_history_stack.dart';
import 'package:nle_editor/presentation/controllers/editor_history_controller.dart';
import 'package:nle_editor/presentation/controllers/project_autosave_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final editorAutosaveControllerProvider =
    StateNotifierProvider.family<ProjectAutosaveController, ProjectAutosaveState, String>((ref, projectId) {
  final database = ref.watch(databaseProvider);
  return ProjectAutosaveController(
    projectId: projectId,
    database: database,
  );
});

final editorHistoryExecutorProvider = Provider<EditorHistoryExecutor>((ref) {
  final database = ref.watch(databaseProvider);
  return EditorHistoryExecutor(
    database: database,
  );
});

final editorHistoryControllerProvider =
    StateNotifierProvider.family<EditorHistoryController, EditorHistoryStack, String>((ref, projectId) {
  final executor = ref.watch(editorHistoryExecutorProvider);
  final autosave = ref.watch(editorAutosaveControllerProvider(projectId).notifier);
  return EditorHistoryController(
    projectId: projectId,
    executor: executor,
    autosaveController: autosave,
  );
});
