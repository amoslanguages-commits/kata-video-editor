import 'dart:convert';

class NativeEventTypes {
  NativeEventTypes._();

  static const String commandAccepted = 'command_accepted';
  static const String commandRejected = 'command_rejected';

  // ── Engine lifecycle ────────────────────────────────────────────────────
  static const String engineReady    = 'engine_ready';
  static const String engineDisposed = 'engine_disposed';

  // ── Graph ────────────────────────────────────────────────────────────────
  static const String graphLoaded    = 'graph_loaded';
  static const String graphUpdated   = 'graph_updated';
  static const String graphValidated = 'graph_validated';

  static const String renderGraphLoaded  = 'render_graph_loaded';
  static const String renderGraphUpdated = 'render_graph_updated';

  static const String playbackTime    = 'playback_time';
  static const String playbackStarted = 'playback_started';
  static const String playbackPaused  = 'playback_paused';
  static const String playheadChanged = 'playhead_changed';
  static const String previewReady    = 'preview_ready';

  static const String jobQueued = 'job_queued';
  static const String jobStarted = 'job_started';
  static const String jobProgress = 'job_progress';
  static const String jobCompleted = 'job_completed';
  static const String jobFailed = 'job_failed';
  static const String jobCancelled = 'job_cancelled';

  static const String proxyStarted = 'proxy_started';
  static const String proxyProgress = 'proxy_progress';
  static const String proxyCompleted = 'proxy_completed';
  static const String proxyFailed = 'proxy_failed';
  static const String proxyCancelled = 'proxy_cancelled';

  static const String exportStarted   = 'export_started';
  static const String exportProgress  = 'export_progress';
  static const String exportCompleted = 'export_completed';
  static const String exportFailed    = 'export_failed';
  static const String exportCancelled = 'export_cancelled';

  static const String missingFile = 'missing_file';
  static const String decoderError = 'decoder_error';
  static const String memoryWarning = 'memory_warning';
  static const String thermalWarning = 'thermal_warning';
  static const String engineError = 'engine_error';
  static const String deviceCapabilities = 'device_capabilities';

  static const String previewSurfaceReady    = 'preview_surface_ready';
  static const String previewSurfaceAttached = 'preview_surface_attached';
  static const String previewSurfaceResized  = 'preview_surface_resized';
  static const String previewSurfaceDisposed = 'preview_surface_disposed';
  static const String previewFrameRendered   = 'preview_frame_rendered';

  static const String audioEngineStateChanged = 'audio_engine_state_changed';
  static const String playbackEnded           = 'playback_ended';

  static const String gpuPreviewFrameRendered = 'gpu_preview_frame_rendered';

  static const String hdrDeviceCapability = 'hdr_device_capability';
  static const String hdrExportValidation = 'hdr_export_validation';
}

class NativeEvent {
  final String id;
  final String type;
  final String? projectId;
  final String? commandId;
  final String? jobId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const NativeEvent({
    required this.id,
    required this.type,
    this.projectId,
    this.commandId,
    this.jobId,
    required this.payload,
    required this.createdAt,
  });

  factory NativeEvent.fromJson(Map<String, dynamic> json) {
    return NativeEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      projectId: json['projectId'] as String?,
      commandId: json['commandId'] as String?,
      jobId: json['jobId'] as String?,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'projectId': projectId,
      'commandId': commandId,
      'jobId': jobId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
