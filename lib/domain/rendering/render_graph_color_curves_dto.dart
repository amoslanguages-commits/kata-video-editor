import 'package:nle_editor/domain/color_curves/color_curve_models.dart';

class RenderGraphColorCurveDto {
  final NleColorCurve curve;

  const RenderGraphColorCurveDto({
    required this.curve,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': curve.type.name,
      'enabled': curve.enabled,
      'points': curve.points.map((point) => point.toJson()).toList(),
      'interpolation': curve.interpolation.name,
      'intensity': curve.intensity,
    };
  }
}

class RenderGraphColorCurveStackDto {
  final NleColorCurveStack stack;

  const RenderGraphColorCurveStackDto({
    required this.stack,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': stack.enabled,
      'evaluationSpace': stack.evaluationSpace.name,
      'curves': stack.curves
          .map((curve) => RenderGraphColorCurveDto(curve: curve).toJson())
          .toList(),
    };
  }
}
