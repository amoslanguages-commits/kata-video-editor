import 'dart:convert';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/keyframes/keyframe_parameters.dart';

class KeyframeInterpolator {
  /// Evaluates the value of a parameter at [targetTimeMicros] given a list of [keyframes].
  /// If there are no keyframes, returns the [defaultValue].
  static double evaluate({
    required List<Keyframe> keyframes,
    required String parameterId,
    required int targetTimeMicros,
    required double defaultValue,
  }) {
    final filtered = keyframes.where((k) => k.parameter == parameterId).toList()
      ..sort((a, b) => a.timeMicros.compareTo(b.timeMicros));

    if (filtered.isEmpty) return defaultValue;

    // If target time is before or equal to the first keyframe, return its value
    if (targetTimeMicros <= filtered.first.timeMicros) {
      return _parseValue(filtered.first.valueJson) ?? defaultValue;
    }

    // If target time is after or equal to the last keyframe, return its value
    if (targetTimeMicros >= filtered.last.timeMicros) {
      return _parseValue(filtered.last.valueJson) ?? defaultValue;
    }

    // Find the bounding keyframes
    Keyframe? prev;
    Keyframe? next;
    for (int i = 0; i < filtered.length - 1; i++) {
      if (targetTimeMicros >= filtered[i].timeMicros &&
          targetTimeMicros <= filtered[i + 1].timeMicros) {
        prev = filtered[i];
        next = filtered[i + 1];
        break;
      }
    }

    if (prev == null || next == null) return defaultValue;

    final valPrev = _parseValue(prev.valueJson) ?? defaultValue;
    final valNext = _parseValue(next.valueJson) ?? defaultValue;

    final tDelta = next.timeMicros - prev.timeMicros;
    if (tDelta == 0) return valPrev;

    // Linear progress ratio between 0.0 and 1.0
    final tRatio = (targetTimeMicros - prev.timeMicros) / tDelta;

    final interpolation = prev.interpolation;

    // Apply easing
    double progress = tRatio;
    switch (interpolation) {
      case KeyframeInterpolation.hold:
        return valPrev;
      case KeyframeInterpolation.linear:
        progress = tRatio;
        break;
      case KeyframeInterpolation.easeIn:
        progress = tRatio * tRatio;
        break;
      case KeyframeInterpolation.easeOut:
        progress = tRatio * (2.0 - tRatio);
        break;
      case KeyframeInterpolation.easeInOut:
      case KeyframeInterpolation.smooth:
        progress = tRatio * tRatio * (3.0 - 2.0 * tRatio);
        break;
    }

    return valPrev + (valNext - valPrev) * progress;
  }

  static double? _parseValue(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is num) {
        return decoded.toDouble();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
