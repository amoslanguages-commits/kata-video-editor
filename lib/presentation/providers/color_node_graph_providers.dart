import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/color_node_graph_repository.dart';
import 'package:nle_editor/domain/color_nodes/color_node_models.dart';
import 'package:nle_editor/domain/color_nodes/mobile_color_stack_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final colorNodeGraphRepositoryProvider =
    Provider<ColorNodeGraphRepository>((ref) {
  return ColorNodeGraphRepository(
    database: ref.watch(databaseProvider),
  );
});

final clipColorNodeGraphProvider =
    FutureProvider.family<NleColorNodeGraph, String>((ref, clipId) {
  return ref.watch(colorNodeGraphRepositoryProvider).getClipGraph(clipId);
});

final clipMobileColorStackProvider =
    FutureProvider.family<NleMobileColorStack, String>((ref, clipId) async {
  final graph = await ref.watch(colorNodeGraphRepositoryProvider).getClipGraph(
        clipId,
      );

  return NleMobileColorStack.fromGraph(graph);
});

final timelineColorNodeGraphProvider =
    FutureProvider.family<NleColorNodeGraph, String>((ref, projectId) {
  return ref.watch(colorNodeGraphRepositoryProvider).getTimelineGraph(projectId);
});

final projectOutputColorNodeGraphProvider =
    FutureProvider.family<NleColorNodeGraph, String>((ref, projectId) {
  return ref
      .watch(colorNodeGraphRepositoryProvider)
      .getProjectOutputGraph(projectId);
});
