enum NleCurveType {
  rgbMaster,
  red,
  green,
  blue,
  luma,
  hueVsSat,
  hueVsHue,
  hueVsLum,
  lumVsSat,
  satVsSat,
}

enum NleCurveInterpolation {
  linear,
  smooth,
}

enum NleCurveEvaluationSpace {
  sceneLinear,
  displayReferred,
}

class NleCurvePoint {
  final double x;
  final double y;

  const NleCurvePoint({
    required this.x,
    required this.y,
  });

  const NleCurvePoint.zero()
      : x = 0.0,
        y = 0.0;

  const NleCurvePoint.one()
      : x = 1.0,
        y = 1.0;

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory NleCurvePoint.fromJson(Map<String, dynamic> json) {
    return NleCurvePoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleCurvePoint clamp({
    double minX = 0.0,
    double maxX = 1.0,
    double minY = 0.0,
    double maxY = 1.0,
  }) {
    return NleCurvePoint(
      x: x.clamp(minX, maxX),
      y: y.clamp(minY, maxY),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NleCurvePoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class NleColorCurve {
  final NleCurveType type;
  final bool enabled;
  final List<NleCurvePoint> points;
  final NleCurveInterpolation interpolation;
  final double intensity;

  const NleColorCurve({
    required this.type,
    required this.enabled,
    required this.points,
    this.interpolation = NleCurveInterpolation.smooth,
    this.intensity = 1.0,
  });

  factory NleColorCurve.identity(NleCurveType type) {
    return NleColorCurve(
      type: type,
      enabled: true,
      points: const [
        NleCurvePoint.zero(),
        NleCurvePoint.one(),
      ],
      interpolation: NleCurveInterpolation.smooth,
      intensity: 1.0,
    );
  }

  bool get isIdentity {
    if (!enabled) return true;
    if (points.length != 2) return false;

    final a = points[0];
    final b = points[1];

    return a.x == 0.0 &&
        a.y == 0.0 &&
        b.x == 1.0 &&
        b.y == 1.0 &&
        intensity == 1.0;
  }

  List<NleCurvePoint> get sortedPoints {
    final copy = [...points];
    copy.sort((a, b) => a.x.compareTo(b.x));
    return copy;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'enabled': enabled,
      'points': points.map((p) => p.toJson()).toList(),
      'interpolation': interpolation.name,
      'intensity': intensity,
    };
  }

  factory NleColorCurve.fromJson(Map<String, dynamic> json) {
    final type = _enumByName(
      NleCurveType.values,
      json['type'],
      NleCurveType.rgbMaster,
    );

    final points = (json['points'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => NleCurvePoint.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return NleColorCurve(
      type: type,
      enabled: json['enabled'] != false,
      points: points.isEmpty
          ? NleColorCurve.identity(type).points
          : points.map((p) => p.clamp()).toList(),
      interpolation: _enumByName(
        NleCurveInterpolation.values,
        json['interpolation'],
        NleCurveInterpolation.smooth,
      ),
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  NleColorCurve copyWith({
    bool? enabled,
    List<NleCurvePoint>? points,
    NleCurveInterpolation? interpolation,
    double? intensity,
  }) {
    return NleColorCurve(
      type: type,
      enabled: enabled ?? this.enabled,
      points: points ?? this.points,
      interpolation: interpolation ?? this.interpolation,
      intensity: intensity ?? this.intensity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NleColorCurve &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          enabled == other.enabled &&
          _listEquals(points, other.points) &&
          interpolation == other.interpolation &&
          intensity == other.intensity;

  @override
  int get hashCode =>
      type.hashCode ^
      enabled.hashCode ^
      points.hashCode ^
      interpolation.hashCode ^
      intensity.hashCode;
}

class NleColorCurveStack {
  final bool enabled;
  final NleCurveEvaluationSpace evaluationSpace;
  final List<NleColorCurve> curves;

  const NleColorCurveStack({
    required this.enabled,
    required this.evaluationSpace,
    required this.curves,
  });

  factory NleColorCurveStack.identity() {
    return NleColorCurveStack(
      enabled: true,
      evaluationSpace: NleCurveEvaluationSpace.sceneLinear,
      curves: NleCurveType.values
          .map((type) => NleColorCurve.identity(type))
          .toList(),
    );
  }

  bool get isIdentity {
    if (!enabled) return true;
    return curves.every((curve) => curve.isIdentity);
  }

  NleColorCurve curve(NleCurveType type) {
    return curves.firstWhere(
      (curve) => curve.type == type,
      orElse: () => NleColorCurve.identity(type),
    );
  }

  NleColorCurveStack updateCurve(NleColorCurve nextCurve) {
    final next = <NleColorCurve>[];

    var replaced = false;

    for (final curve in curves) {
      if (curve.type == nextCurve.type) {
        next.add(nextCurve);
        replaced = true;
      } else {
        next.add(curve);
      }
    }

    if (!replaced) {
      next.add(nextCurve);
    }

    return NleColorCurveStack(
      enabled: enabled,
      evaluationSpace: evaluationSpace,
      curves: next,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'evaluationSpace': evaluationSpace.name,
      'curves': curves.map((curve) => curve.toJson()).toList(),
    };
  }

  factory NleColorCurveStack.fromJson(Map<String, dynamic> json) {
    final parsed = (json['curves'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => NleColorCurve.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final byType = {
      for (final curve in parsed) curve.type: curve,
    };

    return NleColorCurveStack(
      enabled: json['enabled'] != false,
      evaluationSpace: _enumByName(
        NleCurveEvaluationSpace.values,
        json['evaluationSpace'],
        NleCurveEvaluationSpace.sceneLinear,
      ),
      curves: NleCurveType.values
          .map((type) => byType[type] ?? NleColorCurve.identity(type))
          .toList(),
    );
  }

  NleColorCurveStack copyWith({
    bool? enabled,
    NleCurveEvaluationSpace? evaluationSpace,
    List<NleColorCurve>? curves,
  }) {
    return NleColorCurveStack(
      enabled: enabled ?? this.enabled,
      evaluationSpace: evaluationSpace ?? this.evaluationSpace,
      curves: curves ?? this.curves,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NleColorCurveStack &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          evaluationSpace == other.evaluationSpace &&
          _listEquals(curves, other.curves);

  @override
  int get hashCode =>
      enabled.hashCode ^ evaluationSpace.hashCode ^ curves.hashCode;
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

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
