import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/native_bridge/native_true_preview_service.dart';
import 'package:nle_editor/presentation/controllers/native_true_preview_controller.dart';
import 'package:nle_editor/presentation/providers/multitrack_render_graph_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final nativeTruePreviewServiceProvider =
    Provider<NativeTruePreviewService>((ref) {
  final service = NativeTruePreviewService(
    bridge: ref.watch(nativeBridgeProvider),
  );

  ref.onDispose(service.dispose);

  return service;
});

final nativeTruePreviewControllerProvider =
    StateNotifierProvider.family<
        NativeTruePreviewController,
        TruePreviewUiState,
        String>((ref, projectId) {
  return NativeTruePreviewController(
    projectId: projectId,
    previewService: ref.watch(nativeTruePreviewServiceProvider),
    renderGraphService: ref.watch(multitrackRenderGraphServiceProvider),
  );
});
