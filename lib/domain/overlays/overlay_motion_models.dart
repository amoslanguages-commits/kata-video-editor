import 'package:nle_editor/domain/overlays/overlay_value_models.dart';

enum NleOverlayMotionProperty {
  x,
  y,
  width,
  height,
  scale,
  rotation,
  opacity,
}

enum NleOverlayEasing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  spring,
}

class NleOverlayKeyframe {
  final String id;
  final int timeOffsetMicros;
  final NleOverlayMotionProperty property;
  final double value;
  final NleOverlayEasing easing;

  const NleOverlayKeyframe({
    required this.id,
    required this.timeOffsetMicros,
    required this.property,
    required this.value,
    required this.easing,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeOffsetMicros': timeOffsetMicros,
      'property': property.name,
      'value': value,
      'easing': easing.name,
    };
  }

  factory NleOverlayKeyframe.fromJson(Map<String, dynamic> json) {
    return NleOverlayKeyframe(
      id: json['id']?.toString() ?? '',
      timeOffsetMicros: (json['timeOffsetMicros'] as num?)?.toInt() ?? 0,
      property: _enumByName(
        NleOverlayMotionProperty.values,
        json['property'],
        NleOverlayMotionProperty.opacity,
      ),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      easing: _enumByName(
        NleOverlayEasing.values,
        json['easing'],
        NleOverlayEasing.easeInOut,
      ),
    );
  }
}

class NleOverlayMotion {
  final NleOverlayAnimationPreset preset;
  final List<NleOverlayKeyframe> keyframes;

  const NleOverlayMotion({
    required this.preset,
    required this.keyframes,
  });

  const NleOverlayMotion.none()
      : preset = NleOverlayAnimationPreset.none,
        keyframes = const [];

  Map<String, dynamic> toJson() {
    return {
      'preset': preset.name,
      'keyframes': keyframes.map((item) => item.toJson()).toList(),
    };
  }

  factory NleOverlayMotion.fromJson(Map<String, dynamic> json) {
    return NleOverlayMotion(
      preset: _enumByName(
        NleOverlayAnimationPreset.values,
        json['preset'],
        NleOverlayAnimationPreset.none,
      ),
      keyframes: (json['keyframes'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleOverlayKeyframe.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  NleOverlayMotion copyWith({
    NleOverlayAnimationPreset? preset,
    List<NleOverlayKeyframe>? keyframes,
  }) {
    return NleOverlayMotion(
      preset: preset ?? this.preset,
      keyframes: keyframes ?? this.keyframes,
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
