import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/repositories/track_controls_repository.dart';
import 'package:nle_editor/domain/editor_history/editor_action_models.dart';
import 'package:nle_editor/domain/timeline/track_graph_refresh_bridge.dart';
import 'package:nle_editor/presentation/providers/editor_history_providers.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_track_header.dart';

class TrackControlsController {
  final String projectId;
  final TrackControlsRepository repository;
  final TrackGraphRefreshBridge refreshBridge;
  final Ref ref;
  final db.AppDatabase database;

  const TrackControlsController({
    required this.projectId,
    required this.repository,
    required this.refreshBridge,
    required this.ref,
    required this.database,
  });

  Future<void> performAction({
    required String trackId,
    required TrackControlAction action,
  }) async {
    if (action == TrackControlAction.rename) {
      // Rename needs text input, so it is handled from the widget/dialog.
      return;
    }

    final before = await database.trackSnapshot(trackId);

    switch (action) {
      case TrackControlAction.mute:
        await repository.toggleMute(trackId);
        await _refresh('track_mute_changed');
        break;

      case TrackControlAction.solo:
        await repository.toggleSolo(trackId);
        await _refresh('track_solo_changed');
        break;

      case TrackControlAction.lock:
        await repository.toggleLock(trackId);
        await _refresh('track_lock_changed');
        break;

      case TrackControlAction.hide:
        await repository.toggleHide(trackId);
        await _refresh('track_visibility_changed');
        break;

      case TrackControlAction.heightUp:
        await repository.resizeTrackBy(
          trackId: trackId,
          delta: 12,
        );
        await _refresh('track_height_increased');
        break;

      case TrackControlAction.heightDown:
        await repository.resizeTrackBy(
          trackId: trackId,
          delta: -12,
        );
        await _refresh('track_height_decreased');
        break;

      case TrackControlAction.resetHeight:
        await repository.resetTrackHeight(trackId);
        await _refresh('track_height_reset');
        break;
      
      case TrackControlAction.rename:
        break;
    }

    final after = await database.trackSnapshot(trackId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.updateTrackState,
      label: 'Update Track State',
      before: {'track': before},
      after: {'track': after},
    );
  }

  Future<void> renameTrack({
    required String trackId,
    required String name,
  }) async {
    final before = await database.trackSnapshot(trackId);

    await repository.renameTrack(
      trackId: trackId,
      name: name,
    );

    final after = await database.trackSnapshot(trackId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.renameTrack,
      label: 'Rename Track',
      before: {'track': before},
      after: {'track': after},
    );

    await _refresh('track_renamed');
  }

  Future<void> _refresh(String reason) {
    return refreshBridge.refreshAfterTrackChange(
      projectId: projectId,
      reason: reason,
    );
  }
}
