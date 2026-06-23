import 'dart:math' as math;

import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

class KeyframeInterpolationEngine {
  const KeyframeInterpolationEngine();

  NleKeyframeValue sampleProperty({
    required NleAnimatableProperty property,
    required int localTimeMicros,
  }) {
    if (!property.enabled) return property.defaultValue;

    final keyframes = property.orderedKeyframes;

    if (keyframes.isEmpty) return property.defaultValue;
    if (keyframes.length == 1) return keyframes.first.value;

    if (localTimeMicros <= keyframes.first.timeOffsetMicros) {
      return keyframes.first.value;
    }

    if (localTimeMicros >= keyframes.last.timeOffsetMicros) {
      return keyframes.last.value;
    }

    for (var i = 0; i < keyframes.length - 1; i++) {
      final a = keyframes[i];
      final b = keyframes[i + 1];

      if (localTimeMicros >= a.timeOffsetMicros &&
          localTimeMicros <= b.timeOffsetMicros) {
        return _interpolatePair(
          a: a,
          b: b,
          valueType: property.valueType,
          localTimeMicros: localTimeMicros,
        );
      }
    }

    return property.defaultValue;
  }

  NleKeyframeValue _interpolatePair({
    required NleKeyframe a,
    required NleKeyframe b,
    required NleKeyframeValueType valueType,
    required int localTimeMicros,
  }) {
    if (a.interpolation == NleKeyframeInterpolation.hold) {
      return a.value;
    }

    final duration = math.max(
      1,
      b.timeOffsetMicros - a.timeOffsetMicros,
    );

    final rawT = ((localTimeMicros - a.timeOffsetMicros) / duration)
        .clamp(0.0, 1.0);

    final t = _easedT(
      rawT,
      a.interpolation,
      a.outHandle,
      b.inHandle,
    );

    switch (valueType) {
      case NleKeyframeValueType.number:
        return NleKeyframeValue.number(
          _lerp(a.value.numberOrZero, b.value.numberOrZero, t),
        );

      case NleKeyframeValueType.boolean:
        return rawT < 0.5 ? a.value : b.value;

      case NleKeyframeValueType.vec2:
        final av = a.value.vec2OrZero;
        final bv = b.value.vec2OrZero;

        return NleKeyframeValue.vec2(
          NleKeyframeVec2Value(
            x: _lerp(av.x, bv.x, t),
            y: _lerp(av.y, bv.y, t),
          ),
        );

      case NleKeyframeValueType.color:
        final ac = a.value.value as NleKeyframeColorValue?;
        final bc = b.value.value as NleKeyframeColorValue?;

        if (ac == null || bc == null) return a.value;

        return NleKeyframeValue.color(
          NleKeyframeColorValue(
            r: _lerp(ac.r, bc.r, t),
            g: _lerp(ac.g, bc.g, t),
            b: _lerp(ac.b, bc.b, t),
            a: _lerp(ac.a, bc.a, t),
          ),
        );
    }
  }

  double _easedT(
    double t,
    NleKeyframeInterpolation interpolation,
    NleBezierHandle outHandle,
    NleBezierHandle inHandle,
  ) {
    switch (interpolation) {
      case NleKeyframeInterpolation.hold:
        return 0.0;

      case NleKeyframeInterpolation.linear:
        return t;

      case NleKeyframeInterpolation.easeIn:
        return t * t;

      case NleKeyframeInterpolation.easeOut:
        return 1.0 - math.pow(1.0 - t, 2.0).toDouble();

      case NleKeyframeInterpolation.easeInOut:
        return t < 0.5
            ? 2.0 * t * t
            : 1.0 - math.pow(-2.0 * t + 2.0, 2.0).toDouble() / 2.0;

      case NleKeyframeInterpolation.spring:
        final damp = math.exp(-6.0 * t);
        final oscillation = math.cos(12.0 * t);
        return (1.0 - damp * oscillation).clamp(0.0, 1.0);

      case NleKeyframeInterpolation.bezier:
        return _cubicBezierY(
          t,
          outHandle.x,
          outHandle.y,
          inHandle.x,
          inHandle.y,
        );
    }
  }

  double _cubicBezierY(
    double t,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final u = 1.0 - t;
    return 3 * u * u * t * y1 +
        3 * u * t * t * y2 +
        t * t * t;
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
