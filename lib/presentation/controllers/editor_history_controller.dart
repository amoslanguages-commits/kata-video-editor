// lib/presentation/controllers/editor_history_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/domain/editor_history/editor_action_models.dart';
import 'package:nle_editor/domain/editor_history/editor_history_executor.dart';
import 'package:nle_editor/domain/editor_history/editor_history_stack.dart';
import 'package:nle_editor/presentation/controllers/project_autosave_controller.dart';

class EditorHistoryController extends StateNotifier<EditorHistoryStack> {
  final String projectId;
  final EditorHistoryExecutor executor;
  final ProjectAutosaveController autosaveController;

  EditorHistoryController({
    required this.projectId,
    required this.executor,
    required this.autosaveController,
  }) : super(const EditorHistoryStack.empty());

  Future<void> record({
    required EditorActionType type,
    required String label,
    required Map<String, dynamic> before,
    required Map<String, dynamic> after,
  }) async {
    final action = EditorActionSnapshot(
      id: const Uuid().v4(),
      type: type,
      label: label,
      createdAt: DateTime.now(),
      before: before,
      after: after,
    );

    state = state.push(action);

    autosaveController.markDirty(
      reason: label,
    );
  }

  Future<void> undo() async {
    final action = state.nextUndo;
    if (action == null) return;

    await executor.undo(action);

    state = state.markUndo(action);

    autosaveController.markDirty(
      reason: 'Undo ${action.label}',
    );
  }

  Future<void> redo() async {
    final action = state.nextRedo;
    if (action == null) return;

    await executor.redo(action);

    state = state.markRedo(action);

    autosaveController.markDirty(
      reason: 'Redo ${action.label}',
    );
  }

  void clear() {
    state = state.clear();
  }
}
