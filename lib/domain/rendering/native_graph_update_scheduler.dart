import 'dart:async';

import 'package:nle_editor/domain/rendering/multitrack_render_graph_service.dart';
import 'package:nle_editor/domain/rendering/render_graph_validator.dart';
import 'package:nle_editor/native_bridge/native_command_service.dart';

class NativeGraphUpdateScheduler {
  final MultitrackRenderGraphService renderGraphService;
  final RenderGraphValidator validator;
  final NativeCommandService nativeCommandService;

  Timer? _debounce;

  NativeGraphUpdateScheduler({
    required this.renderGraphService,
    required this.validator,
    required this.nativeCommandService,
  });

  void dispose() {
    _debounce?.cancel();
  }

  Future<void> updateNow({
    required String projectId,
    required String reason,
  }) async {
    final graph = await renderGraphService.buildGraph(projectId);
    final validation = validator.validate(graph);

    if (!validation.isValid) {
      final errors = validation.issues
          .where((issue) => issue.isError)
          .map((issue) => '${issue.code}: ${issue.message}')
          .join('\n');

      throw StateError('RenderGraph validation failed:\n$errors');
    }

    await nativeCommandService.updateRenderGraph(
      projectId: projectId,
      renderGraphJson: graph.toJsonString(),
      reason: reason,
    );
  }

  void schedule({
    required String projectId,
    required String reason,
    Duration delay = const Duration(milliseconds: 120),
  }) {
    _debounce?.cancel();

    _debounce = Timer(delay, () {
      updateNow(
        projectId: projectId,
        reason: reason,
      );
    });
  }
}
