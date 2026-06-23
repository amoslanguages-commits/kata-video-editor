import 'package:nle_editor/domain/timeline/timeline_edit_engine.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_models.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_refresh_bridge.dart';

class TimelineEditCommandController {
  final String projectId;
  final TimelineEditEngine engine;
  final TimelineEditRefreshBridge refreshBridge;

  const TimelineEditCommandController({
    required this.projectId,
    required this.engine,
    required this.refreshBridge,
  });

  Future<TimelineEditResult> moveClip({
    required String clipId,
    required String targetTrackId,
    required int targetStartMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final result = await engine.moveClip(
      clipId: clipId,
      targetTrackId: targetTrackId,
      targetStartMicros: targetStartMicros,
      options: options,
    );
    await _refresh('timeline_move_clip');
    return result;
  }

  Future<TimelineEditResult> trimStart({
    required String clipId,
    required int newStartMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final result = await engine.trimClipStart(
      clipId: clipId,
      newStartMicros: newStartMicros,
      options: options,
    );
    await _refresh('timeline_trim_start');
    return result;
  }

  Future<TimelineEditResult> trimEnd({
    required String clipId,
    required int newEndMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final result = await engine.trimClipEnd(
      clipId: clipId,
      newEndMicros: newEndMicros,
      options: options,
    );
    await _refresh('timeline_trim_end');
    return result;
  }

  Future<TimelineEditResult> split({
    required String clipId,
    required int splitMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final result = await engine.splitClip(
      clipId: clipId,
      splitMicros: splitMicros,
      options: options,
    );
    await _refresh('timeline_split_clip');
    return result;
  }

  Future<TimelineEditResult> rippleDelete({
    required String clipId,
    TimelineEditOptions options = const TimelineEditOptions(ripple: true),
  }) async {
    final result = await engine.rippleDeleteClip(
      clipId: clipId,
      options: options,
    );
    await _refresh('timeline_ripple_delete');
    return result;
  }

  Future<void> _refresh(String reason) {
    return refreshBridge.refresh(projectId: projectId, reason: reason);
  }
}
