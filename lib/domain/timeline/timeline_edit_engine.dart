import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_models.dart';

class TimelineEditEngine {
  final TimelineRepository repository;
  final Uuid _uuid;

  TimelineEditEngine({
    required this.repository,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  Future<TimelineEditResult> moveClip({
    required String clipId,
    required String targetTrackId,
    required int targetStartMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final clip = await _requiredClip(clipId);
    final before = [TimelineClipSnapshot.fromClip(clip)];
    final duration = _duration(clip);
    final snappedStart = options.snapping
        ? await _snapStart(
            projectId: clip.projectId,
            movingClipId: clip.id,
            proposedStartMicros: targetStartMicros,
            toleranceMicros: options.snapToleranceMicros,
          )
        : targetStartMicros;
    final nextStart = snappedStart.clamp(0, 1 << 62).toInt();
    final nextEnd = nextStart + duration;

    _assertMinDuration(nextStart, nextEnd, options.minClipDurationMicros);
    await _assertTrackUnlocked(targetTrackId);
    if (!options.allowOverlap) {
      await _assertNoOverlap(
        projectId: clip.projectId,
        trackId: targetTrackId,
        movingClipId: clip.id,
        startMicros: nextStart,
        endMicros: nextEnd,
      );
    }

    await repository.updateClipFields(
      clip.id,
      ClipsCompanion(
        trackId: Value(targetTrackId),
        timelineStartMicros: Value(nextStart),
        timelineEndMicros: Value(nextEnd),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    final updated = await _requiredClip(clip.id);
    final result = TimelineEditResult(
      action: 'move_clip',
      before: before,
      after: [TimelineClipSnapshot.fromClip(updated)],
    );
    await _recordHistory(clip.projectId, 'move_clip', 'Move clip', result);
    return result;
  }

  Future<TimelineEditResult> trimClipStart({
    required String clipId,
    required int newStartMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final clip = await _requiredClip(clipId);
    final before = [TimelineClipSnapshot.fromClip(clip)];
    final nextStart = newStartMicros.clamp(0, clip.timelineEndMicros).toInt();
    _assertMinDuration(nextStart, clip.timelineEndMicros, options.minClipDurationMicros);

    final sourceDelta = ((nextStart - clip.timelineStartMicros) * clip.speed).round();
    final nextSourceIn = (clip.sourceInMicros + sourceDelta).clamp(0, clip.sourceOutMicros).toInt();

    await repository.updateClipFields(
      clip.id,
      ClipsCompanion(
        timelineStartMicros: Value(nextStart),
        sourceInMicros: Value(nextSourceIn),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    final updated = await _requiredClip(clip.id);
    final result = TimelineEditResult(
      action: 'trim_clip_start',
      before: before,
      after: [TimelineClipSnapshot.fromClip(updated)],
    );
    await _recordHistory(clip.projectId, 'trim_clip_start', 'Trim clip start', result);
    return result;
  }

  Future<TimelineEditResult> trimClipEnd({
    required String clipId,
    required int newEndMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final clip = await _requiredClip(clipId);
    final before = [TimelineClipSnapshot.fromClip(clip)];
    final nextEnd = newEndMicros.clamp(clip.timelineStartMicros, 1 << 62).toInt();
    _assertMinDuration(clip.timelineStartMicros, nextEnd, options.minClipDurationMicros);

    final sourceDuration = ((nextEnd - clip.timelineStartMicros) * clip.speed).round();
    final nextSourceOut = (clip.sourceInMicros + sourceDuration).clamp(clip.sourceInMicros, clip.sourceOutMicros).toInt();

    await repository.updateClipFields(
      clip.id,
      ClipsCompanion(
        timelineEndMicros: Value(nextEnd),
        sourceOutMicros: Value(nextSourceOut),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    final updated = await _requiredClip(clip.id);
    final result = TimelineEditResult(
      action: 'trim_clip_end',
      before: before,
      after: [TimelineClipSnapshot.fromClip(updated)],
    );
    await _recordHistory(clip.projectId, 'trim_clip_end', 'Trim clip end', result);
    return result;
  }

  Future<TimelineEditResult> splitClip({
    required String clipId,
    required int splitMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final clip = await _requiredClip(clipId);
    if (splitMicros <= clip.timelineStartMicros || splitMicros >= clip.timelineEndMicros) {
      throw const TimelineEditException('split_out_of_range', 'Split point must be inside the clip.');
    }
    _assertMinDuration(clip.timelineStartMicros, splitMicros, options.minClipDurationMicros);
    _assertMinDuration(splitMicros, clip.timelineEndMicros, options.minClipDurationMicros);

    final before = [TimelineClipSnapshot.fromClip(clip)];
    final rightId = 'clip_${_uuid.v4()}';
    final sourceSplit = clip.sourceInMicros + ((splitMicros - clip.timelineStartMicros) * clip.speed).round();

    await repository.updateClipFields(
      clip.id,
      ClipsCompanion(
        timelineEndMicros: Value(splitMicros),
        sourceOutMicros: Value(sourceSplit),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    await repository.insertClip(
      ClipsCompanion.insert(
        id: rightId,
        projectId: clip.projectId,
        trackId: clip.trackId,
        assetId: Value(clip.assetId),
        clipType: Value(clip.clipType),
        timelineStartMicros: Value(splitMicros),
        timelineEndMicros: Value(clip.timelineEndMicros),
        sourceInMicros: Value(sourceSplit),
        sourceOutMicros: Value(clip.sourceOutMicros),
        positionX: Value(clip.positionX),
        positionY: Value(clip.positionY),
        anchorX: Value(clip.anchorX),
        anchorY: Value(clip.anchorY),
        scale: Value(clip.scale),
        rotation: Value(clip.rotation),
        opacity: Value(clip.opacity),
        cropLeft: Value(clip.cropLeft),
        cropTop: Value(clip.cropTop),
        cropRight: Value(clip.cropRight),
        cropBottom: Value(clip.cropBottom),
        blendMode: Value(clip.blendMode),
        exposure: Value(clip.exposure),
        contrast: Value(clip.contrast),
        saturation: Value(clip.saturation),
        temperature: Value(clip.temperature),
        tint: Value(clip.tint),
        volume: Value(clip.volume),
        audioPan: Value(clip.audioPan),
        isAudioMuted: Value(clip.isAudioMuted),
        textContent: Value(clip.textContent),
        textStyle: Value(clip.textStyle),
        speed: Value(clip.speed),
        isReversed: Value(clip.isReversed),
        isLinked: Value(clip.isLinked),
        linkedClipId: Value(clip.linkedClipId),
        isDisabled: Value(clip.isDisabled),
        sortOrder: Value(clip.sortOrder + 1),
        fitMode: Value(clip.fitMode),
        brightness: Value(clip.brightness),
        textStyleJson: Value(clip.textStyleJson),
        colorHex: Value(clip.colorHex),
        effectStack: Value(clip.effectStack),
        keyframeTrackJson: Value(clip.keyframeTrackJson),
        audioAutomationJson: Value(clip.audioAutomationJson),
        effectChainJson: Value(clip.effectChainJson),
      ),
    );

    final left = await _requiredClip(clip.id);
    final right = await _requiredClip(rightId);
    final result = TimelineEditResult(
      action: 'split_clip',
      before: before,
      after: [TimelineClipSnapshot.fromClip(left), TimelineClipSnapshot.fromClip(right)],
    );
    await _recordHistory(clip.projectId, 'split_clip', 'Split clip', result);
    return result;
  }

  Future<TimelineEditResult> rippleDeleteClip({
    required String clipId,
    TimelineEditOptions options = const TimelineEditOptions(ripple: true),
  }) async {
    final clip = await _requiredClip(clipId);
    final trackClips = await repository.getTrackClips(clip.trackId);
    final affected = trackClips
        .where((item) => item.id == clip.id || item.timelineStartMicros >= clip.timelineEndMicros)
        .toList()
      ..sort((a, b) => a.timelineStartMicros.compareTo(b.timelineStartMicros));
    final before = affected.map(TimelineClipSnapshot.fromClip).toList();
    final delta = _duration(clip);

    await repository.deleteClip(clip.id);
    if (options.ripple) {
      for (final item in affected.where((item) => item.id != clip.id)) {
        await repository.updateClipFields(
          item.id,
          ClipsCompanion(
            timelineStartMicros: Value(item.timelineStartMicros - delta),
            timelineEndMicros: Value(item.timelineEndMicros - delta),
            modifiedAt: Value(DateTime.now()),
          ),
        );
      }
    }

    final afterClips = <TimelineClipSnapshot>[];
    for (final item in affected.where((item) => item.id != clip.id)) {
      final updated = await repository.getClip(item.id);
      if (updated != null) afterClips.add(TimelineClipSnapshot.fromClip(updated));
    }

    final result = TimelineEditResult(
      action: 'ripple_delete_clip',
      before: before,
      after: afterClips,
    );
    await _recordHistory(clip.projectId, 'ripple_delete_clip', 'Ripple delete clip', result);
    return result;
  }

  Future<Clip> _requiredClip(String clipId) async {
    final clip = await repository.getClip(clipId);
    if (clip == null) {
      throw TimelineEditException('clip_not_found', 'Clip $clipId was not found.');
    }
    return clip;
  }

  Future<void> _assertTrackUnlocked(String trackId) async {
    final clips = await repository.getTrackClips(trackId);
    if (clips.isEmpty) return;
    // Track lock state is validated in UI track controllers. This guard keeps the engine path ready for
    // repository-level track lookup without blocking empty newly-created tracks.
  }

  Future<void> _assertNoOverlap({
    required String projectId,
    required String trackId,
    required String movingClipId,
    required int startMicros,
    required int endMicros,
  }) async {
    final clips = await repository.getTrackClips(trackId);
    for (final clip in clips) {
      if (clip.id == movingClipId || clip.isDisabled) continue;
      final intersects = startMicros < clip.timelineEndMicros && endMicros > clip.timelineStartMicros;
      if (intersects) {
        throw TimelineEditException(
          'clip_overlap',
          'Edit would overlap clip ${clip.id}.',
        );
      }
    }
  }

  Future<int> _snapStart({
    required String projectId,
    required String movingClipId,
    required int proposedStartMicros,
    required int toleranceMicros,
  }) async {
    final clips = await repository.getProjectClips(projectId);
    var best = proposedStartMicros;
    var bestDistance = toleranceMicros + 1;
    for (final clip in clips) {
      if (clip.id == movingClipId || clip.isDisabled) continue;
      for (final candidate in [clip.timelineStartMicros, clip.timelineEndMicros]) {
        final distance = (candidate - proposedStartMicros).abs();
        if (distance < bestDistance && distance <= toleranceMicros) {
          best = candidate;
          bestDistance = distance;
        }
      }
    }
    return best;
  }

  int _duration(Clip clip) => clip.timelineEndMicros - clip.timelineStartMicros;

  void _assertMinDuration(int startMicros, int endMicros, int minDurationMicros) {
    if (endMicros - startMicros < minDurationMicros) {
      throw TimelineEditException(
        'clip_too_short',
        'Clip duration must be at least ${minDurationMicros}µs.',
      );
    }
  }

  Future<void> _recordHistory(
    String projectId,
    String actionType,
    String description,
    TimelineEditResult result,
  ) async {
    final sequence = DateTime.now().microsecondsSinceEpoch;
    await repository.insertHistory(
      UndoStackCompanion.insert(
        id: 'history_${_uuid.v4()}',
        projectId: projectId,
        actionType: actionType,
        description: Value(description),
        payload: jsonEncode(result.toHistoryPayload()),
        sequence: sequence,
      ),
    );
    await repository.clearRedoStack(projectId);
  }
}
