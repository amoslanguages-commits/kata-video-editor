import 'package:nle_editor/domain/overlays/overlay_value_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

class NleShapeStyle {
  final NleShapeType shapeType;
  final bool fillEnabled;
  final NleRgbaColor fillColor;
  final NleOverlayStrokeStyle stroke;
  final NleOverlayShadowStyle shadow;
  final double cornerRadius;
  final NleOverlayBlendMode blendMode;

  const NleShapeStyle({
    required this.shapeType,
    required this.fillEnabled,
    required this.fillColor,
    required this.stroke,
    required this.shadow,
    required this.cornerRadius,
    required this.blendMode,
  });

  const NleShapeStyle.defaultRect()
      : shapeType = NleShapeType.roundedRectangle,
        fillEnabled = true,
        fillColor = const NleRgbaColor(r: 1, g: 1, b: 1, a: 0.18),
        stroke = const NleOverlayStrokeStyle.white(),
        shadow = const NleOverlayShadowStyle.soft(),
        cornerRadius = 28.0,
        blendMode = NleOverlayBlendMode.normal;

  const NleShapeStyle.calloutBox()
      : shapeType = NleShapeType.roundedRectangle,
        fillEnabled = true,
        fillColor = const NleRgbaColor(r: 0, g: 0, b: 0, a: 0.55),
        stroke = const NleOverlayStrokeStyle(
          enabled: true,
          color: NleRgbaColor.white(),
          width: 3.0,
          cap: NleLineCap.round,
          join: NleLineJoin.round,
        ),
        shadow = const NleOverlayShadowStyle.soft(),
        cornerRadius = 20.0,
        blendMode = NleOverlayBlendMode.normal;

  Map<String, dynamic> toJson() {
    return {
      'shapeType': shapeType.name,
      'fillEnabled': fillEnabled,
      'fillColor': fillColor.toJson(),
      'stroke': stroke.toJson(),
      'shadow': shadow.toJson(),
      'cornerRadius': cornerRadius,
      'blendMode': blendMode.name,
    };
  }

  factory NleShapeStyle.fromJson(Map<String, dynamic> json) {
    return NleShapeStyle(
      shapeType: _enumByName(
        NleShapeType.values,
        json['shapeType'],
        NleShapeType.roundedRectangle,
      ),
      fillEnabled: json['fillEnabled'] != false,
      fillColor: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['fillColor'] as Map? ?? const {}),
      ),
      stroke: NleOverlayStrokeStyle.fromJson(
        Map<String, dynamic>.from(json['stroke'] as Map? ?? const {}),
      ),
      shadow: NleOverlayShadowStyle.fromJson(
        Map<String, dynamic>.from(json['shadow'] as Map? ?? const {}),
      ),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 28.0,
      blendMode: _enumByName(
        NleOverlayBlendMode.values,
        json['blendMode'],
        NleOverlayBlendMode.normal,
      ),
    );
  }

  NleShapeStyle copyWith({
    NleShapeType? shapeType,
    bool? fillEnabled,
    NleRgbaColor? fillColor,
    NleOverlayStrokeStyle? stroke,
    NleOverlayShadowStyle? shadow,
    double? cornerRadius,
    NleOverlayBlendMode? blendMode,
  }) {
    return NleShapeStyle(
      shapeType: shapeType ?? this.shapeType,
      fillEnabled: fillEnabled ?? this.fillEnabled,
      fillColor: fillColor ?? this.fillColor,
      stroke: stroke ?? this.stroke,
      shadow: shadow ?? this.shadow,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      blendMode: blendMode ?? this.blendMode,
    );
  }
}

class NleLineStyle {
  final NleRgbaColor color;
  final double width;
  final NleLineCap cap;
  final bool dashed;
  final double dashLength;
  final double gapLength;
  final bool arrowStart;
  final bool arrowEnd;
  final double arrowSize;
  final NleOverlayShadowStyle shadow;

  const NleLineStyle({
    required this.color,
    required this.width,
    required this.cap,
    required this.dashed,
    required this.dashLength,
    required this.gapLength,
    required this.arrowStart,
    required this.arrowEnd,
    required this.arrowSize,
    required this.shadow,
  });

  const NleLineStyle.defaultLine()
      : color = const NleRgbaColor.white(),
        width = 8.0,
        cap = NleLineCap.round,
        dashed = false,
        dashLength = 20.0,
        gapLength = 12.0,
        arrowStart = false,
        arrowEnd = false,
        arrowSize = 24.0,
        shadow = const NleOverlayShadowStyle.soft();

  const NleLineStyle.defaultArrow()
      : color = const NleRgbaColor.white(),
        width = 8.0,
        cap = NleLineCap.round,
        dashed = false,
        dashLength = 20.0,
        gapLength = 12.0,
        arrowStart = false,
        arrowEnd = true,
        arrowSize = 30.0,
        shadow = const NleOverlayShadowStyle.soft();

  Map<String, dynamic> toJson() {
    return {
      'color': color.toJson(),
      'width': width,
      'cap': cap.name,
      'dashed': dashed,
      'dashLength': dashLength,
      'gapLength': gapLength,
      'arrowStart': arrowStart,
      'arrowEnd': arrowEnd,
      'arrowSize': arrowSize,
      'shadow': shadow.toJson(),
    };
  }

  factory NleLineStyle.fromJson(Map<String, dynamic> json) {
    return NleLineStyle(
      color: NleRgbaColor.fromJson(
        Map<String, dynamic>.from(json['color'] as Map? ?? const {}),
      ),
      width: (json['width'] as num?)?.toDouble() ?? 8.0,
      cap: _enumByName(NleLineCap.values, json['cap'], NleLineCap.round),
      dashed: json['dashed'] == true,
      dashLength: (json['dashLength'] as num?)?.toDouble() ?? 20.0,
      gapLength: (json['gapLength'] as num?)?.toDouble() ?? 12.0,
      arrowStart: json['arrowStart'] == true,
      arrowEnd: json['arrowEnd'] == true,
      arrowSize: (json['arrowSize'] as num?)?.toDouble() ?? 30.0,
      shadow: NleOverlayShadowStyle.fromJson(
        Map<String, dynamic>.from(json['shadow'] as Map? ?? const {}),
      ),
    );
  }

  NleLineStyle copyWith({
    NleRgbaColor? color,
    double? width,
    NleLineCap? cap,
    bool? dashed,
    double? dashLength,
    double? gapLength,
    bool? arrowStart,
    bool? arrowEnd,
    double? arrowSize,
    NleOverlayShadowStyle? shadow,
  }) {
    return NleLineStyle(
      color: color ?? this.color,
      width: width ?? this.width,
      cap: cap ?? this.cap,
      dashed: dashed ?? this.dashed,
      dashLength: dashLength ?? this.dashLength,
      gapLength: gapLength ?? this.gapLength,
      arrowStart: arrowStart ?? this.arrowStart,
      arrowEnd: arrowEnd ?? this.arrowEnd,
      arrowSize: arrowSize ?? this.arrowSize,
      shadow: shadow ?? this.shadow,
    );
  }
}

class NleStickerStyle {
  final String? assetId;
  final String? localPath;
  final String? packageAssetPath;
  final String? svgText;
  final double opacity;
  final NleOverlayBlendMode blendMode;
  final NleOverlayShadowStyle shadow;
  final bool preserveAspectRatio;

  const NleStickerStyle({
    this.assetId,
    this.localPath,
    this.packageAssetPath,
    this.svgText,
    required this.opacity,
    required this.blendMode,
    required this.shadow,
    required this.preserveAspectRatio,
  });

  const NleStickerStyle.empty()
      : assetId = null,
        localPath = null,
        packageAssetPath = null,
        svgText = null,
        opacity = 1.0,
        blendMode = NleOverlayBlendMode.normal,
        shadow = const NleOverlayShadowStyle.none(),
        preserveAspectRatio = true;

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'localPath': localPath,
      'packageAssetPath': packageAssetPath,
      'svgText': svgText,
      'opacity': opacity,
      'blendMode': blendMode.name,
      'shadow': shadow.toJson(),
      'preserveAspectRatio': preserveAspectRatio,
    };
  }

  factory NleStickerStyle.fromJson(Map<String, dynamic> json) {
    return NleStickerStyle(
      assetId: json['assetId']?.toString(),
      localPath: json['localPath']?.toString(),
      packageAssetPath: json['packageAssetPath']?.toString(),
      svgText: json['svgText']?.toString(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode: _enumByName(
        NleOverlayBlendMode.values,
        json['blendMode'],
        NleOverlayBlendMode.normal,
      ),
      shadow: NleOverlayShadowStyle.fromJson(
        Map<String, dynamic>.from(json['shadow'] as Map? ?? const {}),
      ),
      preserveAspectRatio: json['preserveAspectRatio'] != false,
    );
  }

  NleStickerStyle copyWith({
    String? assetId,
    String? localPath,
    String? packageAssetPath,
    String? svgText,
    double? opacity,
    NleOverlayBlendMode? blendMode,
    NleOverlayShadowStyle? shadow,
    bool? preserveAspectRatio,
  }) {
    return NleStickerStyle(
      assetId: assetId ?? this.assetId,
      localPath: localPath ?? this.localPath,
      packageAssetPath: packageAssetPath ?? this.packageAssetPath,
      svgText: svgText ?? this.svgText,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      shadow: shadow ?? this.shadow,
      preserveAspectRatio: preserveAspectRatio ?? this.preserveAspectRatio,
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
