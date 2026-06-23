// lib/domain/color_qc/color_pass_order_validator.dart

import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/color_qc/color_qc_models.dart';
import 'package:nle_editor/domain/color_qc/professional_color_contract.dart';

class ColorPassOrderValidator implements ProfessionalColorValidator {
  const ColorPassOrderValidator();

  @override
  ColorQaReport validate(RenderGraphDto graph) {
    final issues = <ColorQaIssue>[];

    // Define the correct canonical order of passes
    final canonicalOrder = [
      'input_to_scene_linear',
      'primary_grade',
      'color_curves',
      'secondary_grade',
      'gpu_lut',
      'film_look',
      'output_display_transform',
    ];

    // Helper to get matching canonical index
    int getPassIndex(String passId) {
      if (passId.startsWith('secondary_grade_')) {
        return canonicalOrder.indexOf('secondary_grade');
      }
      if (passId.startsWith('gpu_lut_')) {
        return canonicalOrder.indexOf('gpu_lut');
      }
      if (passId.startsWith('film_look_')) {
        return canonicalOrder.indexOf('film_look');
      }
      return canonicalOrder.indexOf(passId);
    }

    // 1. Validate GPU pass order from a list of simulated or parsed pass IDs
    // Since Dart builds the graph, we check if the metadata overrides the pass list (useful for test cases),
    // otherwise we build the correct canonical one.
    final customPassIds = graph.metadata['simulatedPassIds'] as List?;
    
    if (customPassIds != null) {
      final passIds = customPassIds.map((e) => e.toString()).toList();
      int lastIndex = -1;
      for (final pass in passIds) {
        final index = getPassIndex(pass);
        if (index == -1) continue;

        if (index < lastIndex) {
          issues.add(
            ColorQaIssue(
              id: 'NATIVE_PASS_BAD_ORDER_$pass',
              severity: ColorQaSeverity.releaseBlocker,
              area: ColorQaArea.gpuPipeline,
              title: 'GPU pass order is wrong',
              message: "Pass '$pass' appears after a later stage in simulated sequence.",
              suggestedFix: 'Use Input → Primary → Curves → Qualifier → LUT → Film Look → Output.',
            ),
          );
        }
        lastIndex = index;
      }

      final containsOutputTransform = passIds.any((it) => it == 'output_display_transform' || it == 'hdrOutputTransform');
      if (!containsOutputTransform) {
        issues.add(
          const ColorQaIssue(
            id: 'NATIVE_PASS_OUTPUT_MISSING',
            severity: ColorQaSeverity.releaseBlocker,
            area: ColorQaArea.hdrOutput,
            title: 'Output transform pass missing',
            message: 'No HDR/WCG output transform pass exists in the final chain.',
            suggestedFix: 'Add NleHdrOutputTransformPass as the final pass.',
          ),
        );
      }
    } else {
      for (final track in graph.tracks) {
        for (final clip in track.clips) {
          if (clip.isDisabled) continue;

          final passIds = <String>[];
          passIds.add('input_to_scene_linear');

          if (clip.primaryGrade != null && clip.primaryGrade!.grade.enabled) {
            passIds.add('primary_grade');
          }
          if (clip.colorCurves != null && clip.colorCurves!.stack.enabled) {
            passIds.add('color_curves');
          }
          if (clip.secondaryGrades != null && clip.secondaryGrades!.stack.enabled) {
            for (final layer in clip.secondaryGrades!.stack.layers) {
              if (layer.enabled) {
                passIds.add('secondary_grade_${layer.id}');
              }
            }
          }
          if (clip.lutStack != null) {
            for (final layerDto in clip.lutStack!.layers) {
              if (layerDto.layer.enabled) {
                passIds.add('gpu_lut_${layerDto.layer.id}');
              }
            }
          }
          if (clip.filmLook != null && clip.filmLook!.settings.enabled) {
            passIds.add('film_look_${clip.id}');
          }

          passIds.add('output_display_transform');

          // Check sequence ordering
          int lastIndex = -1;
          for (final pass in passIds) {
            final index = getPassIndex(pass);
            if (index == -1) continue;

            if (index < lastIndex) {
              issues.add(
                ColorQaIssue(
                  id: 'NATIVE_PASS_BAD_ORDER_$pass',
                  severity: ColorQaSeverity.releaseBlocker,
                  area: ColorQaArea.gpuPipeline,
                  title: 'GPU pass order is wrong',
                  message: "Pass '$pass' appears after a later stage in clip '${clip.name}'.",
                  suggestedFix: 'Use Input → Primary → Curves → Qualifier → LUT → Film Look → Output.',
                ),
              );
            }
            lastIndex = index;
          }

          // Check if output transform is present in the final chain
          if (!passIds.contains('output_display_transform')) {
            issues.add(
              ColorQaIssue(
                id: 'NATIVE_PASS_OUTPUT_MISSING',
                severity: ColorQaSeverity.releaseBlocker,
                area: ColorQaArea.hdrOutput,
                title: 'Output transform pass missing',
                message: "No display transform pass exists in the final chain for clip '${clip.name}'.",
                suggestedFix: 'Add output display transform pass as the final pass.',
              ),
            );
          }
        }
      }
    }

    // 2. Validate HDR project configuration safety
    final isHdr = graph.exportHints.isHdrOutput;
    final hdrOutput = graph.hdrOutput;
    if (isHdr && hdrOutput == null) {
      issues.add(
        const ColorQaIssue(
          id: 'NATIVE_PASS_OUTPUT_MISSING',
          severity: ColorQaSeverity.releaseBlocker,
          area: ColorQaArea.hdrOutput,
          title: 'Output transform pass missing',
          message: 'HDR output is enabled in export hints but no HDR output settings are configured.',
          suggestedFix: 'Add NleHdrOutputTransformPass as the final pass.',
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
