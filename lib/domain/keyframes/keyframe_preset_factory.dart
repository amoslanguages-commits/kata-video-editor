import 'package:uuid/uuid.dart';

import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

enum NleKeyframePresetId {
  fadeIn,
  fadeOut,
  fadeInOut,
  scalePop,
  slideLeftIn,
  slideRightIn,
  gentleZoom,
  spinIn,
}

class KeyframePresetFactory {
  static const _uuid = Uuid();

  const KeyframePresetFactory();

  List<NleKeyframe> buildPreset({
    required NleKeyframePresetId preset,
    required NleAnimatableProperty property,
    required int durationMicros,
  }) {
    switch (preset) {
      case NleKeyframePresetId.fadeIn:
        return _numberPair(
          start: 0.0,
          end: 1.0,
          durationMicros: durationMicros,
        );

      case NleKeyframePresetId.fadeOut:
        return _numberPair(
          start: 1.0,
          end: 0.0,
          durationMicros: durationMicros,
        );

      case NleKeyframePresetId.fadeInOut:
        return [
          _number(0, 0.0),
          _number((durationMicros * 0.18).round(), 1.0),
          _number((durationMicros * 0.82).round(), 1.0),
          _number(durationMicros, 0.0),
        ];

      case NleKeyframePresetId.scalePop:
        return [
          _number(0, 0.75),
          _number((durationMicros * 0.18).round(), 1.10),
          _number((durationMicros * 0.30).round(), 1.0),
        ];

      case NleKeyframePresetId.slideLeftIn:
        return _numberPair(
          start: 1.0,
          end: 0.0,
          durationMicros: (durationMicros * 0.22).round(),
        );

      case NleKeyframePresetId.slideRightIn:
        return _numberPair(
          start: -1.0,
          end: 0.0,
          durationMicros: (durationMicros * 0.22).round(),
        );

      case NleKeyframePresetId.gentleZoom:
        return _numberPair(
          start: 1.0,
          end: 1.06,
          durationMicros: durationMicros,
        );

      case NleKeyframePresetId.spinIn:
        return _numberPair(
          start: -12.0,
          end: 0.0,
          durationMicros: (durationMicros * 0.25).round(),
        );
    }
  }

  List<NleKeyframe> _numberPair({
    required double start,
    required double end,
    required int durationMicros,
  }) {
    return [
      _number(0, start),
      _number(durationMicros, end),
    ];
  }

  NleKeyframe _number(int timeMicros, double value) {
    return NleKeyframe(
      id: _uuid.v4(),
      timeOffsetMicros: timeMicros,
      value: NleKeyframeValue.number(value),
      interpolation: NleKeyframeInterpolation.easeInOut,
      inHandle: const NleBezierHandle.easeIn(),
      outHandle: const NleBezierHandle.easeOut(),
      selected: false,
      locked: false,
    );
  }
}
