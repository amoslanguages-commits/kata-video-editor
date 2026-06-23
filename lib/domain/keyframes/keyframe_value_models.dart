enum NleKeyframeOwnerType {
  clip,
  title,
  overlay,
  effect,
  colorNode,
  audioClip,
  audioTrack,
  project,
}

enum NleKeyframeValueType {
  number,
  boolean,
  color,
  vec2,
}

enum NleKeyframeInterpolation {
  hold,
  linear,
  bezier,
  easeIn,
  easeOut,
  easeInOut,
  spring,
}

enum NleKeyframePropertyGroup {
  transform,
  visual,
  text,
  shape,
  effect,
  audio,
  color,
}

enum NleKeyframeSnapTarget {
  none,
  playhead,
  clipStart,
  clipEnd,
  nearestFrame,
  neighboringKeyframe,
}

class NleKeyframeColorValue {
  final double r;
  final double g;
  final double b;
  final double a;

  const NleKeyframeColorValue({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  Map<String, dynamic> toJson() {
    return {
      'r': r,
      'g': g,
      'b': b,
      'a': a,
    };
  }

  factory NleKeyframeColorValue.fromJson(Map<String, dynamic> json) {
    return NleKeyframeColorValue(
      r: (json['r'] as num?)?.toDouble() ?? 1.0,
      g: (json['g'] as num?)?.toDouble() ?? 1.0,
      b: (json['b'] as num?)?.toDouble() ?? 1.0,
      a: (json['a'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class NleKeyframeVec2Value {
  final double x;
  final double y;

  const NleKeyframeVec2Value({
    required this.x,
    required this.y,
  });

  const NleKeyframeVec2Value.zero()
      : x = 0.0,
        y = 0.0;

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory NleKeyframeVec2Value.fromJson(Map<String, dynamic> json) {
    return NleKeyframeVec2Value(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NleKeyframeValue {
  final NleKeyframeValueType type;
  final Object? value;

  const NleKeyframeValue({
    required this.type,
    required this.value,
  });

  const NleKeyframeValue.number(double value)
      : type = NleKeyframeValueType.number,
        value = value;

  const NleKeyframeValue.boolean(bool value)
      : type = NleKeyframeValueType.boolean,
        value = value;

  const NleKeyframeValue.vec2(NleKeyframeVec2Value value)
      : type = NleKeyframeValueType.vec2,
        value = value;

  const NleKeyframeValue.color(NleKeyframeColorValue value)
      : type = NleKeyframeValueType.color,
        value = value;

  double get numberOrZero {
    final raw = value;
    return raw is num ? raw.toDouble() : 0.0;
  }

  bool get boolOrFalse {
    final raw = value;
    return raw == true;
  }

  NleKeyframeVec2Value get vec2OrZero {
    final raw = value;
    return raw is NleKeyframeVec2Value
        ? raw
        : const NleKeyframeVec2Value.zero();
  }

  Map<String, dynamic> toJson() {
    Object? encoded = value;

    if (value is NleKeyframeVec2Value) {
      encoded = (value as NleKeyframeVec2Value).toJson();
    }

    if (value is NleKeyframeColorValue) {
      encoded = (value as NleKeyframeColorValue).toJson();
    }

    return {
      'type': type.name,
      'value': encoded,
    };
  }

  factory NleKeyframeValue.fromJson(Map<String, dynamic> json) {
    final type = _enumByName(
      NleKeyframeValueType.values,
      json['type'],
      NleKeyframeValueType.number,
    );

    final raw = json['value'];

    switch (type) {
      case NleKeyframeValueType.number:
        return NleKeyframeValue.number((raw as num?)?.toDouble() ?? 0.0);

      case NleKeyframeValueType.boolean:
        return NleKeyframeValue.boolean(raw == true);

      case NleKeyframeValueType.vec2:
        return NleKeyframeValue.vec2(
          NleKeyframeVec2Value.fromJson(
            Map<String, dynamic>.from(raw as Map? ?? const {}),
          ),
        );

      case NleKeyframeValueType.color:
        return NleKeyframeValue.color(
          NleKeyframeColorValue.fromJson(
            Map<String, dynamic>.from(raw as Map? ?? const {}),
          ),
        );
    }
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
