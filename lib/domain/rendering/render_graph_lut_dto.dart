import 'package:nle_editor/domain/color_lut/color_lut_models.dart';

class RenderGraphLutLayerDto {
  final NleLutLayer layer;

  const RenderGraphLutLayerDto({
    required this.layer,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': layer.id,
      'lutAssetId': layer.lutAssetId,
      'lutPath': layer.lutPath,
      'name': layer.name,
      'size': layer.size,
      'intensity': layer.intensity,
      'enabled': layer.enabled,
      'domain': layer.domain.name,
      'interpolation': layer.interpolation.name,
    };
  }
}

class RenderGraphLutStackDto {
  final String clipId;
  final List<RenderGraphLutLayerDto> layers;

  const RenderGraphLutStackDto({
    required this.clipId,
    required this.layers,
  });

  Map<String, dynamic> toJson() {
    return {
      'clipId': clipId,
      'layers': layers.map((layer) => layer.toJson()).toList(),
    };
  }
}
