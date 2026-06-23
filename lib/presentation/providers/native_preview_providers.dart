import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/preview/native_preview_command_builder.dart';
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
  final NativePreviewCommandBuilder _commands = const NativePreviewCommandBuilder();

  NativePreviewSessionController({
    required this.ref,
    required String projectId,
  }) : super(NativePreviewSessionState(projectId: projectId));

  Future<void> prepare() async {
    try {
      state = state.copyWith(
        phase: NativePreviewSessionPhase.preparing,
        clearError: true,
      );
      final graph = await ref
          .read(renderGraphServiceProvider)
          .buildProjectGraph(state.projectId);
      final result = await ref.read(nativeBridgeProvider).sendCommand(
            _commands.prepare(
              projectId: state.projectId,
              monitorId: state.monitorId,
              renderGraphJson: graph,
              qualityMode: state.qualityMode,
              preferProxy: state.preferProxy,
              maxPreviewWidth: state.maxPreviewWidth,
              maxPreviewHeight: state.maxPreviewHeight,
            ),
          );
      if (!result.accepted) {
        throw StateError(result.message ?? 'Native preview prepare failed.');
      }
      state = state.copyWith(
        phase: NativePreviewSessionPhase.ready,
        clearError: true,
      );
    } catch (error) {
      markError(error);
    }
  }

  Future<void> renderFrame(int timelineMicros) async {
    try {
      final result = await ref.read(nativeBridgeProvider).sendCommand(
            _commands.renderFrame(
              monitorId: state.monitorId,
              timelineMicros: timelineMicros,
            ),
          );
      if (!result.accepted) {
        throw StateError(result.message ?? 'Native preview frame failed.');
      }
      state = state.copyWith(
        phase: state.isPrepared ? state.phase : NativePreviewSessionPhase.ready,
        playheadMicros: timelineMicros,
        clearError: true,
      );
    } catch (error) {
      markError(error);
    }
  }

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
