class NleRgbaColor {
  final double r;
  final double g;
  final double b;
  final double a;

  const NleRgbaColor({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  const NleRgbaColor.white()
      : r = 1.0,
        g = 1.0,
        b = 1.0,
        a = 1.0;

  const NleRgbaColor.black()
      : r = 0.0,
        g = 0.0,
        b = 0.0,
        a = 1.0;

  const NleRgbaColor.transparent()
      : r = 0.0,
        g = 0.0,
        b = 0.0,
        a = 0.0;

  Map<String, dynamic> toJson() {
    return {
      'r': r,
      'g': g,
      'b': b,
      'a': a,
    };
  }

  factory NleRgbaColor.fromJson(Map<String, dynamic> json) {
    return NleRgbaColor(
      r: (json['r'] as num?)?.toDouble() ?? 1.0,
      g: (json['g'] as num?)?.toDouble() ?? 1.0,
      b: (json['b'] as num?)?.toDouble() ?? 1.0,
      a: (json['a'] as num?)?.toDouble() ?? 1.0,
    );
  }

  int toArgbInt() {
    final ai = (a.clamp(0.0, 1.0) * 255).round();
    final ri = (r.clamp(0.0, 1.0) * 255).round();
    final gi = (g.clamp(0.0, 1.0) * 255).round();
    final bi = (b.clamp(0.0, 1.0) * 255).round();

    return (ai << 24) | (ri << 16) | (gi << 8) | bi;
  }

  NleRgbaColor copyWith({
    double? r,
    double? g,
    double? b,
    double? a,
  }) {
    return NleRgbaColor(
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
      a: a ?? this.a,
    );
  }
}

class NleVec2 {
  final double x;
  final double y;

  const NleVec2({
    required this.x,
    required this.y,
  });

  const NleVec2.zero()
      : x = 0.0,
        y = 0.0;

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory NleVec2.fromJson(Map<String, dynamic> json) {
    return NleVec2(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleVec2 copyWith({
    double? x,
    double? y,
  }) {
    return NleVec2(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

class NleRectNorm {
  final double x;
  final double y;
  final double width;
  final double height;

  const NleRectNorm({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  const NleRectNorm.centerTitle()
      : x = 0.12,
        y = 0.35,
        width = 0.76,
        height = 0.30;

  const NleRectNorm.lowerThird()
      : x = 0.08,
        y = 0.68,
        width = 0.72,
        height = 0.18;

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  factory NleRectNorm.fromJson(Map<String, dynamic> json) {
    return NleRectNorm(
      x: (json['x'] as num?)?.toDouble() ?? 0.12,
      y: (json['y'] as num?)?.toDouble() ?? 0.35,
      width: (json['width'] as num?)?.toDouble() ?? 0.76,
      height: (json['height'] as num?)?.toDouble() ?? 0.30,
    );
  }

  NleRectNorm copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return NleRectNorm(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
