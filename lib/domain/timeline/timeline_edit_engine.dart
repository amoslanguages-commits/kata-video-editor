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
    await _assertTrackUnlocked(clip.trackId);
    await _assertTrackUnlocked(targetTrackId);
    if (!options.allowOverlap) {
      await _assertNoOverlap(
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
    await _assertTrackUnlocked(clip.trackId);
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
    await _assertTrackUnlocked(clip.trackId);
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
    await _assertTrackUnlocked(clip.trackId);
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
      _copyClipCompanion(
        source: clip,
        id: rightId,
        timelineStartMicros: splitMicros,
        timelineEndMicros: clip.timelineEndMicros,
        sourceInMicros: sourceSplit,
        sourceOutMicros: clip.sourceOutMicros,
        sortOrder: clip.sortOrder + 1,
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

  Future<TimelineEditResult> duplicateClip({
    required String clipId,
    int offsetMicros = 100000,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final clip = await _requiredClip(clipId);
    await _assertTrackUnlocked(clip.trackId);
    final before = [TimelineClipSnapshot.fromClip(clip)];
    final duplicateId = 'clip_${_uuid.v4()}';
    final duration = _duration(clip);
    final proposedStart = clip.timelineEndMicros + offsetMicros;
    final start = options.snapping
        ? await _snapStart(
            projectId: clip.projectId,
            movingClipId: clip.id,
            proposedStartMicros: proposedStart,
            toleranceMicros: options.snapToleranceMicros,
          )
        : proposedStart;
    final end = start + duration;

    if (!options.allowOverlap) {
      await _assertNoOverlap(
        trackId: clip.trackId,
        movingClipId: duplicateId,
        startMicros: start,
        endMicros: end,
      );
    }

    await repository.insertClip(
      _copyClipCompanion(
        source: clip,
        id: duplicateId,
        timelineStartMicros: start,
        timelineEndMicros: end,
        sourceInMicros: clip.sourceInMicros,
        sourceOutMicros: clip.sourceOutMicros,
        sortOrder: clip.sortOrder + 1,
      ),
    );

    final duplicate = await _requiredClip(duplicateId);
    final result = TimelineEditResult(
      action: 'duplicate_clip',
      before: before,
      after: [TimelineClipSnapshot.fromClip(clip), TimelineClipSnapshot.fromClip(duplicate)],
    );
    await _recordHistory(clip.projectId, 'duplicate_clip', 'Duplicate clip', result);
    return result;
  }

  Future<TimelineEditResult> slipClip({
    required String clipId,
    required int deltaMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final clip = await _requiredClip(clipId);
    await _assertTrackUnlocked(clip.trackId);
    final before = [TimelineClipSnapshot.fromClip(clip)];
    final sourceDuration = clip.sourceOutMicros - clip.sourceInMicros;
    final nextIn = (clip.sourceInMicros + deltaMicros).clamp(0, 1 << 62).toInt();
    final nextOut = nextIn + sourceDuration;
    _assertMinDuration(nextIn, nextOut, options.minClipDurationMicros);

    await repository.updateClipFields(
      clip.id,
      ClipsCompanion(
        sourceInMicros: Value(nextIn),
        sourceOutMicros: Value(nextOut),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    final updated = await _requiredClip(clip.id);
    final result = TimelineEditResult(
      action: 'slip_clip',
      before: before,
      after: [TimelineClipSnapshot.fromClip(updated)],
    );
    await _recordHistory(clip.projectId, 'slip_clip', 'Slip clip', result);
    return result;
  }

  Future<TimelineEditResult> slideClip({
    required String clipId,
    required int deltaMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final clip = await _requiredClip(clipId);
    await _assertTrackUnlocked(clip.trackId);
    final trackClips = await repository.getTrackClips(clip.trackId)
      ..sort((a, b) => a.timelineStartMicros.compareTo(b.timelineStartMicros));
    final index = trackClips.indexWhere((item) => item.id == clip.id);
    if (index < 0) throw TimelineEditException('clip_not_found', 'Clip $clipId was not found on its track.');
    if (index == 0 || index == trackClips.length - 1) {
      throw const TimelineEditException('slide_requires_neighbors', 'Slide edit requires clips on both sides.');
    }

    final previous = trackClips[index - 1];
    final next = trackClips[index + 1];
    await _assertTrackUnlocked(previous.trackId);
    await _assertTrackUnlocked(next.trackId);

    final before = [previous, clip, next].map(TimelineClipSnapshot.fromClip).toList();
    final duration = _duration(clip);
    final minStart = previous.timelineStartMicros + options.minClipDurationMicros;
    final maxStart = next.timelineEndMicros - options.minClipDurationMicros - duration;
    final targetStart = (clip.timelineStartMicros + deltaMicros).clamp(minStart, maxStart).toInt();
    final targetEnd = targetStart + duration;

    await repository.updateClipFields(
      previous.id,
      ClipsCompanion(
        timelineEndMicros: Value(targetStart),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    await repository.updateClipFields(
      clip.id,
      ClipsCompanion(
        timelineStartMicros: Value(targetStart),
        timelineEndMicros: Value(targetEnd),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    await repository.updateClipFields(
      next.id,
      ClipsCompanion(
        timelineStartMicros: Value(targetEnd),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    final updatedPrevious = await _requiredClip(previous.id);
    final updatedClip = await _requiredClip(clip.id);
    final updatedNext = await _requiredClip(next.id);
    final result = TimelineEditResult(
      action: 'slide_clip',
      before: before,
      after: [updatedPrevious, updatedClip, updatedNext].map(TimelineClipSnapshot.fromClip).toList(),
    );
    await _recordHistory(clip.projectId, 'slide_clip', 'Slide clip', result);
    return result;
  }

  Future<TimelineEditResult> rollEdit({
    required String leftClipId,
    required String rightClipId,
    required int deltaMicros,
    TimelineEditOptions options = const TimelineEditOptions(),
  }) async {
    final left = await _requiredClip(leftClipId);
    final right = await _requiredClip(rightClipId);
    if (left.trackId != right.trackId) {
      throw const TimelineEditException('roll_track_mismatch', 'Roll edit requires clips on the same track.');
    }
    await _assertTrackUnlocked(left.trackId);
    final before = [left, right].map(TimelineClipSnapshot.fromClip).toList();
    final editPoint = left.timelineEndMicros;
    if (right.timelineStartMicros != editPoint) {
      throw const TimelineEditException('roll_gap_or_overlap', 'Roll edit requires adjacent clips.');
    }
    final minPoint = left.timelineStartMicros + options.minClipDurationMicros;
    final maxPoint = right.timelineEndMicros - options.minClipDurationMicros;
    final nextPoint = (editPoint + deltaMicros).clamp(minPoint, maxPoint).toInt();
    final leftSourceDuration = ((nextPoint - left.timelineStartMicros) * left.speed).round();
    final rightSourceDelta = ((nextPoint - right.timelineStartMicros) * right.speed).round();

    await repository.updateClipFields(
      left.id,
      ClipsCompanion(
        timelineEndMicros: Value(nextPoint),
        sourceOutMicros: Value(left.sourceInMicros + leftSourceDuration),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    await repository.updateClipFields(
      right.id,
      ClipsCompanion(
        timelineStartMicros: Value(nextPoint),
        sourceInMicros: Value(right.sourceInMicros + rightSourceDelta),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    final updatedLeft = await _requiredClip(left.id);
    final updatedRight = await _requiredClip(right.id);
    final result = TimelineEditResult(
      action: 'roll_edit',
      before: before,
      after: [updatedLeft, updatedRight].map(TimelineClipSnapshot.fromClip).toList(),
    );
    await _recordHistory(left.projectId, 'roll_edit', 'Roll edit', result);
    return result;
  }

  Future<TimelineEditResult> rippleDeleteClip({
    required String clipId,
    TimelineEditOptions options = const TimelineEditOptions(ripple: true),
  }) async {
    final clip = await _requiredClip(clipId);
    await _assertTrackUnlocked(clip.trackId);
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
    final track = await repository.getTrack(trackId);
    if (track.isLocked) {
      throw TimelineEditException('track_locked', 'Track ${track.name} is locked.');
    }
  }

  Future<void> _assertNoOverlap({
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

  ClipsCompanion _copyClipCompanion({
    required Clip source,
    required String id,
    required int timelineStartMicros,
    required int timelineEndMicros,
    required int sourceInMicros,
    required int sourceOutMicros,
    required int sortOrder,
  }) {
    return ClipsCompanion.insert(
      id: id,
      projectId: source.projectId,
      trackId: source.trackId,
      assetId: Value(source.assetId),
      clipType: Value(source.clipType),
      timelineStartMicros: Value(timelineStartMicros),
      timelineEndMicros: Value(timelineEndMicros),
      sourceInMicros: Value(sourceInMicros),
      sourceOutMicros: Value(sourceOutMicros),
      positionX: Value(source.positionX),
      positionY: Value(source.positionY),
      anchorX: Value(source.anchorX),
      anchorY: Value(source.anchorY),
      scale: Value(source.scale),
      rotation: Value(source.rotation),
      opacity: Value(source.opacity),
      cropLeft: Value(source.cropLeft),
      cropTop: Value(source.cropTop),
      cropRight: Value(source.cropRight),
      cropBottom: Value(source.cropBottom),
      blendMode: Value(source.blendMode),
      exposure: Value(source.exposure),
      contrast: Value(source.contrast),
      saturation: Value(source.saturation),
      temperature: Value(source.temperature),
      tint: Value(source.tint),
      highlights: Value(source.highlights),
      shadows: Value(source.shadows),
      lutPath: Value(source.lutPath),
      volume: Value(source.volume),
      audioPan: Value(source.audioPan),
      isAudioMuted: Value(source.isAudioMuted),
      fadeInMicros: Value(source.fadeInMicros),
      fadeOutMicros: Value(source.fadeOutMicros),
      textContent: Value(source.textContent),
      textStyle: Value(source.textStyle),
      speed: Value(source.speed),
      isReversed: Value(source.isReversed),
      isLinked: Value(source.isLinked),
      linkedClipId: Value(source.linkedClipId),
      isDisabled: Value(source.isDisabled),
      effectStack: Value(source.effectStack),
      sortOrder: Value(sortOrder),
      fitMode: Value(source.fitMode),
      brightness: Value(source.brightness),
      textStyleJson: Value(source.textStyleJson),
      colorHex: Value(source.colorHex),
      lutStackJson: Value(source.lutStackJson),
      primaryGradeJson: Value(source.primaryGradeJson),
      colorCurveStackJson: Value(source.colorCurveStackJson),
      secondaryGradeStackJson: Value(source.secondaryGradeStackJson),
      colorNodeGraphJson: Value(source.colorNodeGraphJson),
      isAdjustmentLayer: Value(source.isAdjustmentLayer),
      adjustmentColorGraphJson: Value(source.adjustmentColorGraphJson),
      filmLookJson: Value(source.filmLookJson),
      titleDataJson: Value(source.titleDataJson),
      isTitleClip: Value(source.isTitleClip),
      overlayDataJson: Value(source.overlayDataJson),
      isOverlayClip: Value(source.isOverlayClip),
      templateGroupId: Value(source.templateGroupId),
      sourceTemplateId: Value(source.sourceTemplateId),
      keyframeTrackJson: Value(source.keyframeTrackJson),
      audioAutomationJson: Value(source.audioAutomationJson),
      effectChainJson: Value(source.effectChainJson),
      voiceTakeId: Value(source.voiceTakeId),
      isVoiceRecording: Value(source.isVoiceRecording),
    );
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
