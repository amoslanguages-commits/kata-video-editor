// lib/domain/color_qc/professional_color_contract.dart

import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/color_qc/color_qc_models.dart';

abstract class ProfessionalColorValidator {
  const ProfessionalColorValidator();

  ColorQaReport validate(RenderGraphDto graph);
}
