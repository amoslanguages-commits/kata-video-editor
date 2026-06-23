// lib/domain/color_qc/render_graph_color_validator.dart

import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/color_qc/color_qc_models.dart';
import 'package:nle_editor/domain/color_qc/professional_color_contract.dart';

class RenderGraphColorValidator implements ProfessionalColorValidator {
  const RenderGraphColorValidator();

  @override
  ColorQaReport validate(RenderGraphDto graph) {
    final issues = <ColorQaIssue>[];

    // 1. Verify Color Pipeline presence and state
    if (graph.colorPipeline == null) {
      issues.add(
        const ColorQaIssue(
          id: 'color_pipeline_missing',
          severity: ColorQaSeverity.warning,
          area: ColorQaArea.colorManagement,
          title: 'Color management pipeline missing',
          message: 'The render graph has no colorPipeline configuration.',
          suggestedFix: 'Initialize ProjectColorSettings before building the graph.',
        ),
      );
    } else if (!graph.colorPipeline!.enabled) {
      issues.add(
        const ColorQaIssue(
          id: 'color_pipeline_disabled',
          severity: ColorQaSeverity.warning,
          area: ColorQaArea.colorManagement,
          title: 'Color management pipeline disabled',
          message: 'Color management is disabled in the settings.',
          suggestedFix: 'Enable color management to support floating point rendering.',
        ),
      );
    }

    // 2. Verify export hints mapping
    final hints = graph.exportHints;
    if (hints.isHdrOutput && !hints.requiresGpuCompositor) {
      issues.add(
        const ColorQaIssue(
          id: 'hdr_without_gpu_compositor',
          severity: ColorQaSeverity.error,
          area: ColorQaArea.gpuPipeline,
          title: 'HDR export requires GPU Compositor',
          message: 'HDR output is enabled but requiresGpuCompositor is set to false.',
          suggestedFix: 'Enable GPU Compositor in export settings for high dynamic range processing.',
        ),
      );
    }

    // 3. Verify bit depth safety
    if (hints.requiresTenBit && !hints.isHdrOutput && !hints.isWideColorOutput) {
      issues.add(
        const ColorQaIssue(
          id: 'ten_bit_without_hdr',
          severity: ColorQaSeverity.warning,
          area: ColorQaArea.hdrOutput,
          title: '10-bit color specified for SDR output',
          message: 'Export requires 10-bit depth, but output is standard Rec.709/sRGB SDR.',
          suggestedFix: 'Standardize to 8-bit depth unless Wide Color Gamut or HDR is enabled.',
        ),
      );
    }

    // 4. Verify quality constraints
    if (graph.colorPipeline != null) {
      final quality = graph.colorPipeline!.quality;
      if (quality != 'high' && quality != 'medium' && quality != 'low' && quality != 'compatibility') {
        issues.add(
          ColorQaIssue(
            id: 'invalid_color_pipeline_quality',
            severity: ColorQaSeverity.error,
            area: ColorQaArea.colorManagement,
            title: 'Invalid pipeline quality mode',
            message: "The quality mode '$quality' is unsupported.",
            suggestedFix: "Use 'high', 'medium', 'low', or 'compatibility'.",
          ),
        );
      }
    }

    final hasErrors = issues.any((i) => i.severity == ColorQaSeverity.error || i.severity == ColorQaSeverity.releaseBlocker);

    return ColorQaReport(
      timestamp: DateTime.now(),
      passed: !hasErrors,
      issues: issues,
    );
  }
}
