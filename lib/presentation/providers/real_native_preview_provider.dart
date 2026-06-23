import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/preview/native_preview_command_builder.dart';
import 'package:nle_editor/domain/preview/native_preview_session.dart';
import 'package:nle_editor/native_bridge/native_event.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final realNativePreviewProvider = StateNotifierProvider.family<
    RealNativePreviewController, NativePreviewSessionState, String>(
  (ref, projectId) {
    final controller = RealNativePreviewController(ref: ref, projectId: projectId);
    ref.onDispose(controller.close);
    return controller;
  },
);

class RealNativePreviewController extends StateNotifier<NativePreviewSessionState> {
  final Ref ref;
  final _commands = const NativePreviewCommandBuilder();
  StreamSubscription<NativeEvent>? _sub;

  RealNativePreviewController({required this.ref, required String projectId})
      : super(NativePreviewSessionState(projectId: projectId)) {
    _sub = ref.read(nativeBridgeProvider).events.listen(_onEvent);
  }

  Future<void> prepare() async {
    try {
      state = state.copyWith(phase: NativePreviewSessionPhase.preparing, clearError: true);
      final graph = await ref.read(renderGraphServiceProvider).buildProjectGraph(state.projectId);
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
      if (!result.accepted) throw StateError(result.message ?? 'Native preview prepare failed.');
    } catch (error) {
      _error(error);
    }
  }

  Future<void> requestFrame(int timelineMicros) async {
    try {
      final result = await ref.read(nativeBridgeProvider).sendCommand(
            _commands.renderFrame(monitorId: state.monitorId, timelineMicros: timelineMicros),
          );
      if (!result.accepted) throw StateError(result.message ?? 'Native preview frame failed.');
    } catch (error) {
      _error(error);
    }
  }

  Future<void> play() async {
    try {
      final result = await ref.read(nativeBridgeProvider).sendCommand(
            _commands.play(monitorId: state.monitorId, fromMicros: state.playheadMicros),
          );
      if (!result.accepted) throw StateError(result.message ?? 'Native preview play failed.');
      state = state.copyWith(phase: NativePreviewSessionPhase.playing, clearError: true);
    } catch (error) {
      _error(error);
    }
  }

  Future<void> pause() async {
    try {
      final result = await ref.read(nativeBridgeProvider).sendCommand(
            _commands.pause(monitorId: state.monitorId),
          );
      if (!result.accepted) throw StateError(result.message ?? 'Native preview pause failed.');
      state = state.copyWith(phase: NativePreviewSessionPhase.paused, clearError: true);
    } catch (error) {
      _error(error);
    }
  }

  Future<void> stop() async {
    try {
      final result = await ref.read(nativeBridgeProvider).sendCommand(
            _commands.stop(monitorId: state.monitorId),
          );
      if (!result.accepted) throw StateError(result.message ?? 'Native preview stop failed.');
      state = state.copyWith(phase: NativePreviewSessionPhase.stopped, clearError: true);
    } catch (error) {
      _error(error);
    }
  }

  void _onEvent(NativeEvent event) {
    final monitorId = event.payload['monitorId']?.toString();
    if (monitorId != null && monitorId != state.monitorId) return;

    if (event.type == NativeEventTypes.previewTextureReady) {
      state = state.copyWith(
        phase: NativePreviewSessionPhase.ready,
        surfaceId: _int(event.payload['textureId']),
        surfaceWidth: _int(event.payload['width']),
        surfaceHeight: _int(event.payload['height']),
        clearError: true,
      );
      return;
    }

    if (event.type == NativeEventTypes.previewFrameRendered) {
      state = state.copyWith(
        phase: state.phase == NativePreviewSessionPhase.playing
            ? NativePreviewSessionPhase.playing
            : NativePreviewSessionPhase.ready,
        playheadMicros: _int(event.payload['timelineTimeUs']) ?? state.playheadMicros,
        clearError: true,
      );
      return;
    }

    if (event.type == NativeEventTypes.previewError) {
      _error(event.payload['message']?.toString() ?? 'Native preview error.');
      return;
    }

    if (event.type == NativeEventTypes.previewEnded) {
      state = state.copyWith(
        phase: NativePreviewSessionPhase.stopped,
        clearError: true,
      );
    }
  }

  int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  void _error(Object error) {
    state = state.copyWith(
      phase: NativePreviewSessionPhase.error,
      errorMessage: error.toString(),
    );
  }

  void close() {
    _sub?.cancel();
    _sub = null;
  }
}
