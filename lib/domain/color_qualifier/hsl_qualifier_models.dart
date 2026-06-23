enum NleQualifierViewMode {
  normal,
  matte,
  overlay,
}

enum NleSecondaryCorrectionMode {
  primary,
  curves,
  primaryAndCurves,
}

class NleRangeControl {
  final double center;
  final double width;
  final double softness;

  const NleRangeControl({
    required this.center,
    required this.width,
    required this.softness,
  });

  const NleRangeControl.full()
      : center = 0.5,
        width = 1.0,
        softness = 0.0;

  Map<String, dynamic> toJson() {
    return {
      'center': center,
      'width': width,
      'softness': softness,
    };
  }

  factory NleRangeControl.fromJson(Map<String, dynamic> json) {
    return NleRangeControl(
      center: (json['center'] as num?)?.toDouble() ?? 0.5,
      width: (json['width'] as num?)?.toDouble() ?? 1.0,
      softness: (json['softness'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleRangeControl copyWith({
    double? center,
    double? width,
    double? softness,
  }) {
    return NleRangeControl(
      center: center ?? this.center,
      width: width ?? this.width,
      softness: softness ?? this.softness,
    );
  }

  NleRangeControl clamp() {
    return NleRangeControl(
      center: center.clamp(0.0, 1.0),
      width: width.clamp(0.0, 1.0),
      softness: softness.clamp(0.0, 1.0),
    );
  }
}

class NleHslQualifier {
  final bool enabled;

  final NleRangeControl hue;
  final NleRangeControl saturation;
  final NleRangeControl luminance;

  final double cleanBlack;
  final double cleanWhite;
  final double blur;
  final bool invert;

  final NleQualifierViewMode viewMode;

  const NleHslQualifier({
    required this.enabled,
    required this.hue,
    required this.saturation,
    required this.luminance,
    required this.cleanBlack,
    required this.cleanWhite,
    required this.blur,
    required this.invert,
    required this.viewMode,
  });

  const NleHslQualifier.identity()
      : enabled = false,
        hue = const NleRangeControl.full(),
        saturation = const NleRangeControl.full(),
        luminance = const NleRangeControl.full(),
        cleanBlack = 0.0,
        cleanWhite = 0.0,
        blur = 0.0,
        invert = false,
        viewMode = NleQualifierViewMode.normal;

  bool get isIdentity {
    return !enabled;
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'hue': hue.toJson(),
      'saturation': saturation.toJson(),
      'luminance': luminance.toJson(),
      'cleanBlack': cleanBlack,
      'cleanWhite': cleanWhite,
      'blur': blur,
      'invert': invert,
      'viewMode': viewMode.name,
    };
  }

  factory NleHslQualifier.fromJson(Map<String, dynamic> json) {
    return NleHslQualifier(
      enabled: json['enabled'] == true,
      hue: NleRangeControl.fromJson(
        Map<String, dynamic>.from(json['hue'] as Map? ?? const {}),
      ).clamp(),
      saturation: NleRangeControl.fromJson(
        Map<String, dynamic>.from(json['saturation'] as Map? ?? const {}),
      ).clamp(),
      luminance: NleRangeControl.fromJson(
        Map<String, dynamic>.from(json['luminance'] as Map? ?? const {}),
      ).clamp(),
      cleanBlack: (json['cleanBlack'] as num?)?.toDouble() ?? 0.0,
      cleanWhite: (json['cleanWhite'] as num?)?.toDouble() ?? 0.0,
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      invert: json['invert'] == true,
      viewMode: _enumByName(
        NleQualifierViewMode.values,
        json['viewMode'],
        NleQualifierViewMode.normal,
      ),
    );
  }

  NleHslQualifier copyWith({
    bool? enabled,
    NleRangeControl? hue,
    NleRangeControl? saturation,
    NleRangeControl? luminance,
    double? cleanBlack,
    double? cleanWhite,
    double? blur,
    bool? invert,
    NleQualifierViewMode? viewMode,
  }) {
    return NleHslQualifier(
      enabled: enabled ?? this.enabled,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
      cleanBlack: cleanBlack ?? this.cleanBlack,
      cleanWhite: cleanWhite ?? this.cleanWhite,
      blur: blur ?? this.blur,
      invert: invert ?? this.invert,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  factory NleHslQualifier.fromPickedHsl({
    required double hue,
    required double saturation,
    required double luminance,
  }) {
    return NleHslQualifier(
      enabled: true,
      hue: NleRangeControl(
        center: hue.clamp(0.0, 1.0),
        width: 0.10,
        softness: 0.08,
      ),
      saturation: NleRangeControl(
        center: saturation.clamp(0.0, 1.0),
        width: 0.35,
        softness: 0.18,
      ),
      luminance: NleRangeControl(
        center: luminance.clamp(0.0, 1.0),
        width: 0.45,
        softness: 0.22,
      ),
      cleanBlack: 0.05,
      cleanWhite: 0.05,
      blur: 0.0,
      invert: false,
      viewMode: NleQualifierViewMode.overlay,
    );
  }
}

class NleSecondaryCorrection {
  final bool enabled;
  final double intensity;

  final double exposure;
  final double contrast;
  final double saturation;
  final double temperature;
  final double tint;

  final double lift;
  final double gamma;
  final double gain;
  final double offset;

  final NleSecondaryCorrectionMode mode;

  const NleSecondaryCorrection({
    required this.enabled,
    required this.intensity,
    required this.exposure,
    required this.contrast,
    required this.saturation,
    required this.temperature,
    required this.tint,
    required this.lift,
    required this.gamma,
    required this.gain,
    required this.offset,
    required this.mode,
  });

  const NleSecondaryCorrection.identity()
      : enabled = true,
        intensity = 1.0,
        exposure = 0.0,
        contrast = 1.0,
        saturation = 1.0,
        temperature = 0.0,
        tint = 0.0,
        lift = 0.0,
        gamma = 1.0,
        gain = 1.0,
        offset = 0.0,
        mode = NleSecondaryCorrectionMode.primary;

  bool get isIdentity {
    return enabled &&
        intensity == 1.0 &&
        exposure == 0.0 &&
        contrast == 1.0 &&
        saturation == 1.0 &&
        temperature == 0.0 &&
        tint == 0.0 &&
        lift == 0.0 &&
        gamma == 1.0 &&
        gain == 1.0 &&
        offset == 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'intensity': intensity,
      'exposure': exposure,
      'contrast': contrast,
      'saturation': saturation,
      'temperature': temperature,
      'tint': tint,
      'lift': lift,
      'gamma': gamma,
      'gain': gain,
      'offset': offset,
      'mode': mode.name,
    };
  }

  factory NleSecondaryCorrection.fromJson(Map<String, dynamic> json) {
    return NleSecondaryCorrection(
      enabled: json['enabled'] != false,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
      exposure: (json['exposure'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      tint: (json['tint'] as num?)?.toDouble() ?? 0.0,
      lift: (json['lift'] as num?)?.toDouble() ?? 0.0,
      gamma: (json['gamma'] as num?)?.toDouble() ?? 1.0,
      gain: (json['gain'] as num?)?.toDouble() ?? 1.0,
      offset: (json['offset'] as num?)?.toDouble() ?? 0.0,
      mode: _enumByName(
        NleSecondaryCorrectionMode.values,
        json['mode'],
        NleSecondaryCorrectionMode.primary,
      ),
    );
  }

  NleSecondaryCorrection copyWith({
    bool? enabled,
    double? intensity,
    double? exposure,
    double? contrast,
    double? saturation,
    double? temperature,
    double? tint,
    double? lift,
    double? gamma,
    double? gain,
    double? offset,
    NleSecondaryCorrectionMode? mode,
  }) {
    return NleSecondaryCorrection(
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      temperature: temperature ?? this.temperature,
      tint: tint ?? this.tint,
      lift: lift ?? this.lift,
      gamma: gamma ?? this.gamma,
      gain: gain ?? this.gain,
      offset: offset ?? this.offset,
      mode: mode ?? this.mode,
    );
  }
}

class NleSecondaryGradeLayer {
  final String id;
  final String name;
  final bool enabled;
  final NleHslQualifier qualifier;
  final NleSecondaryCorrection correction;

  const NleSecondaryGradeLayer({
    required this.id,
    required this.name,
    required this.enabled,
    required this.qualifier,
    required this.correction,
  });

  bool get isIdentity {
    return !enabled || (qualifier.isIdentity && correction.isIdentity);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'qualifier': qualifier.toJson(),
      'correction': correction.toJson(),
    };
  }

  factory NleSecondaryGradeLayer.fromJson(Map<String, dynamic> json) {
    return NleSecondaryGradeLayer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Secondary',
      enabled: json['enabled'] != false,
      qualifier: NleHslQualifier.fromJson(
        Map<String, dynamic>.from(json['qualifier'] as Map? ?? const {}),
      ),
      correction: NleSecondaryCorrection.fromJson(
        Map<String, dynamic>.from(json['correction'] as Map? ?? const {}),
      ),
    );
  }

  NleSecondaryGradeLayer copyWith({
    String? name,
    bool? enabled,
    NleHslQualifier? qualifier,
    NleSecondaryCorrection? correction,
  }) {
    return NleSecondaryGradeLayer(
      id: id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      qualifier: qualifier ?? this.qualifier,
      correction: correction ?? this.correction,
    );
  }
}

class NleSecondaryGradeStack {
  final bool enabled;
  final List<NleSecondaryGradeLayer> layers;

  const NleSecondaryGradeStack({
    required this.enabled,
    required this.layers,
  });

  const NleSecondaryGradeStack.empty()
      : enabled = true,
        layers = const [];

  bool get isIdentity {
    return !enabled || layers.every((layer) => layer.isIdentity);
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'layers': layers.map((layer) => layer.toJson()).toList(),
    };
  }

  factory NleSecondaryGradeStack.fromJson(Map<String, dynamic> json) {
    return NleSecondaryGradeStack(
      enabled: json['enabled'] != false,
      layers: (json['layers'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => NleSecondaryGradeLayer.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }

  NleSecondaryGradeStack copyWith({
    bool? enabled,
    List<NleSecondaryGradeLayer>? layers,
  }) {
    return NleSecondaryGradeStack(
      enabled: enabled ?? this.enabled,
      layers: layers ?? this.layers,
    );
  }

  NleSecondaryGradeStack updateLayer(NleSecondaryGradeLayer nextLayer) {
    final next = <NleSecondaryGradeLayer>[];
    var replaced = false;

    for (final layer in layers) {
      if (layer.id == nextLayer.id) {
        next.add(nextLayer);
        replaced = true;
      } else {
        next.add(layer);
      }
    }

    if (!replaced) {
      next.add(nextLayer);
    }

    return copyWith(layers: next);
  }

  NleSecondaryGradeStack removeLayer(String id) {
    return copyWith(
      layers: layers.where((layer) => layer.id != id).toList(),
    );
  }
}

class NlePickedHslSample {
  final double hue;
  final double saturation;
  final double luminance;
  final double red;
  final double green;
  final double blue;

  const NlePickedHslSample({
    required this.hue,
    required this.saturation,
    required this.luminance,
    required this.red,
    required this.green,
    required this.blue,
  });

  factory NlePickedHslSample.fromJson(Map<String, dynamic> json) {
    return NlePickedHslSample(
      hue: (json['hue'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
      luminance: (json['luminance'] as num?)?.toDouble() ?? 0.0,
      red: (json['red'] as num?)?.toDouble() ?? 0.0,
      green: (json['green'] as num?)?.toDouble() ?? 0.0,
      blue: (json['blue'] as num?)?.toDouble() ?? 0.0,
    );
  }
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
