import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/repositories/clip_interactions_repository.dart';
import 'package:nle_editor/domain/editor_history/editor_action_models.dart';
import 'package:nle_editor/domain/timeline/clip_interaction_models.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_refresh_bridge.dart';
import 'package:nle_editor/presentation/providers/editor_history_providers.dart';
import 'package:nle_editor/presentation/providers/timeline_snap_providers.dart';

class ClipInteractionsController {
  final String projectId;
  final ClipInteractionsRepository repository;
  final TimelineEditRefreshBridge refreshBridge;
  final Ref ref;
  final db.AppDatabase database;

  const ClipInteractionsController({
    required this.projectId,
    required this.repository,
    required this.refreshBridge,
    required this.ref,
    required this.database,
  });

  Future<ClipInteractionResult> moveClipBy({
    required String clipId,
    required int deltaMicros,
  }) async {
    final before = await database.clipSnapshot(clipId);

    await repository.moveClipBy(
      clipId: clipId,
      deltaMicros: deltaMicros,
    );

    final after = await database.clipSnapshot(clipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.moveClip,
      label: 'Move Clip',
      before: {'clip': before},
      after: {'clip': after},
    );

    await _refresh('clip_moved');

    return ClipInteractionResult(
      clipId: clipId,
      action: 'move',
    );
  }

  Future<ClipInteractionResult> moveClipTo({
    required String clipId,
    required String targetTrackId,
    required int newStartMicros,
  }) async {
    final before = await database.clipSnapshot(clipId);

    await repository.moveClipTo(
      clipId: clipId,
      targetTrackId: targetTrackId,
      newStartMicros: newStartMicros,
    );

    final after = await database.clipSnapshot(clipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.moveClip,
      label: 'Move Clip Track',
      before: {'clip': before},
      after: {'clip': after},
    );

    await _refresh('clip_moved_track');

    return ClipInteractionResult(
      clipId: clipId,
      action: 'move_to',
    );
  }

  Future<ClipInteractionResult> trimLeftBy({
    required String clipId,
    required int deltaMicros,
    bool ripple = false,
  }) async {
    final before = await database.clipSnapshot(clipId);

    await repository.trimLeftBy(
      clipId: clipId,
      deltaMicros: deltaMicros,
      ripple: ripple,
    );

    final after = await database.clipSnapshot(clipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.trimClip,
      label: ripple ? 'Ripple Trim Left' : 'Trim Clip Left',
      before: {'clip': before},
      after: {'clip': after},
    );

    await _refresh('clip_trim_left');

    return ClipInteractionResult(
      clipId: clipId,
      action: 'trim_left',
    );
  }

  Future<ClipInteractionResult> trimRightBy({
    required String clipId,
    required int deltaMicros,
    bool ripple = false,
  }) async {
    final before = await database.clipSnapshot(clipId);

    await repository.trimRightBy(
      clipId: clipId,
      deltaMicros: deltaMicros,
      ripple: ripple,
    );

    final after = await database.clipSnapshot(clipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.trimClip,
      label: ripple ? 'Ripple Trim Right' : 'Trim Clip Right',
      before: {'clip': before},
      after: {'clip': after},
    );

    await _refresh('clip_trim_right');

    return ClipInteractionResult(
      clipId: clipId,
      action: 'trim_right',
    );
  }

  Future<ClipInteractionResult> splitClipAt({
    required String clipId,
    required int splitMicros,
  }) async {
    final before = await database.clipSnapshot(clipId);

    final newClipId = await repository.splitClipAt(
      clipId: clipId,
      splitMicros: splitMicros,
    );

    final afterLeft = await database.clipSnapshot(clipId);
    final afterRight = await database.clipSnapshot(newClipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.splitClip,
      label: 'Split Clip',
      before: {'clip': before},
      after: {
        'leftClip': afterLeft,
        'rightClip': afterRight,
        'newClipId': newClipId,
      },
    );

    await _refresh('clip_split');

    return ClipInteractionResult(
      clipId: clipId,
      action: 'split',
      newClipId: newClipId,
    );
  }

  Future<ClipInteractionResult> deleteClip({
    required String clipId,
  }) async {
    final before = await database.clipSnapshot(clipId);
    final clip = await repository.getClip(clipId);
    final duration = clip.timelineEndMicros - clip.timelineStartMicros;
    final otherClips = await database.getTrackClips(clip.trackId);
    final clipsToShift = otherClips
        .where((c) => c.id != clipId && c.timelineStartMicros >= clip.timelineEndMicros)
        .toList();

    final magneticMode = ref.read(timelineSnapSettingsProvider).enabled;

    if (magneticMode) {
      await database.transaction(() async {
        await repository.deleteClip(clipId);
        for (final c in clipsToShift) {
          final newStart = c.timelineStartMicros - duration;
          final newEnd = c.timelineEndMicros - duration;
          await database.updateClipTiming(
            clipId: c.id,
            timelineStartMicros: newStart,
            timelineEndMicros: newEnd,
          );
        }
      });
    } else {
      await repository.deleteClip(clipId);
    }

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.deleteClip,
      label: 'Delete Clip',
      before: {'clip': before},
      after: {},
    );

    await _refresh('clip_deleted');

    return ClipInteractionResult(
      clipId: clipId,
      action: 'delete',
    );
  }

  Future<ClipInteractionResult> duplicateClip({
    required String clipId,
  }) async {
    final newClipId = await repository.duplicateClip(clipId);

    final after = await database.clipSnapshot(newClipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.duplicateClip,
      label: 'Duplicate Clip',
      before: {},
      after: {
        'clip': after,
        'insertedClipId': newClipId,
      },
    );

    await _refresh('clip_duplicated');

    return ClipInteractionResult(
      clipId: clipId,
      action: 'duplicate',
      newClipId: newClipId,
    );
  }

  Future<ClipInteractionResult> slipClipBy({
    required String clipId,
    required int deltaMicros,
  }) async {
    final before = await database.clipSnapshot(clipId);
    await repository.slipClipBy(clipId: clipId, deltaMicros: deltaMicros);
    final after = await database.clipSnapshot(clipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.trimClip,
      label: 'Slip Clip',
      before: {'clip': before},
      after: {'clip': after},
    );

    await _refresh('clip_slipped');
    return ClipInteractionResult(clipId: clipId, action: 'slip');
  }

  Future<ClipInteractionResult> slideClipBy({
    required String clipId,
    required int deltaMicros,
  }) async {
    final before = await database.clipSnapshot(clipId);
    await repository.slideClipBy(clipId: clipId, deltaMicros: deltaMicros);
    final after = await database.clipSnapshot(clipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.moveClip,
      label: 'Slide Clip',
      before: {'clip': before},
      after: {'clip': after},
    );

    await _refresh('clip_slid');
    return ClipInteractionResult(clipId: clipId, action: 'slide');
  }

  Future<ClipInteractionResult> rollEditAt({
    required String leftClipId,
    required String rightClipId,
    required int deltaMicros,
  }) async {
    final beforeLeft = await database.clipSnapshot(leftClipId);
    final beforeRight = await database.clipSnapshot(rightClipId);
    
    await repository.rollEditAt(
      leftClipId: leftClipId, 
      rightClipId: rightClipId, 
      deltaMicros: deltaMicros,
    );
    
    final afterLeft = await database.clipSnapshot(leftClipId);
    final afterRight = await database.clipSnapshot(rightClipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.trimClip,
      label: 'Roll Edit',
      before: {'leftClip': beforeLeft, 'rightClip': beforeRight},
      after: {'leftClip': afterLeft, 'rightClip': afterRight},
    );

    await _refresh('clip_roll');
    return ClipInteractionResult(clipId: leftClipId, action: 'roll');
  }

  Future<void> _refresh(String reason) {
    return refreshBridge.refresh(
      projectId: projectId,
      reason: reason,
    );
  }
}
