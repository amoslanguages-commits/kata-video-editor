// lib/presentation/controllers/native_true_preview_controller.dart
//
// 29F: Program monitor. All service calls carry monitor: PreviewMonitor.program.
// Events from the source monitor are silently ignored.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/preview/preview_monitor.dart';
import 'package:nle_editor/domain/rendering/multitrack_render_graph_service.dart';
import 'package:nle_editor/native_bridge/native_preview_events.dart';
import 'package:nle_editor/native_bridge/native_true_preview_service.dart';

enum TruePreviewUiStatus {
  idle,
  preparing,
  ready,
  playing,
  paused,
  error,
}

class TruePreviewUiState {
  final TruePreviewUiStatus status;
  final int? textureId;
  final int width;
  final int height;
  final int lastRenderedMicros;
  final int droppedFrames;
  final String? errorMessage;

  const TruePreviewUiState({
    required this.status,
    this.textureId,
    this.width = 0,
    this.height = 0,
    this.lastRenderedMicros = 0,
    this.droppedFrames = 0,
    this.errorMessage,
  });

  const TruePreviewUiState.initial()
      : status = TruePreviewUiStatus.idle,
        textureId = null,
        width = 0,
        height = 0,
        lastRenderedMicros = 0,
        droppedFrames = 0,
        errorMessage = null;

  bool get hasTexture => textureId != null && textureId! >= 0;

  TruePreviewUiState copyWith({
    TruePreviewUiStatus? status,
    int? textureId,
    int? width,
    int? height,
    int? lastRenderedMicros,
    int? droppedFrames,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TruePreviewUiState(
      status: status ?? this.status,
      textureId: textureId ?? this.textureId,
      width: width ?? this.width,
      height: height ?? this.height,
      lastRenderedMicros: lastRenderedMicros ?? this.lastRenderedMicros,
      droppedFrames: droppedFrames ?? this.droppedFrames,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class NativeTruePreviewController
    extends StateNotifier<TruePreviewUiState> {
  final String projectId;
  final NativeTruePreviewService previewService;
  final MultitrackRenderGraphService renderGraphService;

  StreamSubscription<NativePreviewEvent>? _eventSub;

  NativeTruePreviewController({
    required this.projectId,
    required this.previewService,
    required this.renderGraphService,
  }) : super(const TruePreviewUiState.initial()) {
    _eventSub = previewService.events.listen(_handleEvent);
  }

  Future<void> prepare({
    NativePreviewQualityMode qualityMode = NativePreviewQualityMode.auto,
  }) async {
    state = state.copyWith(
      status: TruePreviewUiStatus.preparing,
      clearError: true,
    );

    final json = await renderGraphService.buildGraphJsonString(projectId);

    await previewService.prepare(
      monitor: PreviewMonitor.program,
      projectId: projectId,
      renderGraphJson: json,
      qualityMode: qualityMode,
      preferProxy: true,
      maxPreviewWidth: 1280,
      maxPreviewHeight: 720,
    );
  }

  Future<void> refreshGraphAndRender({
    required int timelineTimeMicros,
  }) async {
    final json = await renderGraphService.buildGraphJsonString(projectId);

    await previewService.prepare(
      monitor: PreviewMonitor.program,
      projectId: projectId,
      renderGraphJson: json,
      qualityMode: NativePreviewQualityMode.auto,
      preferProxy: true,
    );

    await renderFrame(timelineTimeMicros);
  }

  Future<void> renderFrame(int timelineTimeMicros) {
    return previewService.renderFrame(
      monitor: PreviewMonitor.program,
      timelineTimeMicros: timelineTimeMicros,
    );
  }

  Future<void> playFrom(int timelineTimeMicros) async {
    state = state.copyWith(status: TruePreviewUiStatus.playing);

    await previewService.play(
      monitor: PreviewMonitor.program,
      fromTimelineTimeMicros: timelineTimeMicros,
    );
  }

  Future<void> pause() async {
    state = state.copyWith(status: TruePreviewUiStatus.paused);
    await previewService.pause(monitor: PreviewMonitor.program);
  }

  Future<void> stop() async {
    state = state.copyWith(status: TruePreviewUiStatus.paused);
    await previewService.stop(monitor: PreviewMonitor.program);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    previewService.disposePreview(monitor: PreviewMonitor.program);
    super.dispose();
  }

  // ── Event handling (program monitor only) ────────────────────────────────

  void _handleEvent(NativePreviewEvent event) {
    // Ignore events from the source monitor.
    if (event.monitor != PreviewMonitor.program) return;

    switch (event) {
      case PreviewTextureReadyEvent():
        state = state.copyWith(
          status: TruePreviewUiStatus.ready,
          textureId: event.textureId,
          width: event.width,
          height: event.height,
          clearError: true,
        );
        break;

      case PreviewFrameRenderedEvent():
        state = state.copyWith(
          lastRenderedMicros: event.timelineTimeMicros,
          clearError: true,
        );
        break;

      case PreviewDroppedFrameEvent():
        state = state.copyWith(
          droppedFrames: state.droppedFrames + 1,
        );
        break;

      case PreviewEndedEvent():
        state = state.copyWith(
          status: TruePreviewUiStatus.paused,
        );
        break;

      case PreviewErrorEvent():
        state = state.copyWith(
          status: TruePreviewUiStatus.error,
          errorMessage: event.message,
        );
        break;

      case ColorPipelineStatsEvent():
        // Handled by ColorPipelineStatsController
        break;
    }
  }
}
