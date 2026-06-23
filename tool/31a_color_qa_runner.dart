// tool/31a_color_qa_runner.dart

import 'dart:convert';
import 'dart:io';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/color_qc/color_qc_models.dart';
import 'package:nle_editor/domain/color_qc/color_identity_validator.dart';
import 'package:nle_editor/domain/color_qc/color_pass_order_validator.dart';
import 'package:nle_editor/domain/color_qc/render_graph_color_validator.dart';
import 'package:nle_editor/domain/color_qc/color_project_compatibility_validator.dart';

void main() async {
  print('======================================================================');
  print('          31A-QA: Color Pipeline Quality Assurance Runner             ');
  print('======================================================================');

  final file = File('tool/31a_color_pipeline_test_cases.json');
  if (!await file.exists()) {
    print('Error: tool/31a_color_pipeline_test_cases.json not found!');
    exit(1);
  }

  final content = await file.readAsString();
  final Map<String, dynamic> data = jsonDecode(content);
  final List<dynamic> cases = data['testCases'] ?? [];

  print('Loaded ${cases.length} test scenarios.');
  print('----------------------------------------------------------------------');

  var allPassed = true;

  for (final testCase in cases) {
    final name = testCase['name'] as String;
    final desc = testCase['description'] as String;
    final graphMap = testCase['graph'] as Map<String, dynamic>;

    print('Running test case: "$name"');
    print('Description: $desc');

    final graph = _parseGraph(graphMap);
    final report = _runValidators(graph);

    print('Status: ${report.passed ? "✅ PASSED" : "❌ FAILED"}');
    print('Total issues: ${report.issues.length}');
    for (final issue in report.issues) {
      print('  - [${issue.severity.name.toUpperCase()}] (${issue.area.name}): ${issue.title} - ${issue.message}');
      if (issue.suggestedFix != null) {
        print('    Suggested Fix: ${issue.suggestedFix}');
      }
    }

    if (!report.passed) {
      final blockers = report.issues.where((i) => i.severity == ColorQaSeverity.releaseBlocker).toList();
      if (blockers.isNotEmpty) {
        allPassed = false;
      }
    }
    print('----------------------------------------------------------------------');
  }

  if (allPassed) {
    print('🎉 All non-blocker/neutrality tests completed successfully!');
    exit(0);
  } else {
    print('❌ Test failures detected in release-blocker rules. Check reports above.');
    exit(1);
  }
}

RenderGraphDto _parseGraph(Map<String, dynamic> map) {
  final projMap = map['project'] as Map<String, dynamic>? ?? {};
  final project = RenderGraphProjectDto(
    id: projMap['id']?.toString() ?? '',
    name: projMap['name']?.toString() ?? '',
    durationMicros: (projMap['durationMicros'] as num?)?.toInt() ?? 0,
    width: (projMap['width'] as num?)?.toInt() ?? 0,
    height: (projMap['height'] as num?)?.toInt() ?? 0,
    frameRate: (projMap['frameRate'] as num?)?.toDouble() ?? 30.0,
    aspectRatio: projMap['aspectRatio']?.toString() ?? '16:9',
  );

  final hintsMap = map['exportHints'] as Map<String, dynamic>? ?? {};
  final exportHints = RenderGraphExportHintsDto(
    useProxyForPreview: hintsMap['useProxyForPreview'] == true,
    useOriginalForExport: hintsMap['useOriginalForExport'] != false,
    requiresGpuCompositor: hintsMap['requiresGpuCompositor'] != false,
    containsText: hintsMap['containsText'] == true,
    containsImage: hintsMap['containsImage'] == true,
    containsVideo: hintsMap['containsVideo'] == true,
    containsAudio: hintsMap['containsAudio'] == true,
    containsAdjustment: hintsMap['containsAdjustment'] == true,
    containsColorAdjustments: hintsMap['containsColorAdjustments'] == true,
    containsCrop: hintsMap['containsCrop'] == true,
    containsSpeedChanges: hintsMap['containsSpeedChanges'] == true,
    containsFades: hintsMap['containsFades'] == true,
    containsLut: hintsMap['containsLut'] == true,
    containsPrimaryGrades: hintsMap['containsPrimaryGrades'] == true,
    containsColorCurves: hintsMap['containsColorCurves'] == true,
    containsSecondaryGrades: hintsMap['containsSecondaryGrades'] == true,
    containsFilmLooks: hintsMap['containsFilmLooks'] == true,
    outputMode: hintsMap['outputMode']?.toString() ?? 'rec709Sdr',
    isHdrOutput: hintsMap['isHdrOutput'] == true,
    isWideColorOutput: hintsMap['isWideColorOutput'] == true,
    requiresTenBit: hintsMap['requiresTenBit'] == true,
  );

  final pipelineMap = map['colorPipeline'] as Map<String, dynamic>?;
  final colorPipeline = pipelineMap == null
      ? null
      : RenderGraphColorPipelineDto(
          enabled: pipelineMap['enabled'] != false,
          quality: pipelineMap['quality']?.toString() ?? 'high',
          defaultInput: const {},
          working: const {},
          previewOutput: const {},
          exportOutput: const {},
          assetInputTransforms: const {},
        );

  return RenderGraphDto(
    schema: map['schema']?.toString() ?? '',
    version: (map['version'] as num?)?.toInt() ?? 2,
    source: map['source']?.toString() ?? 'test',
    project: project,
    assets: const [],
    tracks: const [],
    composition: const RenderGraphCompositionDto(
      visualTrackIdsBottomToTop: [],
      enabledVisualTrackIdsBottomToTop: [],
      audioTrackIds: [],
      enabledAudioTrackIds: [],
      hasSoloAudio: false,
      hasHiddenTracks: false,
      visualLayerCount: 0,
      audioLayerCount: 0,
    ),
    audioMix: const RenderGraphAudioMixDto(
      enabled: true,
      hasSoloAudio: false,
      soloAudioTrackIds: [],
      mutedAudioTrackIds: [],
      activeAudioTrackIds: [],
      sampleRate: 48000,
      channels: 2,
    ),
    exportHints: exportHints,
    colorPipeline: colorPipeline,
    metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
  );
}

ColorQaReport _runValidators(RenderGraphDto graph) {
  final issues = <ColorQaIssue>[];

  final validators = [
    const ColorIdentityValidator(),
    const ColorPassOrderValidator(),
    const RenderGraphColorValidator(),
    const ColorProjectCompatibilityValidator(),
  ];

  for (final validator in validators) {
    final report = validator.validate(graph);
    issues.addAll(report.issues);
  }

  final hasErrors = issues.any((i) =>
      i.severity == ColorQaSeverity.error ||
      i.severity == ColorQaSeverity.releaseBlocker);

  return ColorQaReport(
    timestamp: DateTime.now(),
    passed: !hasErrors,
    issues: issues,
  );
}
