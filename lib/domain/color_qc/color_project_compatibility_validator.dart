// lib/domain/color_qc/color_project_compatibility_validator.dart

import 'package:nle_editor/domain/color/project_color_settings.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/color_qc/color_qc_models.dart';
import 'package:nle_editor/domain/color_qc/professional_color_contract.dart';

class ColorProjectCompatibilityValidator implements ProfessionalColorValidator {
  const ColorProjectCompatibilityValidator();

  @override
  ColorQaReport validate(RenderGraphDto graph) {
    final issues = <ColorQaIssue>[];

    // Verify parsing of missing or malformed color settings does not crash
    try {
      final rawLegacySettings = <String, dynamic>{
        'projectId': graph.project.id,
        // Entirely missing 'pipeline' and subfields
      };

      final parsed = ProjectColorSettings.fromJson(rawLegacySettings);

      // Verify defaults are populated
      if (parsed.projectId != graph.project.id) {
        issues.add(
          const ColorQaIssue(
            id: 'legacy_compatibility_id_mismatch',
            severity: ColorQaSeverity.error,
            area: ColorQaArea.deviceFallback,
            title: 'Project ID deserialization failed',
            message: 'Deserialized project ID does not match input project ID.',
            suggestedFix: 'Verify ProjectColorSettings.fromJson parses projectId correctly.',
          ),
        );
      }

      // Check default pipeline is SDR Rec.709
      final defaultColorSpace = parsed.pipeline.working.workingSpace.name;
      if (defaultColorSpace != 'linearRec709') {
        issues.add(
          ColorQaIssue(
            id: 'legacy_compatibility_bad_default',
            severity: ColorQaSeverity.warning,
            area: ColorQaArea.deviceFallback,
            title: 'Non-standard fallback color space',
            message: "Fallback working space is '$defaultColorSpace' instead of Rec.709 SDR.",
            suggestedFix: 'Standardize safety fallback to Rec.709 SDR.',
          ),
        );
      }
    } catch (e) {
      issues.add(
        ColorQaIssue(
          id: 'legacy_compatibility_crash',
          severity: ColorQaSeverity.releaseBlocker,
          area: ColorQaArea.deviceFallback,
          title: 'Legacy project parsing crash',
          message: 'Deserializing legacy JSON without color fields crashed: $e',
          suggestedFix: 'Ensure all JSON properties fallback to defaults on null.',
        ),
      );
    }

    final hasBlockers = issues.any((i) => i.severity == ColorQaSeverity.releaseBlocker);

    return ColorQaReport(
      timestamp: DateTime.now(),
      passed: !hasBlockers,
      issues: issues,
    );
  }
}
