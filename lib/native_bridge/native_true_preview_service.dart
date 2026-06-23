// lib/native_bridge/native_true_preview_service.dart
//
// 29F: All preview commands now carry [monitor] so the Android
// dual preview manager can route each call to the right instance.

import 'dart:async';

import 'package:nle_editor/domain/preview/preview_monitor.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_command.dart';
import 'package:nle_editor/native_bridge/native_event.dart';
import 'package:nle_editor/native_bridge/native_preview_events.dart';
import 'package:nle_editor/domain/color/gpu_color_pipeline_models.dart';

enum NativePreviewQualityMode {
  auto,
  performance,
  balanced,
  quality,
}

extension NativePreviewQualityModeX on NativePreviewQualityMode {
  String get commandValue {
    switch (this) {
      case NativePreviewQualityMode.auto:
        return 'auto';
      case NativePreviewQualityMode.performance:
        return 'performance';
      case NativePreviewQualityMode.balanced:
        return 'balanced';
      case NativePreviewQualityMode.quality:
        return 'quality';
    }
  }
}

class NativeTruePreviewService {
  final NativeBridgeContract bridge;

  final _events = StreamController<NativePreviewEvent>.broadcast();

  NativeTruePreviewService({
    required this.bridge,
  }) {
    bridge.events.listen(_handleNativeEvent);
  }

  Stream<NativePreviewEvent> get events => _events.stream;

  // ── Commands ────────────────────────────────────────────────────────────

  Future<void> prepare({
    required PreviewMonitor monitor,
    required String projectId,
    required String renderGraphJson,
    NativePreviewQualityMode qualityMode = NativePreviewQualityMode.auto,
    bool preferProxy = true,
    int maxPreviewWidth = 1280,
    int maxPreviewHeight = 720,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.prepareTruePreview,
        projectId: projectId,
        payload: {
          'monitorId': monitor.commandValue,
          'projectId': projectId,
          'renderGraphJson': renderGraphJson,
          'qualityMode': qualityMode.commandValue,
          'preferProxy': preferProxy,
          'maxPreviewWidth': maxPreviewWidth,
          'maxPreviewHeight': maxPreviewHeight,
        },
      ),
    );
  }

  Future<void> renderFrame({
    required PreviewMonitor monitor,
    required int timelineTimeMicros,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.renderPreviewFrame,
        payload: {
          'monitorId': monitor.commandValue,
          'timelineTimeUs': timelineTimeMicros,
        },
      ),
    );
  }

  Future<void> play({
    required PreviewMonitor monitor,
    required int fromTimelineTimeMicros,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.startTruePreview,
        payload: {
          'monitorId': monitor.commandValue,
          'fromTimelineTimeUs': fromTimelineTimeMicros,
        },
      ),
    );
  }

  Future<void> pause({
    required PreviewMonitor monitor,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.pauseTruePreview,
        payload: {
          'monitorId': monitor.commandValue,
        },
      ),
    );
  }

  Future<void> stop({
    required PreviewMonitor monitor,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.stopTruePreview,
        payload: {
          'monitorId': monitor.commandValue,
        },
      ),
    );
  }

  Future<void> disposePreview({
    required PreviewMonitor monitor,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.disposeTruePreview,
        payload: {
          'monitorId': monitor.commandValue,
        },
      ),
    );
  }

  Future<void> disposeAllPreviews() {
    return bridge.sendCommand(
      NativeCommand(
        type: 'dispose_all_previews',
        payload: const {},
      ),
    );
  }

  void dispose() {
    _events.close();
  }

  // ── Event parsing ────────────────────────────────────────────────────────

  void _handleNativeEvent(NativeEvent event) {
    final monitor = PreviewMonitorX.fromRaw(
      event.payload['monitorId']?.toString(),
    );

    switch (event.type) {
      case 'preview_texture_ready':
        final textureId = _payloadInt(event.payload, 'textureId');
        final width = _payloadInt(event.payload, 'width');
        final height = _payloadInt(event.payload, 'height');
        if (textureId == null || width == null || height == null) return;

        _events.add(
          PreviewTextureReadyEvent(
            monitor: monitor,
            textureId: textureId,
            width: width,
            height: height,
          ),
        );
        break;

      case 'preview_frame_rendered':
        final timelineTimeMicros = _payloadInt(
          event.payload,
          'timelineTimeUs',
          fallbackKey: 'timelineTimeMicros',
        );
        if (timelineTimeMicros == null) return;

        _events.add(
          PreviewFrameRenderedEvent(
            monitor: monitor,
            timelineTimeMicros: timelineTimeMicros,
          ),
        );
        break;

      case 'preview_dropped_frame':
        final timelineTimeMicros = _payloadInt(
          event.payload,
          'timelineTimeUs',
          fallbackKey: 'timelineTimeMicros',
        );

        _events.add(
          PreviewDroppedFrameEvent(
            monitor: monitor,
            timelineTimeMicros: timelineTimeMicros ?? 0,
            reason:
                event.payload['reason']?.toString() ?? 'Dropped frame',
          ),
        );
        break;

      case 'preview_ended':
        _events.add(PreviewEndedEvent(monitor: monitor));
        break;

      case 'preview_error':
        _events.add(
          PreviewErrorEvent(
            monitor: monitor,
            message: event.payload['message']?.toString() ?? 'Preview error',
          ),
        );
        break;

      case 'color_pipeline_stats':
        _events.add(
          ColorPipelineStatsEvent(
            monitor: monitor,
            stats: ColorPipelineStats.fromJson(
              Map<String, dynamic>.from(event.payload),
            ),
          ),
        );
        break;
    }
  }

  int? _payloadInt(
    Map<String, dynamic> payload,
    String key, {
    String? fallbackKey,
  }) {
    final value = payload[key] ?? (fallbackKey == null ? null : payload[fallbackKey]);
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
