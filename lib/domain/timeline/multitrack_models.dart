import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MultitrackTrackType {
  video,
  overlay,
  text,
  adjustment,
  audio,
}

enum MultitrackClipType {
  video,
  image,
  audio,
  text,
  adjustment,
  unknown,
}

enum MultitrackTrackRole {
  mainVideo,
  broll,
  overlay,
  text,
  adjustment,
  voice,
  music,
  sfx,
  unknown,
}

class TimelineTime {
  final int micros;

  const TimelineTime(this.micros);

  double get seconds => micros / 1000000.0;

  String get timecode {
    final totalSeconds = micros ~/ 1000000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final ms = (micros % 1000000) ~/ 1000;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${ms.toString().padLeft(3, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(3, '0')}';
  }
}

class TimelineScale {
  final double pixelsPerSecond;

  const TimelineScale({
    required this.pixelsPerSecond,
  });

  static const min = TimelineScale(pixelsPerSecond: 18);
  static const normal = TimelineScale(pixelsPerSecond: 72);
  static const max = TimelineScale(pixelsPerSecond: 360);

  double microsToPx(int micros) {
    return micros / 1000000.0 * pixelsPerSecond;
  }

  int pxToMicros(double px) {
    return (px / pixelsPerSecond * 1000000.0).round();
  }

  TimelineScale zoomBy(double factor) {
    return TimelineScale(
      pixelsPerSecond: (pixelsPerSecond * factor).clamp(
        min.pixelsPerSecond,
        max.pixelsPerSecond,
      ),
    );
  }
}

class MultitrackTrack {
  final String id;
  final String projectId;
  final String name;
  final MultitrackTrackType type;
  final MultitrackTrackRole role;
  final int sortOrder;
  final bool isMuted;
  final bool isSolo;
  final bool isLocked;
  final bool isHidden;
  final double height;
  final Color color;

  const MultitrackTrack({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    required this.role,
    required this.sortOrder,
    this.isMuted = false,
    this.isSolo = false,
    this.isLocked = false,
    this.isHidden = false,
    this.height = 58,
    this.color = const Color(0xFF00E5FF),
  });

  bool get isVisual {
    return type == MultitrackTrackType.video ||
        type == MultitrackTrackType.overlay ||
        type == MultitrackTrackType.text ||
        type == MultitrackTrackType.adjustment;
  }

  bool get isAudio => type == MultitrackTrackType.audio;

  String get label {
    switch (type) {
      case MultitrackTrackType.video:
        return 'V$sortOrder';
      case MultitrackTrackType.overlay:
        return 'O$sortOrder';
      case MultitrackTrackType.text:
        return 'T$sortOrder';
      case MultitrackTrackType.adjustment:
        return 'ADJ';
      case MultitrackTrackType.audio:
        return 'A$sortOrder';
    }
  }

  MultitrackTrack copyWith({
    String? name,
    MultitrackTrackType? type,
    MultitrackTrackRole? role,
    int? sortOrder,
    bool? isMuted,
    bool? isSolo,
    bool? isLocked,
    bool? isHidden,
    double? height,
    Color? color,
  }) {
    return MultitrackTrack(
      id: id,
      projectId: projectId,
      name: name ?? this.name,
      type: type ?? this.type,
      role: role ?? this.role,
      sortOrder: sortOrder ?? this.sortOrder,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      isLocked: isLocked ?? this.isLocked,
      isHidden: isHidden ?? this.isHidden,
      height: height ?? this.height,
      color: color ?? this.color,
    );
  }
}

class MultitrackClip {
  final String id;
  final String projectId;
  final String trackId;
  final String? assetId;
  final MultitrackClipType type;
  final String name;
  final int timelineStartMicros;
  final int timelineEndMicros;
  final int sourceStartMicros;
  final int sourceEndMicros;
  final double speed;
  final double opacity;
  final double positionX;
  final double positionY;
  final double scale;
  final double rotation;
  final String? textContent;
  final String? textStyleJson;
  final String? colorHex;
  final bool isSelected;
  final bool isDisabled;

  // Visual adjustment fields
  final double brightness;
  final double contrast;
  final double saturation;

  // Crop / fit fields
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final String fitMode;

  // Audio fields
  final double volume;
  final int fadeInMicros;
  final int fadeOutMicros;

  const MultitrackClip({
    required this.id,
    required this.projectId,
    required this.trackId,
    required this.type,
    required this.name,
    required this.timelineStartMicros,
    required this.timelineEndMicros,
    this.assetId,
    this.sourceStartMicros = 0,
    this.sourceEndMicros = 0,
    this.speed = 1,
    this.opacity = 1,
    this.positionX = 0,
    this.positionY = 0,
    this.scale = 1,
    this.rotation = 0,
    this.textContent,
    this.textStyleJson,
    this.colorHex,
    this.isSelected = false,
    this.isDisabled = false,
    this.brightness = 0,
    this.contrast = 1,
    this.saturation = 1,
    this.cropLeft = 0,
    this.cropTop = 0,
    this.cropRight = 0,
    this.cropBottom = 0,
    this.fitMode = 'fit',
    this.volume = 1,
    this.fadeInMicros = 0,
    this.fadeOutMicros = 0,
  });

  int get durationMicros => math.max(0, timelineEndMicros - timelineStartMicros);

  bool get isVisual {
    return type == MultitrackClipType.video ||
        type == MultitrackClipType.image ||
        type == MultitrackClipType.text ||
        type == MultitrackClipType.adjustment;
  }

  bool get isAudio => type == MultitrackClipType.audio;

  bool contains(int timelineMicros) {
    return timelineMicros >= timelineStartMicros &&
        timelineMicros < timelineEndMicros;
  }

  int sourceTimeForTimeline(int timelineMicros) {
    final local = math.max(0, timelineMicros - timelineStartMicros);
    final scaled = (local * speed).round();
    final end = sourceEndMicros <= sourceStartMicros
        ? sourceStartMicros + durationMicros
        : sourceEndMicros;

    return (sourceStartMicros + scaled).clamp(sourceStartMicros, end);
  }

  double leftPx(TimelineScale scale) {
    return scale.microsToPx(timelineStartMicros);
  }

  double widthPx(TimelineScale scale) {
    return math.max(12, scale.microsToPx(durationMicros));
  }

  MultitrackClip copyWith({
    String? trackId,
    String? assetId,
    MultitrackClipType? type,
    String? name,
    int? timelineStartMicros,
    int? timelineEndMicros,
    int? sourceStartMicros,
    int? sourceEndMicros,
    double? speed,
    double? opacity,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    String? textContent,
    String? textStyleJson,
    String? colorHex,
    bool? isSelected,
    bool? isDisabled,
    double? brightness,
    double? contrast,
    double? saturation,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
    String? fitMode,
    double? volume,
    int? fadeInMicros,
    int? fadeOutMicros,
  }) {
    return MultitrackClip(
      id: id,
      projectId: projectId,
      trackId: trackId ?? this.trackId,
      assetId: assetId ?? this.assetId,
      type: type ?? this.type,
      name: name ?? this.name,
      timelineStartMicros: timelineStartMicros ?? this.timelineStartMicros,
      timelineEndMicros: timelineEndMicros ?? this.timelineEndMicros,
      sourceStartMicros: sourceStartMicros ?? this.sourceStartMicros,
      sourceEndMicros: sourceEndMicros ?? this.sourceEndMicros,
      speed: speed ?? this.speed,
      opacity: opacity ?? this.opacity,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      textContent: textContent ?? this.textContent,
      textStyleJson: textStyleJson ?? this.textStyleJson,
      colorHex: colorHex ?? this.colorHex,
      isSelected: isSelected ?? this.isSelected,
      isDisabled: isDisabled ?? this.isDisabled,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      fitMode: fitMode ?? this.fitMode,
      volume: volume ?? this.volume,
      fadeInMicros: fadeInMicros ?? this.fadeInMicros,
      fadeOutMicros: fadeOutMicros ?? this.fadeOutMicros,
    );
  }
}

class ResolvedVisualLayer {
  final MultitrackTrack track;
  final MultitrackClip clip;
  final int sourceTimeMicros;
  final int timelineTimeMicros;
  final int layerIndex;
  final double opacity;

  const ResolvedVisualLayer({
    required this.track,
    required this.clip,
    required this.sourceTimeMicros,
    required this.timelineTimeMicros,
    required this.layerIndex,
    required this.opacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'trackId': track.id,
      'trackType': track.type.name,
      'trackRole': track.role.name,
      'trackSortOrder': track.sortOrder,
      'clipId': clip.id,
      'assetId': clip.assetId,
      'clipType': clip.type.name,
      'timelineTimeMicros': timelineTimeMicros,
      'sourceTimeMicros': sourceTimeMicros,
      'layerIndex': layerIndex,
      'opacity': opacity,
      'positionX': clip.positionX,
      'positionY': clip.positionY,
      'scale': clip.scale,
      'rotation': clip.rotation,
    };
  }
}

class ResolvedAudioLayer {
  final MultitrackTrack track;
  final MultitrackClip clip;
  final int sourceTimeMicros;
  final int timelineTimeMicros;
  final double volume;

  const ResolvedAudioLayer({
    required this.track,
    required this.clip,
    required this.sourceTimeMicros,
    required this.timelineTimeMicros,
    required this.volume,
  });
}

class ResolvedTimelineFrame {
  final int timelineTimeMicros;
  final List<ResolvedVisualLayer> visualLayers;
  final List<ResolvedAudioLayer> audioLayers;

  const ResolvedTimelineFrame({
    required this.timelineTimeMicros,
    required this.visualLayers,
    required this.audioLayers,
  });
}
