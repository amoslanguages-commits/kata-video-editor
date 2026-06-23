// lib/domain/color_qc/color_identity_validator.dart

import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/color_qc/color_qc_models.dart';
import 'package:nle_editor/domain/color_qc/professional_color_contract.dart';

class ColorIdentityValidator implements ProfessionalColorValidator {
  const ColorIdentityValidator();

  @override
  ColorQaReport validate(RenderGraphDto graph) {
    final issues = <ColorQaIssue>[];

    for (final track in graph.tracks) {
      for (final clip in track.clips) {
        final List<String> activeGrades = [];

        // 1. Primary grade
        if (clip.primaryGrade != null && !clip.primaryGrade!.grade.isIdentity) {
          activeGrades.add('Primary Wheels');
        }

        // 2. Color curves
        if (clip.colorCurves != null && !clip.colorCurves!.stack.isIdentity) {
          activeGrades.add('RGB/HSL Curves');
        }

        // 3. Secondary grades (qualifiers)
        if (clip.secondaryGrades != null && !clip.secondaryGrades!.stack.isIdentity) {
          activeGrades.add('HSL Qualifiers');
        }

        // 4. LUT stack
        if (clip.lutStack != null) {
          final hasEnabledLuts = clip.lutStack!.layers.any(
            (layerDto) => layerDto.layer.enabled && layerDto.layer.intensity > 0.0,
          );
          if (hasEnabledLuts) {
            activeGrades.add('3D LUT');
          }
        }

        // 5. Film look
        if (clip.filmLook != null && !clip.filmLook!.settings.isIdentity) {
          activeGrades.add('Film Science/Effects');
        }

        if (activeGrades.isNotEmpty) {
          issues.add(
            ColorQaIssue(
              id: 'identity_non_neutral_${clip.id}',
              severity: ColorQaSeverity.info,
              area: ColorQaArea.colorManagement,
              title: 'Non-neutral color grading active',
              message: "Clip '${clip.name}' has active adjustments: ${activeGrades.join(', ')}.",
              suggestedFix: 'Reset grading parameters to neutrality if a clean pass is desired.',
            ),
          );
        }
      }
    }

    return ColorQaReport(
      timestamp: DateTime.now(),
      passed: true, // Neutrality checks are informative, so they always pass
      issues: issues,
    );
  }
}
