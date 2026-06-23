import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nle_editor/domain/color_curves/color_curve_models.dart';

class ColorCurveEvaluator {
  const ColorCurveEvaluator();

  double evaluate(
    NleColorCurve curve,
    double x,
  ) {
    if (!curve.enabled || curve.points.isEmpty) {
      return x.clamp(0.0, 1.0);
    }

    final points = curve.sortedPoints.map((p) => p.clamp()).toList();

    if (points.length == 1) {
      return points.first.y.clamp(0.0, 1.0);
    }

    final input = x.clamp(0.0, 1.0);

    if (input <= points.first.x) return points.first.y.clamp(0.0, 1.0);
    if (input >= points.last.x) return points.last.y.clamp(0.0, 1.0);

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];

      if (input >= a.x && input <= b.x) {
        final span = math.max(b.x - a.x, 0.00001);
        final tRaw = (input - a.x) / span;

        final t = curve.interpolation == NleCurveInterpolation.smooth
            ? _smoothStep(tRaw)
            : tRaw;

        final y = a.y + (b.y - a.y) * t;

        final mixed = input + (y - input) * curve.intensity.clamp(0.0, 1.0);

        return mixed.clamp(0.0, 1.0);
      }
    }

    return input;
  }

  Float32List buildLookupTable({
    required NleColorCurve curve,
    int size = 256,
  }) {
    final result = Float32List(size);

    for (var i = 0; i < size; i++) {
      final x = i / (size - 1);
      result[i] = evaluate(curve, x);
    }

    return result;
  }

  Float32List buildPackedRgbCurveTexture({
    required NleColorCurveStack stack,
    int size = 256,
  }) {
    final master = buildLookupTable(
      curve: stack.curve(NleCurveType.rgbMaster),
      size: size,
    );

    final red = buildLookupTable(
      curve: stack.curve(NleCurveType.red),
      size: size,
    );

    final green = buildLookupTable(
      curve: stack.curve(NleCurveType.green),
      size: size,
    );

    final blue = buildLookupTable(
      curve: stack.curve(NleCurveType.blue),
      size: size,
    );

    final packed = Float32List(size * 4);

    for (var i = 0; i < size; i++) {
      packed[i * 4] = master[i];
      packed[i * 4 + 1] = red[i];
      packed[i * 4 + 2] = green[i];
      packed[i * 4 + 3] = blue[i];
    }

    return packed;
  }

  Float32List buildPackedHslCurveTexture({
    required NleColorCurveStack stack,
    int size = 256,
  }) {
    final hueVsSat = buildLookupTable(
      curve: stack.curve(NleCurveType.hueVsSat),
      size: size,
    );

    final hueVsHue = buildLookupTable(
      curve: stack.curve(NleCurveType.hueVsHue),
      size: size,
    );

    final hueVsLum = buildLookupTable(
      curve: stack.curve(NleCurveType.hueVsLum),
      size: size,
    );

    final lumVsSat = buildLookupTable(
      curve: stack.curve(NleCurveType.lumVsSat),
      size: size,
    );

    final satVsSat = buildLookupTable(
      curve: stack.curve(NleCurveType.satVsSat),
      size: size,
    );

    final luma = buildLookupTable(
      curve: stack.curve(NleCurveType.luma),
      size: size,
    );

    final packed = Float32List(size * 8);

    for (var i = 0; i < size; i++) {
      packed[i * 8] = hueVsSat[i];
      packed[i * 8 + 1] = hueVsHue[i];
      packed[i * 8 + 2] = hueVsLum[i];
      packed[i * 8 + 3] = lumVsSat[i];

      packed[i * 8 + 4] = satVsSat[i];
      packed[i * 8 + 5] = luma[i]; // Packed luma curve
      packed[i * 8 + 6] = 0.0;
      packed[i * 8 + 7] = 1.0;
    }

    return packed;
  }

  double _smoothStep(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3.0 - 2.0 * x);
  }
}
