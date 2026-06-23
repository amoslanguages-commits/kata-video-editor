import 'package:nle_editor/domain/titles/title_value_models.dart';

enum NleTextMotionProperty {
  positionX,
  positionY,
  scale,
  rotation,
  opacity,
  blur,
}

enum NleKeyframeEasing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  springSoft,
}

enum NleTitleAnimationPreset {
  none,
  fadeIn,
  fadeUp,
  slideLeft,
  slideRight,
  scalePop,
  cinematicSlowZoom,
  lowerThirdSlide,
}

class NleTitleKeyframe {
  final String id;
  final int timeOffsetMicros;
  final NleTextMotionProperty property;
  final double value;
  final NleKeyframeEasing easing;

  const NleTitleKeyframe({
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

  factory NleTitleKeyframe.fromJson(Map<String, dynamic> json) {
    return NleTitleKeyframe(
      id: json['id']?.toString() ?? '',
      timeOffsetMicros: (json['timeOffsetMicros'] as num?)?.toInt() ?? 0,
      property: _enumByName(
        NleTextMotionProperty.values,
        json['property'],
        NleTextMotionProperty.opacity,
      ),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      easing: _enumByName(
        NleKeyframeEasing.values,
        json['easing'],
        NleKeyframeEasing.easeInOut,
      ),
    );
  }
}

class NleTitleMotion {
  final NleVec2 position;
  final double scale;
  final double rotationDegrees;
  final double opacity;
  final double blur;
  final NleTitleAnimationPreset animationPreset;
  final List<NleTitleKeyframe> keyframes;

  const NleTitleMotion({
    required this.position,
    required this.scale,
    required this.rotationDegrees,
    required this.opacity,
    required this.blur,
    required this.animationPreset,
    required this.keyframes,
  });

  const NleTitleMotion.identity()
      : position = const NleVec2.zero(),
        scale = 1.0,
        rotationDegrees = 0.0,
        opacity = 1.0,
        blur = 0.0,
        animationPreset = NleTitleAnimationPreset.none,
        keyframes = const [];

  Map<String, dynamic> toJson() {
    return {
      'position': position.toJson(),
      'scale': scale,
      'rotationDegrees': rotationDegrees,
      'opacity': opacity,
      'blur': blur,
      'animationPreset': animationPreset.name,
      'keyframes': keyframes.map((k) => k.toJson()).toList(),
    };
  }

  factory NleTitleMotion.fromJson(Map<String, dynamic> json) {
    return NleTitleMotion(
      position: NleVec2.fromJson(
        Map<String, dynamic>.from(json['position'] as Map? ?? const {}),
      ),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotationDegrees: (json['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      animationPreset: _enumByName(
        NleTitleAnimationPreset.values,
        json['animationPreset'],
        NleTitleAnimationPreset.none,
      ),
      keyframes: (json['keyframes'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleTitleKeyframe.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  NleTitleMotion copyWith({
    NleVec2? position,
    double? scale,
    double? rotationDegrees,
    double? opacity,
    double? blur,
    NleTitleAnimationPreset? animationPreset,
    List<NleTitleKeyframe>? keyframes,
  }) {
    return NleTitleMotion(
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      opacity: opacity ?? this.opacity,
      blur: blur ?? this.blur,
      animationPreset: animationPreset ?? this.animationPreset,
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
