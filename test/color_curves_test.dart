import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/domain/color_curves/color_curve_models.dart';
import 'package:nle_editor/domain/color_curves/color_curve_evaluator.dart';
import 'package:nle_editor/domain/rendering/render_graph_color_curves_dto.dart';

void main() {
  group('Color Curves Domain Models', () {
    test('Identity stack initialization', () {
      final stack = NleColorCurveStack.identity();
      expect(stack.enabled, isTrue);
      expect(stack.evaluationSpace, equals(NleCurveEvaluationSpace.sceneLinear));
      expect(stack.curves.length, equals(NleCurveType.values.length));
      expect(stack.isIdentity, isTrue);
    });

    test('isIdentity checks custom points', () {
      final curve = NleColorCurve.identity(NleCurveType.red);
      expect(curve.isIdentity, isTrue);

      final modifiedCurve = curve.copyWith(
        points: const [
          NleCurvePoint(x: 0.0, y: 0.0),
          NleCurvePoint(x: 0.5, y: 0.6),
          NleCurvePoint(x: 1.0, y: 1.0),
        ],
      );
      expect(modifiedCurve.isIdentity, isFalse);
    });

    test('updateCurve works as expected', () {
      final stack = NleColorCurveStack.identity();
      final customRed = NleColorCurve(
        type: NleCurveType.red,
        enabled: true,
        points: const [
          NleCurvePoint(x: 0.0, y: 0.1),
          NleCurvePoint(x: 1.0, y: 0.9),
        ],
      );

      final updated = stack.updateCurve(customRed);
      expect(updated.curve(NleCurveType.red).points.first.y, equals(0.1));
      expect(updated.curve(NleCurveType.green).isIdentity, isTrue);
    });
  });

  group('Color Curve Evaluator', () {
    const evaluator = ColorCurveEvaluator();

    test('Linear identity evaluation', () {
      final curve = NleColorCurve.identity(NleCurveType.rgbMaster);
      expect(evaluator.evaluate(curve, 0.0), closeTo(0.0, 0.0001));
      expect(evaluator.evaluate(curve, 0.5), closeTo(0.5, 0.0001));
      expect(evaluator.evaluate(curve, 1.0), closeTo(1.0, 0.0001));
    });

    test('Disabled curve returns identity', () {
      final curve = NleColorCurve(
        type: NleCurveType.red,
        enabled: false,
        points: const [
          NleCurvePoint(x: 0.0, y: 1.0),
          NleCurvePoint(x: 1.0, y: 0.0),
        ],
      );
      expect(evaluator.evaluate(curve, 0.25), closeTo(0.25, 0.0001));
    });

    test('Evaluation clamping and sorting', () {
      final curve = NleColorCurve(
        type: NleCurveType.green,
        enabled: true,
        points: const [
          NleCurvePoint(x: 1.0, y: 0.9),
          NleCurvePoint(x: 0.0, y: 0.1),
        ],
      );
      // Evaluator should internally sort points by x: (0, 0.1) and (1, 0.9)
      expect(evaluator.evaluate(curve, 0.0), closeTo(0.1, 0.0001));
      expect(evaluator.evaluate(curve, 1.0), closeTo(0.9, 0.0001));
    });

    test('Packing lookup tables', () {
      final stack = NleColorCurveStack.identity();
      final rgbTexture = evaluator.buildPackedRgbCurveTexture(stack: stack);
      expect(rgbTexture.length, equals(256 * 4));
      // First pixel channels should be roughly 0.0 (except A which is Blue, 0.0 here)
      expect(rgbTexture[0], closeTo(0.0, 0.0001));
      // Last pixel should be 1.0
      expect(rgbTexture[(256 - 1) * 4], closeTo(1.0, 0.0001));

      final hslTexture = evaluator.buildPackedHslCurveTexture(stack: stack);
      expect(hslTexture.length, equals(256 * 8));
      // Last pixel luma curve channel (index 5) should be 1.0
      expect(hslTexture[(256 - 1) * 8 + 5], closeTo(1.0, 0.0001));
    });
  });

  group('Color Curves Serialization', () {
    test('JSON serialization roundtrip', () {
      final stack = NleColorCurveStack(
        enabled: true,
        evaluationSpace: NleCurveEvaluationSpace.displayReferred,
        curves: [
          NleColorCurve(
            type: NleCurveType.rgbMaster,
            enabled: true,
            points: const [
              NleCurvePoint(x: 0.0, y: 0.1),
              NleCurvePoint(x: 0.5, y: 0.5),
              NleCurvePoint(x: 1.0, y: 0.9),
            ],
            interpolation: NleCurveInterpolation.linear,
            intensity: 0.8,
          ),
        ],
      );

      final json = stack.toJson();
      final decoded = NleColorCurveStack.fromJson(json);

      expect(decoded.enabled, isTrue);
      expect(decoded.evaluationSpace, equals(NleCurveEvaluationSpace.displayReferred));
      
      final rgbMaster = decoded.curve(NleCurveType.rgbMaster);
      expect(rgbMaster.points.length, equals(3));
      expect(rgbMaster.points[0].y, equals(0.1));
      expect(rgbMaster.interpolation, equals(NleCurveInterpolation.linear));
      expect(rgbMaster.intensity, equals(0.8));
    });

    test('RenderGraph DTO serialization', () {
      final stack = NleColorCurveStack.identity();
      final dto = RenderGraphColorCurveStackDto(stack: stack);
      final json = dto.toJson();

      expect(json['enabled'], isTrue);
      expect(json['evaluationSpace'], equals('sceneLinear'));
      expect(json['curves'], isA<List>());
    });
  });
}
