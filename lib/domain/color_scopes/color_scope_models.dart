enum NleScopeType {
  waveform,
  rgbParade,
  vectorscope,
  histogram,
}

enum NleScopeSource {
  programPreview,
  sourcePreview,
  exportFrame,
}

enum NleScopeColorSpace {
  displayReferred,
  sceneLinear,
}

class NleScopeSettings {
  final bool enabled;
  final NleScopeType activeType;
  final NleScopeSource source;
  final NleScopeColorSpace colorSpace;
  final bool showSkinToneLine;
  final bool showClippingWarnings;
  final bool showGrid;
  final bool showOverlay;
  final double refreshFps;
  final int sampleWidth;
  final int sampleHeight;

  const NleScopeSettings({
    required this.enabled,
    required this.activeType,
    required this.source,
    required this.colorSpace,
    required this.showSkinToneLine,
    required this.showClippingWarnings,
    required this.showGrid,
    required this.showOverlay,
    required this.refreshFps,
    required this.sampleWidth,
    required this.sampleHeight,
  });

  const NleScopeSettings.defaultMobile()
      : enabled = true,
        activeType = NleScopeType.waveform,
        source = NleScopeSource.programPreview,
        colorSpace = NleScopeColorSpace.displayReferred,
        showSkinToneLine = true,
        showClippingWarnings = true,
        showGrid = true,
        showOverlay = false,
        refreshFps = 12.0,
        sampleWidth = 256,
        sampleHeight = 144;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'activeType': activeType.name,
      'source': source.name,
      'colorSpace': colorSpace.name,
      'showSkinToneLine': showSkinToneLine,
      'showClippingWarnings': showClippingWarnings,
      'showGrid': showGrid,
      'showOverlay': showOverlay,
      'refreshFps': refreshFps,
      'sampleWidth': sampleWidth,
      'sampleHeight': sampleHeight,
    };
  }

  factory NleScopeSettings.fromJson(Map<String, dynamic> json) {
    return NleScopeSettings(
      enabled: json['enabled'] != false,
      activeType: _enumByName(
        NleScopeType.values,
        json['activeType'],
        NleScopeType.waveform,
      ),
      source: _enumByName(
        NleScopeSource.values,
        json['source'],
        NleScopeSource.programPreview,
      ),
      colorSpace: _enumByName(
        NleScopeColorSpace.values,
        json['colorSpace'],
        NleScopeColorSpace.displayReferred,
      ),
      showSkinToneLine: json['showSkinToneLine'] != false,
      showClippingWarnings: json['showClippingWarnings'] != false,
      showGrid: json['showGrid'] != false,
      showOverlay: json['showOverlay'] == true,
      refreshFps: (json['refreshFps'] as num?)?.toDouble() ?? 12.0,
      sampleWidth: (json['sampleWidth'] as num?)?.toInt() ?? 256,
      sampleHeight: (json['sampleHeight'] as num?)?.toInt() ?? 144,
    );
  }

  NleScopeSettings copyWith({
    bool? enabled,
    NleScopeType? activeType,
    NleScopeSource? source,
    NleScopeColorSpace? colorSpace,
    bool? showSkinToneLine,
    bool? showClippingWarnings,
    bool? showGrid,
    bool? showOverlay,
    double? refreshFps,
    int? sampleWidth,
    int? sampleHeight,
  }) {
    return NleScopeSettings(
      enabled: enabled ?? this.enabled,
      activeType: activeType ?? this.activeType,
      source: source ?? this.source,
      colorSpace: colorSpace ?? this.colorSpace,
      showSkinToneLine: showSkinToneLine ?? this.showSkinToneLine,
      showClippingWarnings: showClippingWarnings ?? this.showClippingWarnings,
      showGrid: showGrid ?? this.showGrid,
      showOverlay: showOverlay ?? this.showOverlay,
      refreshFps: refreshFps ?? this.refreshFps,
      sampleWidth: sampleWidth ?? this.sampleWidth,
      sampleHeight: sampleHeight ?? this.sampleHeight,
    );
  }
}

class NleWaveformPoint {
  final double x;
  final double y;
  final double intensity;

  const NleWaveformPoint({
    required this.x,
    required this.y,
    required this.intensity,
  });

  factory NleWaveformPoint.fromJson(Map<String, dynamic> json) {
    return NleWaveformPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NleRgbParadePoint {
  final double x;
  final double y;
  final double red;
  final double green;
  final double blue;

  const NleRgbParadePoint({
    required this.x,
    required this.y,
    required this.red,
    required this.green,
    required this.blue,
  });

  factory NleRgbParadePoint.fromJson(Map<String, dynamic> json) {
    return NleRgbParadePoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      red: (json['red'] as num?)?.toDouble() ?? 0.0,
      green: (json['green'] as num?)?.toDouble() ?? 0.0,
      blue: (json['blue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NleVectorPoint {
  final double x;
  final double y;
  final double intensity;

  const NleVectorPoint({
    required this.x,
    required this.y,
    required this.intensity,
  });

  factory NleVectorPoint.fromJson(Map<String, dynamic> json) {
    return NleVectorPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NleHistogramData {
  final List<double> luma;
  final List<double> red;
  final List<double> green;
  final List<double> blue;

  const NleHistogramData({
    required this.luma,
    required this.red,
    required this.green,
    required this.blue,
  });

  factory NleHistogramData.empty() {
    return const NleHistogramData(
      luma: [],
      red: [],
      green: [],
      blue: [],
    );
  }

  factory NleHistogramData.fromJson(Map<String, dynamic> json) {
    return NleHistogramData(
      luma: _doubleList(json['luma']),
      red: _doubleList(json['red']),
      green: _doubleList(json['green']),
      blue: _doubleList(json['blue']),
    );
  }
}

class NleClippingWarnings {
  final bool blackClipping;
  final bool whiteClipping;
  final bool redChannelClipping;
  final bool greenChannelClipping;
  final bool blueChannelClipping;
  final bool overSaturated;

  final double blackClipPercent;
  final double whiteClipPercent;
  final double redClipPercent;
  final double greenClipPercent;
  final double blueClipPercent;
  final double saturationWarningPercent;

  const NleClippingWarnings({
    required this.blackClipping,
    required this.whiteClipping,
    required this.redChannelClipping,
    required this.greenChannelClipping,
    required this.blueChannelClipping,
    required this.overSaturated,
    required this.blackClipPercent,
    required this.whiteClipPercent,
    required this.redClipPercent,
    required this.greenClipPercent,
    required this.blueClipPercent,
    required this.saturationWarningPercent,
  });

  factory NleClippingWarnings.none() {
    return const NleClippingWarnings(
      blackClipping: false,
      whiteClipping: false,
      redChannelClipping: false,
      greenChannelClipping: false,
      blueChannelClipping: false,
      overSaturated: false,
      blackClipPercent: 0.0,
      whiteClipPercent: 0.0,
      redClipPercent: 0.0,
      greenClipPercent: 0.0,
      blueClipPercent: 0.0,
      saturationWarningPercent: 0.0,
    );
  }

  factory NleClippingWarnings.fromJson(Map<String, dynamic> json) {
    return NleClippingWarnings(
      blackClipping: json['blackClipping'] == true,
      whiteClipping: json['whiteClipping'] == true,
      redChannelClipping: json['redChannelClipping'] == true,
      greenChannelClipping: json['greenChannelClipping'] == true,
      blueChannelClipping: json['blueChannelClipping'] == true,
      overSaturated: json['overSaturated'] == true,
      blackClipPercent: (json['blackClipPercent'] as num?)?.toDouble() ?? 0.0,
      whiteClipPercent: (json['whiteClipPercent'] as num?)?.toDouble() ?? 0.0,
      redClipPercent: (json['redClipPercent'] as num?)?.toDouble() ?? 0.0,
      greenClipPercent: (json['greenClipPercent'] as num?)?.toDouble() ?? 0.0,
      blueClipPercent: (json['blueClipPercent'] as num?)?.toDouble() ?? 0.0,
      saturationWarningPercent:
          (json['saturationWarningPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get hasAnyWarning {
    return blackClipping ||
        whiteClipping ||
        redChannelClipping ||
        greenChannelClipping ||
        blueChannelClipping ||
        overSaturated;
  }
}

class NleScopeFrameData {
  final int frameTimestampMicros;
  final int sampleWidth;
  final int sampleHeight;

  final List<NleWaveformPoint> waveform;
  final List<NleRgbParadePoint> rgbParade;
  final List<NleVectorPoint> vectorscope;
  final NleHistogramData histogram;
  final NleClippingWarnings warnings;

  const NleScopeFrameData({
    required this.frameTimestampMicros,
    required this.sampleWidth,
    required this.sampleHeight,
    required this.waveform,
    required this.rgbParade,
    required this.vectorscope,
    required this.histogram,
    required this.warnings,
  });

  factory NleScopeFrameData.empty() {
    return NleScopeFrameData(
      frameTimestampMicros: 0,
      sampleWidth: 0,
      sampleHeight: 0,
      waveform: const [],
      rgbParade: const [],
      vectorscope: const [],
      histogram: NleHistogramData.empty(),
      warnings: NleClippingWarnings.none(),
    );
  }

  factory NleScopeFrameData.fromJson(Map<String, dynamic> json) {
    return NleScopeFrameData(
      frameTimestampMicros:
          (json['frameTimestampMicros'] as num?)?.toInt() ?? 0,
      sampleWidth: (json['sampleWidth'] as num?)?.toInt() ?? 0,
      sampleHeight: (json['sampleHeight'] as num?)?.toInt() ?? 0,
      waveform: (json['waveform'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => NleWaveformPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      rgbParade: (json['rgbParade'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => NleRgbParadePoint.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      vectorscope: (json['vectorscope'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => NleVectorPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      histogram: NleHistogramData.fromJson(
        Map<String, dynamic>.from(json['histogram'] as Map? ?? const {}),
      ),
      warnings: NleClippingWarnings.fromJson(
        Map<String, dynamic>.from(json['warnings'] as Map? ?? const {}),
      ),
    );
  }
}

List<double> _doubleList(Object? value) {
  return (value as List? ?? const [])
      .map((e) => (e as num?)?.toDouble() ?? 0.0)
      .toList();
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? name,
  T fallback,
) {
  final string = name?.toString();
  if (string == null) return fallback;

  for (final value in values) {
    if (value.name == string) return value;
  }

  return fallback;
}
