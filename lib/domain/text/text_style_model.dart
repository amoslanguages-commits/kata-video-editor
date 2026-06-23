import 'dart:convert';

class TextAlignmentOption {
  TextAlignmentOption._();

  static const String left = 'left';
  static const String center = 'center';
  static const String right = 'right';
}

class TextAnimationType {
  TextAnimationType._();

  static const String none = 'none';
  static const String fade = 'fade';
  static const String pop = 'pop';
  static const String slideUp = 'slide_up';
  static const String typewriter = 'typewriter';
  static const String karaoke = 'karaoke';
}

class NleTextStyle {
  final String fontFamily;
  final double fontSize;
  final int fontWeight;

  final String color;
  final String strokeColor;
  final double strokeWidth;

  final bool shadowEnabled;
  final String shadowColor;
  final double shadowBlur;
  final double shadowOffsetX;
  final double shadowOffsetY;

  final bool backgroundEnabled;
  final String backgroundColor;
  final double backgroundOpacity;
  final double backgroundRadius;
  final double backgroundPadding;

  final String alignment;
  final double lineSpacing;
  final double letterSpacing;

  final String animation;
  final double animationIntensity;

  const NleTextStyle({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    required this.strokeColor,
    required this.strokeWidth,
    required this.shadowEnabled,
    required this.shadowColor,
    required this.shadowBlur,
    required this.shadowOffsetX,
    required this.shadowOffsetY,
    required this.backgroundEnabled,
    required this.backgroundColor,
    required this.backgroundOpacity,
    required this.backgroundRadius,
    required this.backgroundPadding,
    required this.alignment,
    required this.lineSpacing,
    required this.letterSpacing,
    required this.animation,
    required this.animationIntensity,
  });

  factory NleTextStyle.defaults() {
    return const NleTextStyle(
      fontFamily: 'system',
      fontSize: 36,
      fontWeight: 800,
      color: '#FFFFFF',
      strokeColor: '#000000',
      strokeWidth: 0,
      shadowEnabled: true,
      shadowColor: '#000000',
      shadowBlur: 8,
      shadowOffsetX: 0,
      shadowOffsetY: 2,
      backgroundEnabled: false,
      backgroundColor: '#000000',
      backgroundOpacity: 0.55,
      backgroundRadius: 12,
      backgroundPadding: 8,
      alignment: TextAlignmentOption.center,
      lineSpacing: 1.0,
      letterSpacing: 0,
      animation: TextAnimationType.none,
      animationIntensity: 1.0,
    );
  }

  NleTextStyle copyWith({
    String? fontFamily,
    double? fontSize,
    int? fontWeight,
    String? color,
    String? strokeColor,
    double? strokeWidth,
    bool? shadowEnabled,
    String? shadowColor,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
    bool? backgroundEnabled,
    String? backgroundColor,
    double? backgroundOpacity,
    double? backgroundRadius,
    double? backgroundPadding,
    String? alignment,
    double? lineSpacing,
    double? letterSpacing,
    String? animation,
    double? animationIntensity,
  }) {
    return NleTextStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      color: color ?? this.color,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      shadowEnabled: shadowEnabled ?? this.shadowEnabled,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundRadius: backgroundRadius ?? this.backgroundRadius,
      backgroundPadding: backgroundPadding ?? this.backgroundPadding,
      alignment: alignment ?? this.alignment,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      animation: animation ?? this.animation,
      animationIntensity: animationIntensity ?? this.animationIntensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight,
      'color': color,
      'strokeColor': strokeColor,
      'strokeWidth': strokeWidth,
      'shadowEnabled': shadowEnabled,
      'shadowColor': shadowColor,
      'shadowBlur': shadowBlur,
      'shadowOffsetX': shadowOffsetX,
      'shadowOffsetY': shadowOffsetY,
      'backgroundEnabled': backgroundEnabled,
      'backgroundColor': backgroundColor,
      'backgroundOpacity': backgroundOpacity,
      'backgroundRadius': backgroundRadius,
      'backgroundPadding': backgroundPadding,
      'alignment': alignment,
      'lineSpacing': lineSpacing,
      'letterSpacing': letterSpacing,
      'animation': animation,
      'animationIntensity': animationIntensity,
    };
  }

  factory NleTextStyle.fromJson(Map<String, dynamic> json) {
    final defaults = NleTextStyle.defaults();

    return NleTextStyle(
      fontFamily: json['fontFamily'] as String? ?? defaults.fontFamily,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaults.fontSize,
      fontWeight: (json['fontWeight'] as num?)?.round() ?? defaults.fontWeight,
      color: json['color'] as String? ?? defaults.color,
      strokeColor: json['strokeColor'] as String? ?? defaults.strokeColor,
      strokeWidth:
          (json['strokeWidth'] as num?)?.toDouble() ?? defaults.strokeWidth,
      shadowEnabled:
          json['shadowEnabled'] as bool? ?? defaults.shadowEnabled,
      shadowColor: json['shadowColor'] as String? ?? defaults.shadowColor,
      shadowBlur:
          (json['shadowBlur'] as num?)?.toDouble() ?? defaults.shadowBlur,
      shadowOffsetX:
          (json['shadowOffsetX'] as num?)?.toDouble() ?? defaults.shadowOffsetX,
      shadowOffsetY:
          (json['shadowOffsetY'] as num?)?.toDouble() ?? defaults.shadowOffsetY,
      backgroundEnabled:
          json['backgroundEnabled'] as bool? ?? defaults.backgroundEnabled,
      backgroundColor:
          json['backgroundColor'] as String? ?? defaults.backgroundColor,
      backgroundOpacity:
          (json['backgroundOpacity'] as num?)?.toDouble() ??
              defaults.backgroundOpacity,
      backgroundRadius:
          (json['backgroundRadius'] as num?)?.toDouble() ??
              defaults.backgroundRadius,
      backgroundPadding:
          (json['backgroundPadding'] as num?)?.toDouble() ??
              defaults.backgroundPadding,
      alignment: json['alignment'] as String? ?? defaults.alignment,
      lineSpacing:
          (json['lineSpacing'] as num?)?.toDouble() ?? defaults.lineSpacing,
      letterSpacing:
          (json['letterSpacing'] as num?)?.toDouble() ?? defaults.letterSpacing,
      animation: json['animation'] as String? ?? defaults.animation,
      animationIntensity:
          (json['animationIntensity'] as num?)?.toDouble() ??
              defaults.animationIntensity,
    );
  }

  factory NleTextStyle.fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return NleTextStyle.defaults();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return NleTextStyle.fromJson(decoded);
      }
    } catch (_) {}

    return NleTextStyle.defaults();
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class TextStylePreset {
  final String id;
  final String name;
  final String category;
  final bool isPremium;
  final bool isBuiltIn;
  final NleTextStyle style;

  const TextStylePreset({
    required this.id,
    required this.name,
    required this.category,
    required this.isPremium,
    required this.isBuiltIn,
    required this.style,
  });
}
