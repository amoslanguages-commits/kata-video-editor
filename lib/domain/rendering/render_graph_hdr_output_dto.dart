// lib/domain/rendering/render_graph_hdr_output_dto.dart
//
// 30J-PRO: Render Graph representation of the HDR Output Settings
// that is serialized and passed down to the native GPU compositor.

import 'package:nle_editor/domain/color_output/hdr_output_models.dart';

class RenderGraphHdrOutputDto {
  final NleHdrOutputSettings settings;

  const RenderGraphHdrOutputDto({
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'colorMode': settings.colorMode.name,
      'transferFunction': settings.transferFunction.name,
      'toneMapOperator': settings.toneMapOperator.name,
      'metadataMode': settings.metadataMode.name,
      'colorRange': settings.colorRange.name,
      'bitDepth': settings.bitDepth.name,
      'previewMode': settings.previewMode.name,
      'targetPeakNits': settings.targetPeakNits,
      'masteringMetadata': settings.masteringMetadata.toJson(),
    };
  }
}
