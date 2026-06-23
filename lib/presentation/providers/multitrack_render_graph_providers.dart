import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/rendering/multitrack_render_graph_service.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_validator.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/film_look_providers.dart';
import 'package:nle_editor/presentation/providers/lut_providers.dart';
import 'package:nle_editor/presentation/providers/primary_grade_providers.dart';
import 'package:nle_editor/presentation/providers/color_curve_providers.dart';
import 'package:nle_editor/presentation/providers/secondary_grade_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/hdr_output_providers.dart';

final multitrackRenderGraphServiceProvider =
    Provider<MultitrackRenderGraphService>((ref) {
  final database = ref.watch(databaseProvider);
  final timelineRepository = ref.watch(multitrackTimelineRepositoryProvider);
  final lutRepository = ref.watch(lutRepositoryProvider);
  final primaryGradeRepository = ref.watch(primaryGradeRepositoryProvider);
  final colorCurveRepository = ref.watch(colorCurveRepositoryProvider);
  final secondaryGradeRepository = ref.watch(secondaryGradeRepositoryProvider);
  final filmLookRepository = ref.watch(filmLookRepositoryProvider);
  final hdrOutputRepository = ref.watch(hdrOutputRepositoryProvider);

  return MultitrackRenderGraphService(
    database: database,
    timelineRepository: timelineRepository,
    lutRepository: lutRepository,
    primaryGradeRepository: primaryGradeRepository,
    colorCurveRepository: colorCurveRepository,
    secondaryGradeRepository: secondaryGradeRepository,
    filmLookRepository: filmLookRepository,
    hdrOutputRepository: hdrOutputRepository,
  );
});

final renderGraphValidatorProvider = Provider<RenderGraphValidator>((ref) {
  return const RenderGraphValidator();
});

final projectRenderGraphProvider =
    FutureProvider.family<RenderGraphDto, String>((ref, projectId) async {
  final service = ref.watch(multitrackRenderGraphServiceProvider);
  final autoDucking = ref.watch(autoDuckingProvider);
  return service.buildGraph(projectId, autoDuckingEnabled: autoDucking);
});

final projectRenderGraphJsonProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
  final service = ref.watch(multitrackRenderGraphServiceProvider);
  final autoDucking = ref.watch(autoDuckingProvider);
  return service.buildGraphJson(projectId, autoDuckingEnabled: autoDucking);
});

final projectRenderGraphValidationProvider =
    FutureProvider.family<RenderGraphValidationResult, String>(
  (ref, projectId) async {
    final graph = await ref.watch(projectRenderGraphProvider(projectId).future);
    final validator = ref.watch(renderGraphValidatorProvider);
    return validator.validate(graph);
  },
);
