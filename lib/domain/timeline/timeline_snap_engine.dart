import 'dart:math' as math;

import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_models.dart';

class TimelineSnapEngine {
  const TimelineSnapEngine();

  List<TimelineSnapTarget> buildTargets({
    required List<MultitrackClip> clips,
    required int playheadMicros,
    required TimelineSnapSettings settings,
    String? activeClipId,
    List<TimelineMarkerSnapPoint> markers = const [],
  }) {
    if (!settings.enabled) return const [];

    final targets = <TimelineSnapTarget>[];

    if (settings.snapToTimelineZero) {
      targets.add(
        const TimelineSnapTarget(
          type: TimelineSnapTargetType.timelineZero,
          timelineMicros: 0,
          label: 'Timeline start',
        ),
      );
    }

    if (settings.snapToPlayhead) {
      targets.add(
        TimelineSnapTarget(
          type: TimelineSnapTargetType.playhead,
          timelineMicros: playheadMicros,
          label: 'Playhead',
        ),
      );
    }

    if (settings.snapToClipEdges) {
      for (final clip in clips) {
        if (clip.id == activeClipId) continue;
        if (clip.isDisabled) continue;

        targets.add(
          TimelineSnapTarget(
            type: TimelineSnapTargetType.clipStart,
            timelineMicros: clip.timelineStartMicros,
            label: 'Clip start',
            clipId: clip.id,
          ),
        );

        targets.add(
          TimelineSnapTarget(
            type: TimelineSnapTargetType.clipEnd,
            timelineMicros: clip.timelineEndMicros,
            label: 'Clip end',
            clipId: clip.id,
          ),
        );
      }
    }

    if (settings.snapToMarkers) {
      for (final marker in markers) {
        targets.add(
          TimelineSnapTarget(
            type: TimelineSnapTargetType.marker,
            timelineMicros: marker.timelineMicros,
            label: marker.label,
            markerId: marker.id,
          ),
        );
      }
    }

    targets.sort((a, b) => a.timelineMicros.compareTo(b.timelineMicros));

    return targets;
  }

  TimelineSnapResult snapMove({
    required MultitrackClip clip,
    required int deltaMicros,
    required TimelineScale scale,
    required List<MultitrackClip> allClips,
    required int playheadMicros,
    required TimelineSnapSettings settings,
    List<TimelineMarkerSnapPoint> markers = const [],
  }) {
    if (!settings.enabled) {
      return TimelineSnapResult(
        originalDeltaMicros: deltaMicros,
        snappedDeltaMicros: deltaMicros,
      );
    }

    final thresholdMicros = _thresholdMicros(
      scale: scale,
      thresholdPx: settings.thresholdPx,
    );

    final targets = buildTargets(
      clips: allClips,
      playheadMicros: playheadMicros,
      settings: settings,
      activeClipId: clip.id,
      markers: markers,
    );

    final movedStart = math.max(0, clip.timelineStartMicros + deltaMicros);
    final movedEnd = math.max(
      movedStart,
      clip.timelineEndMicros + deltaMicros,
    );

    final candidates = <TimelineSnapCandidate>[];

    for (final target in targets) {
      candidates.add(
        _candidateForEdge(
          target: target,
          movingEdge: TimelineSnapEdge.start,
          movingEdgeMicros: movedStart,
        ),
      );

      candidates.add(
        _candidateForEdge(
          target: target,
          movingEdge: TimelineSnapEdge.end,
          movingEdgeMicros: movedEnd,
        ),
      );
    }

    final best = _bestCandidate(
      candidates: candidates,
      thresholdMicros: thresholdMicros,
    );

    if (best == null) {
      return TimelineSnapResult(
        originalDeltaMicros: deltaMicros,
        snappedDeltaMicros: deltaMicros,
      );
    }

    final snappedDelta = deltaMicros + best.adjustmentMicros;

    final safeDelta = math.max(
      -clip.timelineStartMicros,
      snappedDelta,
    );

    return TimelineSnapResult(
      originalDeltaMicros: deltaMicros,
      snappedDeltaMicros: safeDelta,
      candidate: best,
    );
  }

  TimelineSnapResult snapTrimLeft({
    required MultitrackClip clip,
    required int deltaMicros,
    required TimelineScale scale,
    required List<MultitrackClip> allClips,
    required int playheadMicros,
    required TimelineSnapSettings settings,
    List<TimelineMarkerSnapPoint> markers = const [],
  }) {
    if (!settings.enabled) {
      return TimelineSnapResult(
        originalDeltaMicros: deltaMicros,
        snappedDeltaMicros: deltaMicros,
      );
    }

    final thresholdMicros = _thresholdMicros(
      scale: scale,
      thresholdPx: settings.thresholdPx,
    );

    final targets = buildTargets(
      clips: allClips,
      playheadMicros: playheadMicros,
      settings: settings,
      activeClipId: clip.id,
      markers: markers,
    );

    final movedStart = math.max(0, clip.timelineStartMicros + deltaMicros);

    final candidates = targets
        .map(
          (target) => _candidateForEdge(
            target: target,
            movingEdge: TimelineSnapEdge.start,
            movingEdgeMicros: movedStart,
          ),
        )
        .toList();

    final best = _bestCandidate(
      candidates: candidates,
      thresholdMicros: thresholdMicros,
    );

    if (best == null) {
      return TimelineSnapResult(
        originalDeltaMicros: deltaMicros,
        snappedDeltaMicros: deltaMicros,
      );
    }

    return TimelineSnapResult(
      originalDeltaMicros: deltaMicros,
      snappedDeltaMicros: deltaMicros + best.adjustmentMicros,
      candidate: best,
    );
  }

  TimelineSnapResult snapTrimRight({
    required MultitrackClip clip,
    required int deltaMicros,
    required TimelineScale scale,
    required List<MultitrackClip> allClips,
    required int playheadMicros,
    required TimelineSnapSettings settings,
    List<TimelineMarkerSnapPoint> markers = const [],
  }) {
    if (!settings.enabled) {
      return TimelineSnapResult(
        originalDeltaMicros: deltaMicros,
        snappedDeltaMicros: deltaMicros,
      );
    }

    final thresholdMicros = _thresholdMicros(
      scale: scale,
      thresholdPx: settings.thresholdPx,
    );

    final targets = buildTargets(
      clips: allClips,
      playheadMicros: playheadMicros,
      settings: settings,
      activeClipId: clip.id,
      markers: markers,
    );

    final movedEnd = clip.timelineEndMicros + deltaMicros;

    final candidates = targets
        .map(
          (target) => _candidateForEdge(
            target: target,
            movingEdge: TimelineSnapEdge.end,
            movingEdgeMicros: movedEnd,
          ),
        )
        .toList();

    final best = _bestCandidate(
      candidates: candidates,
      thresholdMicros: thresholdMicros,
    );

    if (best == null) {
      return TimelineSnapResult(
        originalDeltaMicros: deltaMicros,
        snappedDeltaMicros: deltaMicros,
      );
    }

    return TimelineSnapResult(
      originalDeltaMicros: deltaMicros,
      snappedDeltaMicros: deltaMicros + best.adjustmentMicros,
      candidate: best,
    );
  }

  TimelineSnapCandidate _candidateForEdge({
    required TimelineSnapTarget target,
    required TimelineSnapEdge movingEdge,
    required int movingEdgeMicros,
  }) {
    final adjustment = target.timelineMicros - movingEdgeMicros;

    return TimelineSnapCandidate(
      target: target,
      movingEdge: movingEdge,
      movingEdgeMicros: movingEdgeMicros,
      distanceMicros: adjustment.abs(),
      adjustmentMicros: adjustment,
    );
  }

  TimelineSnapCandidate? _bestCandidate({
    required List<TimelineSnapCandidate> candidates,
    required int thresholdMicros,
  }) {
    if (candidates.isEmpty) return null;

    final eligible = candidates
        .where((candidate) => candidate.distanceMicros <= thresholdMicros)
        .toList();

    if (eligible.isEmpty) return null;

    eligible.sort((a, b) {
      final distanceCompare = a.distanceMicros.compareTo(b.distanceMicros);

      if (distanceCompare != 0) return distanceCompare;

      return _targetPriority(a.target.type).compareTo(
        _targetPriority(b.target.type),
      );
    });

    return eligible.first;
  }

  int _thresholdMicros({
    required TimelineScale scale,
    required double thresholdPx,
  }) {
    return scale.pxToMicros(thresholdPx).abs();
  }

  int _targetPriority(TimelineSnapTargetType type) {
    switch (type) {
      case TimelineSnapTargetType.playhead:
        return 0;
      case TimelineSnapTargetType.timelineZero:
        return 1;
      case TimelineSnapTargetType.marker:
        return 2;
      case TimelineSnapTargetType.clipStart:
        return 3;
      case TimelineSnapTargetType.clipEnd:
        return 4;
    }
  }
}
