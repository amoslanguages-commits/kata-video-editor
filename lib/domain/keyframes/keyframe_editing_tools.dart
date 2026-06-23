import 'package:uuid/uuid.dart';

import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

class KeyframeEditingTools {
  static const _uuid = Uuid();

  const KeyframeEditingTools();

  NleAnimatableProperty addKeyframe({
    required NleAnimatableProperty property,
    required int timeOffsetMicros,
    required NleKeyframeValue value,
    NleKeyframeInterpolation interpolation = NleKeyframeInterpolation.easeInOut,
  }) {
    final existing = property.keyframes.where(
      (kf) => kf.timeOffsetMicros == timeOffsetMicros,
    );

    if (existing.isNotEmpty) {
      return updateKeyframeValue(
        property: property,
        keyframeId: existing.first.id,
        value: value,
      );
    }

    final next = [
      ...property.keyframes,
      NleKeyframe(
        id: _uuid.v4(),
        timeOffsetMicros: timeOffsetMicros,
        value: value,
        interpolation: interpolation,
        inHandle: const NleBezierHandle.easeIn(),
        outHandle: const NleBezierHandle.easeOut(),
        selected: false,
        locked: false,
      ),
    ]..sort((a, b) => a.timeOffsetMicros.compareTo(b.timeOffsetMicros));

    return property.copyWith(keyframes: next);
  }

  NleAnimatableProperty updateKeyframeValue({
    required NleAnimatableProperty property,
    required String keyframeId,
    required NleKeyframeValue value,
  }) {
    return property.copyWith(
      keyframes: property.keyframes.map((kf) {
        if (kf.id != keyframeId || kf.locked) return kf;
        return kf.copyWith(value: value);
      }).toList(),
    );
  }

  NleAnimatableProperty moveKeyframe({
    required NleAnimatableProperty property,
    required String keyframeId,
    required int timeOffsetMicros,
    required int clipDurationMicros,
  }) {
    final safeTime = timeOffsetMicros.clamp(0, clipDurationMicros);

    final next = property.keyframes.map((kf) {
      if (kf.id != keyframeId || kf.locked) return kf;
      return kf.copyWith(timeOffsetMicros: safeTime);
    }).toList()
      ..sort((a, b) => a.timeOffsetMicros.compareTo(b.timeOffsetMicros));

    return property.copyWith(keyframes: next);
  }

  NleAnimatableProperty removeKeyframe({
    required NleAnimatableProperty property,
    required String keyframeId,
  }) {
    return property.copyWith(
      keyframes: property.keyframes
          .where((kf) => kf.id != keyframeId || kf.locked)
          .toList(),
    );
  }

  NleAnimatableProperty setInterpolation({
    required NleAnimatableProperty property,
    required String keyframeId,
    required NleKeyframeInterpolation interpolation,
  }) {
    return property.copyWith(
      keyframes: property.keyframes.map((kf) {
        if (kf.id != keyframeId || kf.locked) return kf;
        return kf.copyWith(interpolation: interpolation);
      }).toList(),
    );
  }

  NleAnimatableProperty selectKeyframe({
    required NleAnimatableProperty property,
    required String keyframeId,
    bool additive = false,
  }) {
    return property.copyWith(
      keyframes: property.keyframes.map((kf) {
        if (additive) {
          return kf.id == keyframeId
              ? kf.copyWith(selected: !kf.selected)
              : kf;
        }

        return kf.copyWith(selected: kf.id == keyframeId);
      }).toList(),
    );
  }

  NleAnimatableProperty clearSelection(NleAnimatableProperty property) {
    return property.copyWith(
      keyframes: property.keyframes
          .map((kf) => kf.copyWith(selected: false))
          .toList(),
    );
  }

  NleAnimatableProperty duplicateSelected({
    required NleAnimatableProperty property,
    required int offsetMicros,
    required int clipDurationMicros,
  }) {
    final duplicates = property.keyframes.where((kf) => kf.selected).map((kf) {
      return NleKeyframe(
        id: _uuid.v4(),
        timeOffsetMicros:
            (kf.timeOffsetMicros + offsetMicros).clamp(0, clipDurationMicros),
        value: kf.value,
        interpolation: kf.interpolation,
        inHandle: kf.inHandle,
        outHandle: kf.outHandle,
        selected: true,
        locked: false,
      );
    });

    final originals = property.keyframes
        .map((kf) => kf.copyWith(selected: false))
        .toList();

    final next = [...originals, ...duplicates]
      ..sort((a, b) => a.timeOffsetMicros.compareTo(b.timeOffsetMicros));

    return property.copyWith(keyframes: next);
  }
}
