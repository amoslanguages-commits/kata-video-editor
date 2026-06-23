// lib/native_bridge/native_preview_events.dart
//
// 29F: All preview events now carry [monitor] so each controller
// can filter events belonging to its own preview instance.

import 'package:nle_editor/domain/preview/preview_monitor.dart';
import 'package:nle_editor/domain/color/gpu_color_pipeline_models.dart';

sealed class NativePreviewEvent {
  final PreviewMonitor monitor;
  const NativePreviewEvent({required this.monitor});
}

class PreviewTextureReadyEvent extends NativePreviewEvent {
  final int textureId;
  final int width;
  final int height;

  const PreviewTextureReadyEvent({
    required super.monitor,
    required this.textureId,
    required this.width,
    required this.height,
  });
}

class PreviewFrameRenderedEvent extends NativePreviewEvent {
  final int timelineTimeMicros;

  const PreviewFrameRenderedEvent({
    required super.monitor,
    required this.timelineTimeMicros,
  });
}

class PreviewDroppedFrameEvent extends NativePreviewEvent {
  final int timelineTimeMicros;
  final String reason;

  const PreviewDroppedFrameEvent({
    required super.monitor,
    required this.timelineTimeMicros,
    required this.reason,
  });
}

class PreviewEndedEvent extends NativePreviewEvent {
  const PreviewEndedEvent({required super.monitor});
}

class PreviewErrorEvent extends NativePreviewEvent {
  final String message;

  const PreviewErrorEvent({
    required super.monitor,
    required this.message,
  });
}

class ColorPipelineStatsEvent extends NativePreviewEvent {
  final ColorPipelineStats stats;

  const ColorPipelineStatsEvent({
    required super.monitor,
    required this.stats,
  });
}
