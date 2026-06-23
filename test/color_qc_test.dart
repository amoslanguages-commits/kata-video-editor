// test/color_qc_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/color_qc/color_qc_models.dart';
import 'package:nle_editor/domain/color_qc/color_identity_validator.dart';
import 'package:nle_editor/domain/color_qc/color_pass_order_validator.dart';
import 'package:nle_editor/domain/color_qc/render_graph_color_validator.dart';
import 'package:nle_editor/domain/color_qc/color_project_compatibility_validator.dart';

void main() {
  group('Color QA Validators Unit Tests', () {
    late RenderGraphDto mockGraph;

    setUp(() {
      mockGraph = RenderGraphDto(
        schema: 'nle.render_graph',
        version: 2,
        source: 'test_suite',
        project: const RenderGraphProjectDto(
          id: 'test_project',
          name: 'QA Test Project',
          durationMicros: 5000000,
          width: 1920,
          height: 1080,
          frameRate: 24.0,
          aspectRatio: '16:9',
        ),
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
        exportHints: const RenderGraphExportHintsDto(
          useProxyForPreview: false,
          useOriginalForExport: true,
          requiresGpuCompositor: true,
          containsText: false,
          containsImage: false,
          containsVideo: false,
          containsAudio: false,
          containsAdjustment: false,
          containsColorAdjustments: false,
          containsCrop: false,
          containsSpeedChanges: false,
          containsFades: false,
          containsLut: false,
          containsPrimaryGrades: false,
          containsColorCurves: false,
          containsSecondaryGrades: false,
          containsFilmLooks: false,
          outputMode: 'rec709Sdr',
          isHdrOutput: false,
          isWideColorOutput: false,
          requiresTenBit: false,
        ),
        colorPipeline: const RenderGraphColorPipelineDto(
          enabled: true,
          quality: 'high',
          defaultInput: {},
          working: {},
          previewOutput: {},
          exportOutput: {},
          forceCompatibilityMode: false,
          previewMatchesExport: true,
          assetInputTransforms: {},
        ),
      );
    });

    test('ColorIdentityValidator reports no issues on neutral graph', () {
      const validator = ColorIdentityValidator();
      final report = validator.validate(mockGraph);
      expect(report.passed, isTrue);
      expect(report.issues, isEmpty);
    });

    test('ColorPassOrderValidator detects incorrect custom pass sequence', () {
      final badOrderGraph = RenderGraphDto(
        schema: mockGraph.schema,
        version: mockGraph.version,
        source: mockGraph.source,
        project: mockGraph.project,
        assets: mockGraph.assets,
        tracks: mockGraph.tracks,
        composition: mockGraph.composition,
        audioMix: mockGraph.audioMix,
        exportHints: mockGraph.exportHints,
        colorPipeline: mockGraph.colorPipeline,
        metadata: const {
          'simulatedPassIds': [
            'input_to_scene_linear',
            'color_curves', // curves before primary is wrong
            'primary_grade',
            'output_display_transform'
          ]
        },
      );

      const validator = ColorPassOrderValidator();
      final report = validator.validate(badOrderGraph);

      expect(report.passed, isFalse);
      expect(report.issues.any((i) => i.id == 'NATIVE_PASS_BAD_ORDER_primary_grade'), isTrue);
    });

    test('RenderGraphColorValidator warns on missing color pipeline DTO', () {
      final missingPipelineGraph = RenderGraphDto(
        schema: mockGraph.schema,
        version: mockGraph.version,
        source: mockGraph.source,
        project: mockGraph.project,
        assets: mockGraph.assets,
        tracks: mockGraph.tracks,
        composition: mockGraph.composition,
        audioMix: mockGraph.audioMix,
        exportHints: mockGraph.exportHints,
        colorPipeline: null,
      );

      const validator = RenderGraphColorValidator();
      final report = validator.validate(missingPipelineGraph);

      expect(report.passed, isTrue); // Warnings do not block pass
      expect(report.issues.any((i) => i.id == 'color_pipeline_missing'), isTrue);
    });

    test('ColorProjectCompatibilityValidator handles missing JSON values', () {
      const validator = ColorProjectCompatibilityValidator();
      final report = validator.validate(mockGraph);
      expect(report.passed, isTrue);
      expect(report.issues.any((i) => i.id == 'legacy_compatibility_crash'), isFalse);
    });
  });
}
