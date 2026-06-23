enum ClipFitMode {
  fit,
  fill,
  stretch,
}

extension ClipFitModeX on ClipFitMode {
  String get dbValue {
    switch (this) {
      case ClipFitMode.fit:
        return 'fit';
      case ClipFitMode.fill:
        return 'fill';
      case ClipFitMode.stretch:
        return 'stretch';
    }
  }

  String get label {
    switch (this) {
      case ClipFitMode.fit:
        return 'Fit';
      case ClipFitMode.fill:
        return 'Fill';
      case ClipFitMode.stretch:
        return 'Stretch';
    }
  }

  static ClipFitMode fromDb(String value) {
    switch (value.trim().toLowerCase()) {
      case 'fill':
        return ClipFitMode.fill;
      case 'stretch':
        return ClipFitMode.stretch;
      case 'fit':
      default:
        return ClipFitMode.fit;
    }
  }
}

class ClipInspectorState {
  final String clipId;
  final String projectId;
  final String trackId;
  final String? assetId;
  final String clipType;
  final String name;

  final int timelineStartMicros;
  final int timelineEndMicros;
  final int sourceStartMicros;
  final int sourceEndMicros;

  final double positionX;
  final double positionY;
  final double scale;
  final double rotation;
  final double opacity;

  final ClipFitMode fitMode;
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  final double speed;

  final double volume;
  final int fadeInMicros;
  final int fadeOutMicros;

  final double brightness;
  final double contrast;
  final double saturation;
  final double exposure;
  final double temperature;
  final double tint;
  final double highlights;
  final double shadows;

  final String textContent;
  final String? textStyleJson;
  final String? colorHex;

  final bool isDisabled;

  const ClipInspectorState({
    required this.clipId,
    required this.projectId,
    required this.trackId,
    required this.assetId,
    required this.clipType,
    required this.name,
    required this.timelineStartMicros,
    required this.timelineEndMicros,
    required this.sourceStartMicros,
    required this.sourceEndMicros,
    required this.positionX,
    required this.positionY,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.fitMode,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    required this.speed,
    required this.volume,
    required this.fadeInMicros,
    required this.fadeOutMicros,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.exposure,
    required this.temperature,
    required this.tint,
    required this.highlights,
    required this.shadows,
    required this.textContent,
    required this.textStyleJson,
    required this.colorHex,
    required this.isDisabled,
  });

  int get durationMicros => timelineEndMicros - timelineStartMicros;

  bool get isVisual {
    final type = clipType.toLowerCase();
    return type == 'video' ||
        type == 'image' ||
        type == 'photo' ||
        type == 'text' ||
        type == 'caption' ||
        type == 'title' ||
        type == 'adjustment';
  }

  bool get isAudio {
    final type = clipType.toLowerCase();
    return type == 'audio' ||
        type == 'music' ||
        type == 'voice' ||
        type == 'sfx' ||
        type == 'video';
  }

  bool get isText {
    final type = clipType.toLowerCase();
    return type == 'text' || type == 'caption' || type == 'title';
  }

  String get readableDuration {
    final seconds = durationMicros / 1000000.0;
    return '${seconds.toStringAsFixed(2)}s';
  }
}
