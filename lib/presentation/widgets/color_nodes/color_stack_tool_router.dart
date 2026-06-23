// lib/presentation/widgets/color_nodes/color_stack_tool_router.dart
//
// 30J-PRO: Router widget that returns the correct editing panel
// (Primary, Curves, Qualifier, LUT, Film Look, or HDR Output)
// based on the selected color node type.

import 'package:flutter/material.dart';
import 'package:nle_editor/domain/color_nodes/color_node_models.dart';
import 'package:nle_editor/presentation/widgets/color_grade/primary_grade_panel.dart';
import 'package:nle_editor/presentation/widgets/color_curves/color_curves_panel.dart';
import 'package:nle_editor/presentation/widgets/color_qualifier/hsl_qualifier_panel.dart';
import 'package:nle_editor/presentation/widgets/color_lut/lut_panel.dart';
import 'package:nle_editor/presentation/widgets/film_look/film_look_panel.dart';
import 'package:nle_editor/presentation/widgets/color_output/hdr_output_panel.dart';

class ColorStackToolRouter extends StatelessWidget {
  final NleColorNodeType nodeType;
  final String ownerId; // clipId or projectId

  const ColorStackToolRouter({
    super.key,
    required this.nodeType,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    switch (nodeType) {
      case NleColorNodeType.primary:
        return PrimaryGradePanel(selectedClipId: ownerId);
      case NleColorNodeType.curves:
        return ColorCurvesPanel(selectedClipId: ownerId);
      case NleColorNodeType.qualifier:
        return HslQualifierPanel(selectedClipId: ownerId);
      case NleColorNodeType.lut:
        return LutPanel(selectedClipId: ownerId);
      case NleColorNodeType.filmLook:
        return FilmLookPanel(selectedClipId: ownerId);
      case NleColorNodeType.output:
        return HdrOutputPanel(projectId: ownerId);
      default:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'No editor panel for ${nodeType.name.toUpperCase()} node.',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}
