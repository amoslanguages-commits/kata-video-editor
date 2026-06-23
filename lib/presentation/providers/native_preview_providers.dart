import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/preview/native_preview_session.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final nativePreviewSessionProvider = StateNotifierProvider.family<
    NativePreviewSessionController, NativePreviewSessionState, String>(
  (ref, projectId) {
    return NativePreviewSessionController(
      ref: ref,
      projectId: projectId,
    );
  },
);

class NativePreviewSessionController
    extends StateNotifier<NativePreviewSessionState> {
  final Ref ref;

  NativePreviewSessionController({
    required this.ref,
    required String projectId,
  }) : super(NativePreviewSessionState(projectId: projectId));

  Future<void> markPreparing() async {
    state = state.copyWith(
      phase: NativePreviewSessionPhase.preparing,
      clearError: true,
    );
  }

  Future<void> markReady() async {
    state = state.copyWith(
      phase: NativePreviewSessionPhase.ready,
      clearError: true,
    );
  }

  Future<void> markPlaying() async {
    state = state.copyWith(
      phase: NativePreviewSessionPhase.playing,
      clearError: true,
    );
  }

  Future<void> markPaused() async {
    state = state.copyWith(
      phase: NativePreviewSessionPhase.paused,
      clearError: true,
    );
  }

  Future<void> markStopped() async {
    state = state.copyWith(
      phase: NativePreviewSessionPhase.stopped,
      clearError: true,
    );
  }

  void markError(Object error) {
    state = state.copyWith(
      phase: NativePreviewSessionPhase.error,
      errorMessage: error.toString(),
    );
  }

  void setPlayhead(int timelineMicros) {
    state = state.copyWith(playheadMicros: timelineMicros);
  }

  void setPreviewOptions({
    String? qualityMode,
    bool? preferProxy,
    int? maxPreviewWidth,
    int? maxPreviewHeight,
  }) {
    state = state.copyWith(
      qualityMode: qualityMode,
      preferProxy: preferProxy,
      maxPreviewWidth: maxPreviewWidth,
      maxPreviewHeight: maxPreviewHeight,
    );
  }
}

final nativePreviewBridgeProvider = Provider((ref) {
  return ref.watch(nativeBridgeProvider);
});

final nativePreviewRenderGraphProvider = Provider((ref) {
  return ref.watch(renderGraphServiceProvider);
});
