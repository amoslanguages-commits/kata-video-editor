import 'dart:convert';

import 'package:uuid/uuid.dart';

class NativeCommandTypes {
  NativeCommandTypes._();

  static const String initialize = 'initialize';
  static const String dispose    = 'destroy_engine'; // legacy alias kept for FakeNativeBridge

  static const String createEngine  = 'create_engine';
  static const String destroyEngine = 'destroy_engine';

  static const String loadRenderGraph     = 'load_render_graph';
  static const String updateRenderGraph   = 'update_render_graph';
  static const String validateRenderGraph = 'validate_render_graph';

  static const String play = 'play';
  static const String pause = 'pause';
  static const String seek = 'seek';

  static const String addClip = 'add_clip';
  static const String moveClip = 'move_clip';
  static const String trimClip = 'trim_clip';
  static const String splitClip = 'split_clip';
  static const String deleteClip = 'delete_clip';

  static const String setTransform = 'set_transform';
  static const String setColor = 'set_color';
  static const String setAudio = 'set_audio';

  static const String addKeyframe = 'add_keyframe';
  static const String updateKeyframe = 'update_keyframe';
  static const String deleteKeyframe = 'delete_keyframe';

  static const String startJob = 'start_job';
  static const String cancelJob = 'cancel_job';

  static const String startProxy              = 'start_proxy';
  static const String startProxyJob           = 'start_proxy_job';
  static const String cancelProxyJob          = 'cancel_proxy_job';
  static const String startExport             = 'start_export';
  static const String startExportJob          = 'start_export_job';
  static const String cancelExportJob         = 'cancel_export_job';
  static const String probeDeviceCapabilities = 'probe_device_capabilities';
  static const String getSessionState         = 'get_session_state';

  static const String createPreviewTexture     = 'create_preview_texture';
  static const String disposePreviewTexture    = 'dispose_preview_texture';
  static const String attachPreviewTexture     = 'attach_preview_texture';
  static const String resizePreviewTexture     = 'resize_preview_texture';
  static const String renderPreviewPlaceholder = 'render_preview_placeholder';

  static const String setPlaybackRate      = 'set_playback_rate';
  static const String getAudioEngineState  = 'get_audio_engine_state';

  static const String addTransition = 'add_transition';
  static const String updateTransition = 'update_transition';
  static const String deleteTransition = 'delete_transition';
  static const String enableTransition = 'enable_transition';
  static const String disableTransition = 'disable_transition';

  static const String renderGpuPreviewFrame = 'render_gpu_preview_frame';

  static const String qaValidateRenderGraph  = 'qa_validate_render_graph';
  static const String qaProbeVisual          = 'qa_probe_visual';
  static const String qaProbeAudio           = 'qa_probe_audio';
  static const String qaRunExportSync        = 'qa_run_export_sync';
  static const String qaRunPreviewSync       = 'qa_run_preview_sync';
  static const String qaClearSyncTelemetry   = 'qa_clear_sync_telemetry';

  // 29E device compatibility QA
  static const String qaRunDeviceCompatibility     = 'qa_run_device_compatibility';
  static const String qaCollectDeviceCapabilities  = 'qa_collect_device_capabilities';
  static const String qaRunMemoryPressureProbe     = 'qa_run_memory_pressure_probe';
  static const String qaExportRecoverySuggestion   = 'qa_export_recovery_suggestion';

  static const String prepareTruePreview = 'prepare_true_preview';
  static const String renderPreviewFrame = 'render_preview_frame';
  static const String startTruePreview   = 'start_true_preview';
  static const String pauseTruePreview   = 'pause_true_preview';
  static const String stopTruePreview    = 'stop_true_preview';
  static const String disposeTruePreview = 'dispose_true_preview';

  static const String hdrScanCapability   = 'hdr_scan_capability';
  static const String hdrValidateExport   = 'hdr_validate_export';
  static const String hdrConfigurePreview = 'hdr_configure_preview';
}

class NativeCommand {
  final String id;
  final String type;
  final String? projectId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  NativeCommand({
    String? id,
    required this.type,
    this.projectId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        payload = payload ?? {},
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'projectId': projectId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class NativeCommandResult {
  final String commandId;
  final bool accepted;
  final String? message;
  final String? errorCode;

  const NativeCommandResult({
    required this.commandId,
    required this.accepted,
    this.message,
    this.errorCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'commandId': commandId,
      'accepted': accepted,
      'message': message,
      'errorCode': errorCode,
    };
  }
}
