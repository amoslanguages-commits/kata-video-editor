import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/qa/multitrack_qa_models.dart';
import 'package:nle_editor/domain/qa/multitrack_qa_runner.dart';
import 'package:nle_editor/presentation/providers/multitrack_render_graph_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';

final multitrackQaRunnerProvider = Provider<MultitrackQaRunner>((ref) {
  return const MultitrackQaRunner();
});

final projectMultitrackQaReportProvider =
    FutureProvider.family<MultitrackQaReport, String>((ref, projectId) async {
  final timeline = await ref.watch(projectTimelineOnceProvider(projectId).future);
  final graph = await ref.watch(projectRenderGraphProvider(projectId).future);
  final runner = ref.watch(multitrackQaRunnerProvider);

  return runner.run(
    projectId: projectId,
    timeline: timeline,
    graph: graph,
  );
});
