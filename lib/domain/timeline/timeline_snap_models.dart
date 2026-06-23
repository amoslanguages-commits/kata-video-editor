import 'package:nle_editor/presentation/controllers/multitrack_timeline_controller.dart';

enum TimelineSnapTargetType {
  timelineZero,
  playhead,
  clipStart,
  clipEnd,
  marker,
}

enum TimelineSnapEdge {
  start,
  end,
}

enum TimelineSnapOperation {
  move,
  trimLeft,
  trimRight,
}

class TimelineMarkerSnapPoint {
  final String id;
  final int timelineMicros;
  final String label;

  const TimelineMarkerSnapPoint({
    required this.id,
    required this.timelineMicros,
    required this.label,
  });
}

class TimelineSnapTarget {
  final TimelineSnapTargetType type;
  final int timelineMicros;
  final String label;
  final String? clipId;
  final String? markerId;

  const TimelineSnapTarget({
    required this.type,
    required this.timelineMicros,
    required this.label,
    this.clipId,
    this.markerId,
  });
}

class TimelineSnapCandidate {
  final TimelineSnapTarget target;
  final TimelineSnapEdge movingEdge;
  final int movingEdgeMicros;
  final int distanceMicros;
  final int adjustmentMicros;

  const TimelineSnapCandidate({
    required this.target,
    required this.movingEdge,
    required this.movingEdgeMicros,
    required this.distanceMicros,
    required this.adjustmentMicros,
  });
}

class TimelineSnapResult {
  final int originalDeltaMicros;
  final int snappedDeltaMicros;
  final TimelineSnapCandidate? candidate;

  const TimelineSnapResult({
    required this.originalDeltaMicros,
    required this.snappedDeltaMicros,
    this.candidate,
  });

  bool get snapped => candidate != null;

  TimelineSnapPoint? toTimelineSnapPoint() {
    final snap = candidate;

    if (snap == null) return null;

    return TimelineSnapPoint(
      micros: snap.target.timelineMicros,
      reason: snap.target.label,
    );
  }
}

class TimelineSnapSettings {
  final bool enabled;
  final double thresholdPx;
  final bool snapToPlayhead;
  final bool snapToClipEdges;
  final bool snapToTimelineZero;
  final bool snapToMarkers;

  const TimelineSnapSettings({
    this.enabled = true,
    this.thresholdPx = 10,
    this.snapToPlayhead = true,
    this.snapToClipEdges = true,
    this.snapToTimelineZero = true,
    this.snapToMarkers = true,
  });

  TimelineSnapSettings copyWith({
    bool? enabled,
    double? thresholdPx,
    bool? snapToPlayhead,
    bool? snapToClipEdges,
    bool? snapToTimelineZero,
    bool? snapToMarkers,
  }) {
    return TimelineSnapSettings(
      enabled: enabled ?? this.enabled,
      thresholdPx: thresholdPx ?? this.thresholdPx,
      snapToPlayhead: snapToPlayhead ?? this.snapToPlayhead,
      snapToClipEdges: snapToClipEdges ?? this.snapToClipEdges,
      snapToTimelineZero: snapToTimelineZero ?? this.snapToTimelineZero,
      snapToMarkers: snapToMarkers ?? this.snapToMarkers,
    );
  }
}
