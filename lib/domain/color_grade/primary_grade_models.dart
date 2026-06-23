enum NlePrimaryGradeMode {
  linear,
  log,
}

class NleRgbVector {
  final double r;
  final double g;
  final double b;

  const NleRgbVector({
    required this.r,
    required this.g,
    required this.b,
  });

  const NleRgbVector.zero()
      : r = 0.0,
        g = 0.0,
        b = 0.0;

  const NleRgbVector.one()
      : r = 1.0,
        g = 1.0,
        b = 1.0;

  Map<String, dynamic> toJson() {
    return {
      'r': r,
      'g': g,
      'b': b,
    };
  }

  factory NleRgbVector.fromJson(Map<String, dynamic> json) {
    return NleRgbVector(
      r: (json['r'] as num?)?.toDouble() ?? 0.0,
      g: (json['g'] as num?)?.toDouble() ?? 0.0,
      b: (json['b'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleRgbVector copyWith({
    double? r,
    double? g,
    double? b,
  }) {
    return NleRgbVector(
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
    );
  }

  NleRgbVector clamp(double min, double max) {
    return NleRgbVector(
      r: r.clamp(min, max),
      g: g.clamp(min, max),
      b: b.clamp(min, max),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NleRgbVector &&
          runtimeType == other.runtimeType &&
          r == other.r &&
          g == other.g &&
          b == other.b;

  @override
  int get hashCode => r.hashCode ^ g.hashCode ^ b.hashCode;
}

class NlePrimaryWheelControl {
  final double master;
  final NleRgbVector rgb;

  const NlePrimaryWheelControl({
    required this.master,
    required this.rgb,
  });

  const NlePrimaryWheelControl.zero()
      : master = 0.0,
        rgb = const NleRgbVector.zero();

  const NlePrimaryWheelControl.one()
      : master = 1.0,
        rgb = const NleRgbVector.one();

  Map<String, dynamic> toJson() {
    return {
      'master': master,
      'rgb': rgb.toJson(),
    };
  }

  factory NlePrimaryWheelControl.fromJson(
    Map<String, dynamic> json, {
    required double defaultMaster,
    required NleRgbVector defaultRgb,
  }) {
    return NlePrimaryWheelControl(
      master: (json['master'] as num?)?.toDouble() ?? defaultMaster,
      rgb: json['rgb'] is Map
          ? NleRgbVector.fromJson(
              Map<String, dynamic>.from(json['rgb'] as Map),
            )
          : defaultRgb,
    );
  }

  NlePrimaryWheelControl copyWith({
    double? master,
    NleRgbVector? rgb,
  }) {
    return NlePrimaryWheelControl(
      master: master ?? this.master,
      rgb: rgb ?? this.rgb,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NlePrimaryWheelControl &&
          runtimeType == other.runtimeType &&
          master == other.master &&
          rgb == other.rgb;

  @override
  int get hashCode => master.hashCode ^ rgb.hashCode;
}

class NlePrimaryGrade {
  final bool enabled;
  final NlePrimaryGradeMode mode;
  final double intensity;

  final NlePrimaryWheelControl lift;
  final NlePrimaryWheelControl gamma;
  final NlePrimaryWheelControl gain;
  final NlePrimaryWheelControl offset;

  final double contrast;
  final double pivot;
  final double saturation;

  const NlePrimaryGrade({
    required this.enabled,
    required this.mode,
    required this.intensity,
    required this.lift,
    required this.gamma,
    required this.gain,
    required this.offset,
    required this.contrast,
    required this.pivot,
    required this.saturation,
  });

  const NlePrimaryGrade.identity()
      : enabled = true,
        mode = NlePrimaryGradeMode.linear,
        intensity = 1.0,
        lift = const NlePrimaryWheelControl.zero(),
        gamma = const NlePrimaryWheelControl.one(),
        gain = const NlePrimaryWheelControl.one(),
        offset = const NlePrimaryWheelControl.zero(),
        contrast = 1.0,
        pivot = 0.18,
        saturation = 1.0;

  bool get isIdentity {
    return enabled &&
        intensity == 1.0 &&
        mode == NlePrimaryGradeMode.linear &&
        lift.master == 0.0 &&
        lift.rgb.r == 0.0 &&
        lift.rgb.g == 0.0 &&
        lift.rgb.b == 0.0 &&
        gamma.master == 1.0 &&
        gamma.rgb.r == 1.0 &&
        gamma.rgb.g == 1.0 &&
        gamma.rgb.b == 1.0 &&
        gain.master == 1.0 &&
        gain.rgb.r == 1.0 &&
        gain.rgb.g == 1.0 &&
        gain.rgb.b == 1.0 &&
        offset.master == 0.0 &&
        offset.rgb.r == 0.0 &&
        offset.rgb.g == 0.0 &&
        offset.rgb.b == 0.0 &&
        contrast == 1.0 &&
        pivot == 0.18 &&
        saturation == 1.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'mode': mode.name,
      'intensity': intensity,
      'lift': lift.toJson(),
      'gamma': gamma.toJson(),
      'gain': gain.toJson(),
      'offset': offset.toJson(),
      'contrast': contrast,
      'pivot': pivot,
      'saturation': saturation,
    };
  }

  factory NlePrimaryGrade.fromJson(Map<String, dynamic> json) {
    return NlePrimaryGrade(
      enabled: json['enabled'] != false,
      mode: _enumByName(
        NlePrimaryGradeMode.values,
        json['mode'],
        NlePrimaryGradeMode.linear,
      ),
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
      lift: NlePrimaryWheelControl.fromJson(
        Map<String, dynamic>.from(json['lift'] as Map? ?? const {}),
        defaultMaster: 0.0,
        defaultRgb: const NleRgbVector.zero(),
      ),
      gamma: NlePrimaryWheelControl.fromJson(
        Map<String, dynamic>.from(json['gamma'] as Map? ?? const {}),
        defaultMaster: 1.0,
        defaultRgb: const NleRgbVector.one(),
      ),
      gain: NlePrimaryWheelControl.fromJson(
        Map<String, dynamic>.from(json['gain'] as Map? ?? const {}),
        defaultMaster: 1.0,
        defaultRgb: const NleRgbVector.one(),
      ),
      offset: NlePrimaryWheelControl.fromJson(
        Map<String, dynamic>.from(json['offset'] as Map? ?? const {}),
        defaultMaster: 0.0,
        defaultRgb: const NleRgbVector.zero(),
      ),
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      pivot: (json['pivot'] as num?)?.toDouble() ?? 0.18,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
    );
  }

  NlePrimaryGrade copyWith({
    bool? enabled,
    NlePrimaryGradeMode? mode,
    double? intensity,
    NlePrimaryWheelControl? lift,
    NlePrimaryWheelControl? gamma,
    NlePrimaryWheelControl? gain,
    NlePrimaryWheelControl? offset,
    double? contrast,
    double? pivot,
    double? saturation,
  }) {
    return NlePrimaryGrade(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      intensity: intensity ?? this.intensity,
      lift: lift ?? this.lift,
      gamma: gamma ?? this.gamma,
      gain: gain ?? this.gain,
      offset: offset ?? this.offset,
      contrast: contrast ?? this.contrast,
      pivot: pivot ?? this.pivot,
      saturation: saturation ?? this.saturation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NlePrimaryGrade &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          mode == other.mode &&
          intensity == other.intensity &&
          lift == other.lift &&
          gamma == other.gamma &&
          gain == other.gain &&
          offset == other.offset &&
          contrast == other.contrast &&
          pivot == other.pivot &&
          saturation == other.saturation;

  @override
  int get hashCode =>
      enabled.hashCode ^
      mode.hashCode ^
      intensity.hashCode ^
      lift.hashCode ^
      gamma.hashCode ^
      gain.hashCode ^
      offset.hashCode ^
      contrast.hashCode ^
      pivot.hashCode ^
      saturation.hashCode;
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
