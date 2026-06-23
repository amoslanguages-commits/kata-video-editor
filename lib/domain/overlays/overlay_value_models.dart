import 'package:nle_editor/domain/titles/title_value_models.dart';

enum NleOverlayClipKind {
  shape,
  line,
  arrow,
  sticker,
  pngOverlay,
  svgOverlay,
  callout,
}

enum NleShapeType {
  rectangle,
  roundedRectangle,
  ellipse,
  circle,
  pill,
  triangle,
  diamond,
}

enum NleLineCap {
  butt,
  round,
  square,
}

enum NleLineJoin {
  miter,
  round,
  bevel,
}

enum NleOverlayBlendMode {
  normal,
  multiply,
  screen,
  overlay,
  add,
  subtract,
}

enum NleOverlayAnchor {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

enum NleOverlayAnimationPreset {
  none,
  fadeIn,
  fadeUp,
  pop,
  slideLeft,
  slideRight,
  pulse,
  bounce,
  drawLine,
}

class NleOverlayShadowStyle {
  final bool enabled;
  final NleRgbaColor color;
  final double blur;
  final double offsetX;
  final double offsetY;

  const NleOverlayShadowStyle({
    required this.enabled,
    required this.color,
    required this.blur,
    required this.offsetX,
    required this.offsetY,
  });

  const NleOverlayShadowStyle.none()
      : enabled = false,
        color = const NleRgbaColor.black(),
        blur = 0.0,
        offsetX = 0.0,
        offsetY = 0.0;

  const NleOverlayShadowStyle.soft()
      : enabled = true,
        color = const NleRgbaColor(r: 0, g: 0, b: 0, a: 0.45),
        blur = 18.0,
        offsetX = 0.0,
        offsetY = 6.0;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'color': color.toJson(),
      'blur': blur,
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }

  factory NleOverlayShadowStyle.fromJson(Map<String, dynamic> json) {
    return NleOverlayShadowStyle(
      enabled: json['enabled'] == true,
      color: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['color'] as Map? ?? const {}),
      ),
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleOverlayShadowStyle copyWith({
    bool? enabled,
    NleRgbaColor? color,
    double? blur,
    double? offsetX,
    double? offsetY,
  }) {
    return NleOverlayShadowStyle(
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      blur: blur ?? this.blur,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }
}

class NleOverlayStrokeStyle {
  final bool enabled;
  final NleRgbaColor color;
  final double width;
  final NleLineCap cap;
  final NleLineJoin join;

  const NleOverlayStrokeStyle({
    required this.enabled,
    required this.color,
    required this.width,
    required this.cap,
    required this.join,
  });

  const NleOverlayStrokeStyle.none()
      : enabled = false,
        color = const NleRgbaColor.white(),
        width = 0.0,
        cap = NleLineCap.round,
        join = NleLineJoin.round;

  const NleOverlayStrokeStyle.white()
      : enabled = true,
        color = const NleRgbaColor.white(),
        width = 6.0,
        cap = NleLineCap.round,
        join = NleLineJoin.round;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'color': color.toJson(),
      'width': width,
      'cap': cap.name,
      'join': join.name,
    };
  }

  factory NleOverlayStrokeStyle.fromJson(Map<String, dynamic> json) {
    return NleOverlayStrokeStyle(
      enabled: json['enabled'] == true,
      color: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['color'] as Map? ?? const {}),
      ),
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      cap: _enumByName(NleLineCap.values, json['cap'], NleLineCap.round),
      join: _enumByName(NleLineJoin.values, json['join'], NleLineJoin.round),
    );
  }

  NleOverlayStrokeStyle copyWith({
    bool? enabled,
    NleRgbaColor? color,
    double? width,
    NleLineCap? cap,
    NleLineJoin? join,
  }) {
    return NleOverlayStrokeStyle(
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      width: width ?? this.width,
      cap: cap ?? this.cap,
      join: join ?? this.join,
    );
  }
}

class NleOverlayTransform {
  final NleRectNorm box;
  final NleOverlayAnchor anchor;
  final double rotationDegrees;
  final double scale;
  final double opacity;
  final bool respectSafeArea;

  const NleOverlayTransform({
    required this.box,
    required this.anchor,
    required this.rotationDegrees,
    required this.scale,
    required this.opacity,
    required this.respectSafeArea,
  });

  const NleOverlayTransform.center()
      : box = const NleRectNorm(
          x: 0.35,
          y: 0.35,
          width: 0.30,
          height: 0.30,
        ),
        anchor = NleOverlayAnchor.center,
        rotationDegrees = 0.0,
        scale = 1.0,
        opacity = 1.0,
        respectSafeArea = true;

  const NleOverlayTransform.lowerThird()
      : box = const NleRectNorm(
          x: 0.08,
          y: 0.68,
          width: 0.72,
          height: 0.16,
        ),
        anchor = NleOverlayAnchor.centerLeft,
        rotationDegrees = 0.0,
        scale = 1.0,
        opacity = 1.0,
        respectSafeArea = true;

  Map<String, dynamic> toJson() {
    return {
      'box': box.toJson(),
      'anchor': anchor.name,
      'rotationDegrees': rotationDegrees,
      'scale': scale,
      'opacity': opacity,
      'respectSafeArea': respectSafeArea,
    };
  }

  factory NleOverlayTransform.fromJson(Map<String, dynamic> json) {
    return NleOverlayTransform(
      box: NleRectNorm.fromJson(
        Map<String, dynamic>.from(json['box'] as Map? ?? const {}),
      ),
      anchor: _enumByName(
        NleOverlayAnchor.values,
        json['anchor'],
        NleOverlayAnchor.center,
      ),
      rotationDegrees: (json['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      respectSafeArea: json['respectSafeArea'] != false,
    );
  }

  NleOverlayTransform copyWith({
    NleRectNorm? box,
    NleOverlayAnchor? anchor,
    double? rotationDegrees,
    double? scale,
    double? opacity,
    bool? respectSafeArea,
  }) {
    return NleOverlayTransform(
      box: box ?? this.box,
      anchor: anchor ?? this.anchor,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      respectSafeArea: respectSafeArea ?? this.respectSafeArea,
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
