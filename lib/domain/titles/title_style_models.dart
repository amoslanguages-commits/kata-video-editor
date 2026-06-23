import 'package:nle_editor/domain/titles/title_value_models.dart';

enum NleTextClipKind {
  title,
  lowerThird,
  label,
  caption,
  motionGraphic,
}

enum NleTextHorizontalAlign {
  left,
  center,
  right,
}

enum NleTextVerticalAlign {
  top,
  center,
  bottom,
}

enum NleTextCaseTransform {
  none,
  uppercase,
  lowercase,
  titleCase,
}

enum NleTextAnchor {
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

enum NleTextBlendMode {
  normal,
  screen,
  multiply,
  overlay,
  add,
}

enum NleTitleTemplateId {
  basicTitle,
  cinematicCenter,
  lowerThirdClean,
  lowerThirdBold,
  socialHook,
  subtitleCard,
  nameTag,
  breakingNews,
}

class NleFontDescriptor {
  final String family;
  final String? assetPath;
  final int weight;
  final bool italic;

  const NleFontDescriptor({
    required this.family,
    this.assetPath,
    required this.weight,
    required this.italic,
  });

  const NleFontDescriptor.defaultSans()
      : family = 'Inter',
        assetPath = null,
        weight = 800,
        italic = false;

  Map<String, dynamic> toJson() {
    return {
      'family': family,
      'assetPath': assetPath,
      'weight': weight,
      'italic': italic,
    };
  }

  factory NleFontDescriptor.fromJson(Map<String, dynamic> json) {
    return NleFontDescriptor(
      family: json['family']?.toString() ?? 'Inter',
      assetPath: json['assetPath']?.toString(),
      weight: (json['weight'] as num?)?.toInt() ?? 800,
      italic: json['italic'] == true,
    );
  }

  NleFontDescriptor copyWith({
    String? family,
    String? assetPath,
    int? weight,
    bool? italic,
  }) {
    return NleFontDescriptor(
      family: family ?? this.family,
      assetPath: assetPath ?? this.assetPath,
      weight: weight ?? this.weight,
      italic: italic ?? this.italic,
    );
  }
}

class NleTextStrokeStyle {
  final bool enabled;
  final double width;
  final NleRgbaColor color;

  const NleTextStrokeStyle({
    required this.enabled,
    required this.width,
    required this.color,
  });

  const NleTextStrokeStyle.none()
      : enabled = false,
        width = 0.0,
        color = const NleRgbaColor.black();

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'width': width,
      'color': color.toJson(),
    };
  }

  factory NleTextStrokeStyle.fromJson(Map<String, dynamic> json) {
    return NleTextStrokeStyle(
      enabled: json['enabled'] == true,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      color: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['color'] as Map? ?? const {}),
      ),
    );
  }

  NleTextStrokeStyle copyWith({
    bool? enabled,
    double? width,
    NleRgbaColor? color,
  }) {
    return NleTextStrokeStyle(
      enabled: enabled ?? this.enabled,
      width: width ?? this.width,
      color: color ?? this.color,
    );
  }
}

class NleTextShadowStyle {
  final bool enabled;
  final NleRgbaColor color;
  final double blur;
  final double offsetX;
  final double offsetY;

  const NleTextShadowStyle({
    required this.enabled,
    required this.color,
    required this.blur,
    required this.offsetX,
    required this.offsetY,
  });

  const NleTextShadowStyle.none()
      : enabled = false,
        color = const NleRgbaColor.black(),
        blur = 0.0,
        offsetX = 0.0,
        offsetY = 0.0;

  const NleTextShadowStyle.soft()
      : enabled = true,
        color = const NleRgbaColor(r: 0, g: 0, b: 0, a: 0.55),
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

  factory NleTextShadowStyle.fromJson(Map<String, dynamic> json) {
    return NleTextShadowStyle(
      enabled: json['enabled'] == true,
      color: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['color'] as Map? ?? const {}),
      ),
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleTextShadowStyle copyWith({
    bool? enabled,
    NleRgbaColor? color,
    double? blur,
    double? offsetX,
    double? offsetY,
  }) {
    return NleTextShadowStyle(
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      blur: blur ?? this.blur,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }
}

class NleTextBackgroundStyle {
  final bool enabled;
  final NleRgbaColor color;
  final double radius;
  final double paddingX;
  final double paddingY;

  const NleTextBackgroundStyle({
    required this.enabled,
    required this.color,
    required this.radius,
    required this.paddingX,
    required this.paddingY,
  });

  const NleTextBackgroundStyle.none()
      : enabled = false,
        color = const NleRgbaColor.transparent(),
        radius = 0.0,
        paddingX = 0.0,
        paddingY = 0.0;

  const NleTextBackgroundStyle.darkPill()
      : enabled = true,
        color = const NleRgbaColor(r: 0, g: 0, b: 0, a: 0.60),
        radius = 24.0,
        paddingX = 28.0,
        paddingY = 14.0;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'color': color.toJson(),
      'radius': radius,
      'paddingX': paddingX,
      'paddingY': paddingY,
    };
  }

  factory NleTextBackgroundStyle.fromJson(Map<String, dynamic> json) {
    return NleTextBackgroundStyle(
      enabled: json['enabled'] == true,
      color: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['color'] as Map? ?? const {}),
      ),
      radius: (json['radius'] as num?)?.toDouble() ?? 0.0,
      paddingX: (json['paddingX'] as num?)?.toDouble() ?? 0.0,
      paddingY: (json['paddingY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleTextBackgroundStyle copyWith({
    bool? enabled,
    NleRgbaColor? color,
    double? radius,
    double? paddingX,
    double? paddingY,
  }) {
    return NleTextBackgroundStyle(
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      radius: radius ?? this.radius,
      paddingX: paddingX ?? this.paddingX,
      paddingY: paddingY ?? this.paddingY,
    );
  }
}

class NleTextGradientStyle {
  final bool enabled;
  final NleRgbaColor startColor;
  final NleRgbaColor endColor;
  final double angleDegrees;

  const NleTextGradientStyle({
    required this.enabled,
    required this.startColor,
    required this.endColor,
    required this.angleDegrees,
  });

  const NleTextGradientStyle.none()
      : enabled = false,
        startColor = const NleRgbaColor.white(),
        endColor = const NleRgbaColor.white(),
        angleDegrees = 0.0;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'startColor': startColor.toJson(),
      'endColor': endColor.toJson(),
      'angleDegrees': angleDegrees,
    };
  }

  factory NleTextGradientStyle.fromJson(Map<String, dynamic> json) {
    return NleTextGradientStyle(
      enabled: json['enabled'] == true,
      startColor: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['startColor'] as Map? ?? const {}),
      ),
      endColor: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['endColor'] as Map? ?? const {}),
      ),
      angleDegrees: (json['angleDegrees'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleTextGradientStyle copyWith({
    bool? enabled,
    NleRgbaColor? startColor,
    NleRgbaColor? endColor,
    double? angleDegrees,
  }) {
    return NleTextGradientStyle(
      enabled: enabled ?? this.enabled,
      startColor: startColor ?? this.startColor,
      endColor: endColor ?? this.endColor,
      angleDegrees: angleDegrees ?? this.angleDegrees,
    );
  }
}

class NleTextStyleModel {
  final NleFontDescriptor font;
  final double fontSize;
  final NleRgbaColor fillColor;
  final double opacity;

  final double letterSpacing;
  final double lineHeight;
  final NleTextCaseTransform caseTransform;

  final NleTextStrokeStyle stroke;
  final NleTextShadowStyle shadow;
  final NleTextBackgroundStyle background;
  final NleTextGradientStyle gradient;

  final NleTextBlendMode blendMode;

  const NleTextStyleModel({
    required this.font,
    required this.fontSize,
    required this.fillColor,
    required this.opacity,
    required this.letterSpacing,
    required this.lineHeight,
    required this.caseTransform,
    required this.stroke,
    required this.shadow,
    required this.background,
    required this.gradient,
    required this.blendMode,
  });

  const NleTextStyleModel.defaultTitle()
      : font = const NleFontDescriptor.defaultSans(),
        fontSize = 72.0,
        fillColor = const NleRgbaColor.white(),
        opacity = 1.0,
        letterSpacing = 0.0,
        lineHeight = 1.05,
        caseTransform = NleTextCaseTransform.none,
        stroke = const NleTextStrokeStyle.none(),
        shadow = const NleTextShadowStyle.soft(),
        background = const NleTextBackgroundStyle.none(),
        gradient = const NleTextGradientStyle.none(),
        blendMode = NleTextBlendMode.normal;

  Map<String, dynamic> toJson() {
    return {
      'font': font.toJson(),
      'fontSize': fontSize,
      'fillColor': fillColor.toJson(),
      'opacity': opacity,
      'letterSpacing': letterSpacing,
      'lineHeight': lineHeight,
      'caseTransform': caseTransform.name,
      'stroke': stroke.toJson(),
      'shadow': shadow.toJson(),
      'background': background.toJson(),
      'gradient': gradient.toJson(),
      'blendMode': blendMode.name,
    };
  }

  factory NleTextStyleModel.fromJson(Map<String, dynamic> json) {
    return NleTextStyleModel(
      font: NleFontDescriptor.fromJson(
        Map<String, dynamic>.from(json['font'] as Map? ?? const {}),
      ),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 72.0,
      fillColor: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['fillColor'] as Map? ?? const {}),
      ),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.05,
      caseTransform: _enumByName(
        NleTextCaseTransform.values,
        json['caseTransform'],
        NleTextCaseTransform.none,
      ),
      stroke: NleTextStrokeStyle.fromJson(
        Map<String, dynamic>.from(json['stroke'] as Map? ?? const {}),
      ),
      shadow: NleTextShadowStyle.fromJson(
        Map<String, dynamic>.from(json['shadow'] as Map? ?? const {}),
      ),
      background: NleTextBackgroundStyle.fromJson(
        Map<String, dynamic>.from(json['background'] as Map? ?? const {}),
      ),
      gradient: NleTextGradientStyle.fromJson(
        Map<String, dynamic>.from(json['gradient'] as Map? ?? const {}),
      ),
      blendMode: _enumByName(
        NleTextBlendMode.values,
        json['blendMode'],
        NleTextBlendMode.normal,
      ),
    );
  }

  NleTextStyleModel copyWith({
    NleFontDescriptor? font,
    double? fontSize,
    NleRgbaColor? fillColor,
    double? opacity,
    double? letterSpacing,
    double? lineHeight,
    NleTextCaseTransform? caseTransform,
    NleTextStrokeStyle? stroke,
    NleTextShadowStyle? shadow,
    NleTextBackgroundStyle? background,
    NleTextGradientStyle? gradient,
    NleTextBlendMode? blendMode,
  }) {
    return NleTextStyleModel(
      font: font ?? this.font,
      fontSize: fontSize ?? this.fontSize,
      fillColor: fillColor ?? this.fillColor,
      opacity: opacity ?? this.opacity,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      caseTransform: caseTransform ?? this.caseTransform,
      stroke: stroke ?? this.stroke,
      shadow: shadow ?? this.shadow,
      background: background ?? this.background,
      gradient: gradient ?? this.gradient,
      blendMode: blendMode ?? this.blendMode,
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
