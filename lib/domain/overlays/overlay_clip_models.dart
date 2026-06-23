import 'package:nle_editor/domain/overlays/overlay_motion_models.dart';
import 'package:nle_editor/domain/overlays/overlay_style_models.dart';
import 'package:nle_editor/domain/overlays/overlay_value_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

class NleOverlayClipData {
  final String id;
  final NleOverlayClipKind kind;
  final String name;

  final NleOverlayTransform transform;
  final NleShapeStyle? shapeStyle;
  final NleLineStyle? lineStyle;
  final NleStickerStyle? stickerStyle;
  final NleOverlayMotion motion;

  final bool editable;
  final bool locked;
  final bool hidden;
  final int version;

  const NleOverlayClipData({
    required this.id,
    required this.kind,
    required this.name,
    required this.transform,
    this.shapeStyle,
    this.lineStyle,
    this.stickerStyle,
    required this.motion,
    required this.editable,
    required this.locked,
    required this.hidden,
    required this.version,
  });

  factory NleOverlayClipData.rectangle({
    required String id,
  }) {
    return NleOverlayClipData(
      id: id,
      kind: NleOverlayClipKind.shape,
      name: 'Rounded Rectangle',
      transform: const NleOverlayTransform.center(),
      shapeStyle: const NleShapeStyle.defaultRect(),
      motion: const NleOverlayMotion.none(),
      editable: true,
      locked: false,
      hidden: false,
      version: 1,
    );
  }

  factory NleOverlayClipData.circle({
    required String id,
  }) {
    return NleOverlayClipData(
      id: id,
      kind: NleOverlayClipKind.shape,
      name: 'Circle',
      transform: const NleOverlayTransform.center(),
      shapeStyle: const NleShapeStyle.defaultRect().copyWith(
        shapeType: NleShapeType.circle,
        fillColor: const NleRgbaColor(r: 1.0, g: 0.18, b: 0.18, a: 0.75),
        cornerRadius: 999.0,
      ),
      motion: const NleOverlayMotion.none(),
      editable: true,
      locked: false,
      hidden: false,
      version: 1,
    );
  }

  factory NleOverlayClipData.line({
    required String id,
  }) {
    return NleOverlayClipData(
      id: id,
      kind: NleOverlayClipKind.line,
      name: 'Line',
      transform: const NleOverlayTransform.center().copyWith(
        box: const NleRectNorm(
          x: 0.20,
          y: 0.46,
          width: 0.60,
          height: 0.08,
        ),
      ),
      lineStyle: const NleLineStyle.defaultLine(),
      motion: const NleOverlayMotion.none(),
      editable: true,
      locked: false,
      hidden: false,
      version: 1,
    );
  }

  factory NleOverlayClipData.arrow({
    required String id,
  }) {
    return NleOverlayClipData(
      id: id,
      kind: NleOverlayClipKind.arrow,
      name: 'Arrow',
      transform: const NleOverlayTransform.center().copyWith(
        box: const NleRectNorm(
          x: 0.18,
          y: 0.42,
          width: 0.64,
          height: 0.14,
        ),
      ),
      lineStyle: const NleLineStyle.defaultArrow(),
      motion: const NleOverlayMotion(
        preset: NleOverlayAnimationPreset.drawLine,
        keyframes: [],
      ),
      editable: true,
      locked: false,
      hidden: false,
      version: 1,
    );
  }

  factory NleOverlayClipData.callout({
    required String id,
  }) {
    return NleOverlayClipData(
      id: id,
      kind: NleOverlayClipKind.callout,
      name: 'Callout Box',
      transform: const NleOverlayTransform.lowerThird(),
      shapeStyle: const NleShapeStyle.calloutBox(),
      motion: const NleOverlayMotion(
        preset: NleOverlayAnimationPreset.fadeUp,
        keyframes: [],
      ),
      editable: true,
      locked: false,
      hidden: false,
      version: 1,
    );
  }

  factory NleOverlayClipData.sticker({
    required String id,
    String? localPath,
    String? packageAssetPath,
  }) {
    return NleOverlayClipData(
      id: id,
      kind: NleOverlayClipKind.sticker,
      name: 'Sticker',
      transform: const NleOverlayTransform.center().copyWith(
        box: const NleRectNorm(
          x: 0.38,
          y: 0.36,
          width: 0.24,
          height: 0.24,
        ),
      ),
      stickerStyle: NleStickerStyle.empty().copyWith(
        localPath: localPath,
        packageAssetPath: packageAssetPath,
      ),
      motion: const NleOverlayMotion(
        preset: NleOverlayAnimationPreset.pop,
        keyframes: [],
      ),
      editable: true,
      locked: false,
      hidden: false,
      version: 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'name': name,
      'transform': transform.toJson(),
      'shapeStyle': shapeStyle?.toJson(),
      'lineStyle': lineStyle?.toJson(),
      'stickerStyle': stickerStyle?.toJson(),
      'motion': motion.toJson(),
      'editable': editable,
      'locked': locked,
      'hidden': hidden,
      'version': version,
    };
  }

  factory NleOverlayClipData.fromJson(Map<String, dynamic> json) {
    return NleOverlayClipData(
      id: json['id']?.toString() ?? '',
      kind: _enumByName(
        NleOverlayClipKind.values,
        json['kind'],
        NleOverlayClipKind.shape,
      ),
      name: json['name']?.toString() ?? 'Overlay',
      transform: NleOverlayTransform.fromJson(
        Map<String, dynamic>.from(json['transform'] as Map? ?? const {}),
      ),
      shapeStyle: json['shapeStyle'] is Map
          ? NleShapeStyle.fromJson(
              Map<String, dynamic>.from(json['shapeStyle'] as Map),
            )
          : null,
      lineStyle: json['lineStyle'] is Map
          ? NleLineStyle.fromJson(
              Map<String, dynamic>.from(json['lineStyle'] as Map),
            )
          : null,
      stickerStyle: json['stickerStyle'] is Map
          ? NleStickerStyle.fromJson(
              Map<String, dynamic>.from(json['stickerStyle'] as Map),
            )
          : null,
      motion: NleOverlayMotion.fromJson(
        Map<String, dynamic>.from(json['motion'] as Map? ?? const {}),
      ),
      editable: json['editable'] != false,
      locked: json['locked'] == true,
      hidden: json['hidden'] == true,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleOverlayClipData copyWith({
    String? name,
    NleOverlayTransform? transform,
    NleShapeStyle? shapeStyle,
    NleLineStyle? lineStyle,
    NleStickerStyle? stickerStyle,
    NleOverlayMotion? motion,
    bool? editable,
    bool? locked,
    bool? hidden,
    int? version,
  }) {
    return NleOverlayClipData(
      id: id,
      kind: kind,
      name: name ?? this.name,
      transform: transform ?? this.transform,
      shapeStyle: shapeStyle ?? this.shapeStyle,
      lineStyle: lineStyle ?? this.lineStyle,
      stickerStyle: stickerStyle ?? this.stickerStyle,
      motion: motion ?? this.motion,
      editable: editable ?? this.editable,
      locked: locked ?? this.locked,
      hidden: hidden ?? this.hidden,
      version: version ?? this.version,
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
