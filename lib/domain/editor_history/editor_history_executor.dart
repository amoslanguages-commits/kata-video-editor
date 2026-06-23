// lib/domain/editor_history/editor_history_executor.dart

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/editor_history/editor_action_models.dart';

class EditorHistoryExecutor {
  final db.AppDatabase database;

  const EditorHistoryExecutor({
    required this.database,
  });

  Future<void> undo(EditorActionSnapshot action) async {
    switch (action.type) {
      case EditorActionType.insertClip:
      case EditorActionType.sourceInsert:
      case EditorActionType.duplicateClip:
        final insertedClipId = action.after['clipId']?.toString() ??
            action.after['insertedClipId']?.toString();

        if (insertedClipId != null) {
          await database.deleteClipSnapshot(insertedClipId);
        }
        break;

      case EditorActionType.deleteClip:
        await database.restoreClipFromSnapshot(action.before['clip']);
        break;

      case EditorActionType.moveClip:
      case EditorActionType.trimClip:
      case EditorActionType.splitClip:
      case EditorActionType.updateClipInspector:
        final beforeClip = action.before['clip'];
        if (beforeClip is Map<String, dynamic>) {
          await database.restoreClipFromSnapshot(beforeClip);
        }

        final extraClip = action.after['createdClipId']?.toString() ??
            action.after['newClipId']?.toString();
        if (extraClip != null && action.type == EditorActionType.splitClip) {
          await database.deleteClipSnapshot(extraClip);
        }
        break;

      case EditorActionType.updateTrackState:
      case EditorActionType.renameTrack:
        final beforeTrack = action.before['track'];
        if (beforeTrack is Map<String, dynamic>) {
          await database.restoreTrackFromSnapshot(beforeTrack);
        }
        break;
    }
  }

  Future<void> redo(EditorActionSnapshot action) async {
    switch (action.type) {
      case EditorActionType.insertClip:
      case EditorActionType.sourceInsert:
      case EditorActionType.duplicateClip:
        final clip = action.after['clip'];
        if (clip is Map<String, dynamic>) {
          await database.restoreClipFromSnapshot(clip);
        }
        break;

      case EditorActionType.deleteClip:
        final deletedClipId = action.before['clip']?['id']?.toString();
        if (deletedClipId != null) {
          await database.deleteClipSnapshot(deletedClipId);
        }
        break;

      case EditorActionType.moveClip:
      case EditorActionType.trimClip:
      case EditorActionType.updateClipInspector:
        final afterClip = action.after['clip'];
        if (afterClip is Map<String, dynamic>) {
          await database.restoreClipFromSnapshot(afterClip);
        }
        break;

      case EditorActionType.splitClip:
        final afterLeft = action.after['leftClip'] ?? action.before['clip'];
        final afterRight = action.after['rightClip'] ?? action.after['clip'];

        if (afterLeft is Map<String, dynamic>) {
          await database.restoreClipFromSnapshot(afterLeft);
        }

        if (afterRight is Map<String, dynamic>) {
          await database.restoreClipFromSnapshot(afterRight);
        }
        break;

      case EditorActionType.updateTrackState:
      case EditorActionType.renameTrack:
        final afterTrack = action.after['track'];
        if (afterTrack is Map<String, dynamic>) {
          await database.restoreTrackFromSnapshot(afterTrack);
        }
        break;
    }
  }
}
