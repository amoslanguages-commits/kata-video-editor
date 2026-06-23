// lib/domain/editor_history/editor_history_stack.dart

import 'package:nle_editor/domain/editor_history/editor_action_models.dart';

class EditorHistoryStack {
  final List<EditorActionSnapshot> undoStack;
  final List<EditorActionSnapshot> redoStack;
  final int maxDepth;

  const EditorHistoryStack({
    required this.undoStack,
    required this.redoStack,
    this.maxDepth = 80,
  });

  const EditorHistoryStack.empty({
    this.maxDepth = 80,
  })  : undoStack = const [],
        redoStack = const [];

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  EditorActionSnapshot? get nextUndo {
    if (undoStack.isEmpty) return null;
    return undoStack.last;
  }

  EditorActionSnapshot? get nextRedo {
    if (redoStack.isEmpty) return null;
    return redoStack.last;
  }

  EditorHistoryStack push(EditorActionSnapshot action) {
    final nextUndo = [...undoStack, action];

    final trimmed = nextUndo.length > maxDepth
        ? nextUndo.sublist(nextUndo.length - maxDepth)
        : nextUndo;

    return EditorHistoryStack(
      undoStack: trimmed,
      redoStack: const [],
      maxDepth: maxDepth,
    );
  }

  EditorHistoryStack markUndo(EditorActionSnapshot action) {
    final nextUndo = [...undoStack]..removeLast();
    final nextRedo = [...redoStack, action];

    return EditorHistoryStack(
      undoStack: nextUndo,
      redoStack: nextRedo,
      maxDepth: maxDepth,
    );
  }

  EditorHistoryStack markRedo(EditorActionSnapshot action) {
    final nextRedo = [...redoStack]..removeLast();
    final nextUndo = [...undoStack, action];

    return EditorHistoryStack(
      undoStack: nextUndo,
      redoStack: nextRedo,
      maxDepth: maxDepth,
    );
  }

  EditorHistoryStack clear() {
    return EditorHistoryStack(
      undoStack: const [],
      redoStack: const [],
      maxDepth: maxDepth,
    );
  }
}
