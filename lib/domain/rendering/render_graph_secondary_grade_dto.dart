import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';

class RenderGraphSecondaryGradeLayerDto {
  final NleSecondaryGradeLayer layer;

  const RenderGraphSecondaryGradeLayerDto({
    required this.layer,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': layer.id,
      'name': layer.name,
      'enabled': layer.enabled,
      'qualifier': layer.qualifier.toJson(),
      'correction': layer.correction.toJson(),
    };
  }
}

class RenderGraphSecondaryGradeStackDto {
  final NleSecondaryGradeStack stack;

  const RenderGraphSecondaryGradeStackDto({
    required this.stack,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': stack.enabled,
      'layers': stack.layers
          .map((layer) => RenderGraphSecondaryGradeLayerDto(layer: layer).toJson())
          .toList(),
    };
  }
}
