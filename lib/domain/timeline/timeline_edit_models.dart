import 'package:nle_editor/data/database/app_database.dart';

class TimelineEditException implements Exception {
  final String code;
  final String message;

  const TimelineEditException(this.code, this.message);

  @override
  String toString() => 'TimelineEditException($code): $message';
}

class TimelineEditOptions {
  final bool ripple;
  final bool snapping;
  final int snapToleranceMicros;
  final bool allowOverlap;
  final int minClipDurationMicros;

  const TimelineEditOptions({
    this.ripple = false,
    this.snapping = true,
    this.snapToleranceMicros = 100000,
    this.allowOverlap = false,
    this.minClipDurationMicros = 100000,
  });
}

class TimelineClipSnapshot {
  final String id;
  final String projectId;
  final String trackId;
  final String? assetId;
  final String clipType;
  final int timelineStartMicros;
  final int timelineEndMicros;
  final int sourceInMicros;
  final int sourceOutMicros;
  final double speed;
  final bool isDisabled;

  const TimelineClipSnapshot({
    required this.id,
    required this.projectId,
    required this.trackId,
    required this.assetId,
    required this.clipType,
    required this.timelineStartMicros,
    required this.timelineEndMicros,
    required this.sourceInMicros,
    required this.sourceOutMicros,
    required this.speed,
    required this.isDisabled,
  });

  factory TimelineClipSnapshot.fromClip(Clip clip) {
    return TimelineClipSnapshot(
      id: clip.id,
      projectId: clip.projectId,
      trackId: clip.trackId,
      assetId: clip.assetId,
      clipType: clip.clipType,
      timelineStartMicros: clip.timelineStartMicros,
      timelineEndMicros: clip.timelineEndMicros,
      sourceInMicros: clip.sourceInMicros,
      sourceOutMicros: clip.sourceOutMicros,
      speed: clip.speed,
      isDisabled: clip.isDisabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'trackId': trackId,
      'assetId': assetId,
      'clipType': clipType,
      'timelineStartMicros': timelineStartMicros,
      'timelineEndMicros': timelineEndMicros,
      'sourceInMicros': sourceInMicros,
      'sourceOutMicros': sourceOutMicros,
      'speed': speed,
      'isDisabled': isDisabled,
    };
  }
}

class TimelineEditResult {
  final String action;
  final List<TimelineClipSnapshot> before;
  final List<TimelineClipSnapshot> after;

  const TimelineEditResult({
    required this.action,
    required this.before,
    required this.after,
  });

  Map<String, dynamic> toHistoryPayload() {
    return {
      'action': action,
      'before': before.map((clip) => clip.toJson()).toList(),
      'after': after.map((clip) => clip.toJson()).toList(),
    };
  }
}
