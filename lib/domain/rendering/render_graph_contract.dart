class RenderGraphContract {
  static const String schema = 'nle.render_graph';
  static const int version = 2;
  static const int minSupportedVersion = 2;
  static const int maxSupportedVersion = 2;

  static const String source = 'flutter_multitrack_timeline';

  static const String nativeBridgeName = 'nle_editor/native_methods';
  static const int nativeBridgeProtocolVersion = 1;
  static const int minNativeBridgeProtocolVersion = 1;
  static const int maxNativeBridgeProtocolVersion = 1;

  static const String payloadProtocolVersionKey = 'protocolVersion';
  static const String payloadCommandIdKey = 'commandId';
  static const String payloadProjectIdKey = 'projectId';
  static const String payloadRenderGraphJsonKey = 'renderGraphJson';
  static const String payloadRenderGraphSchemaKey = 'renderGraphSchema';
  static const String payloadRenderGraphVersionKey = 'renderGraphVersion';

  static const Set<int> supportedVersions = {
    version,
  };

  static bool supportsVersion(int candidate) {
    return candidate >= minSupportedVersion &&
        candidate <= maxSupportedVersion &&
        supportedVersions.contains(candidate);
  }

  static bool supportsNativeBridgeProtocol(int candidate) {
    return candidate >= minNativeBridgeProtocolVersion &&
        candidate <= maxNativeBridgeProtocolVersion;
  }

  const RenderGraphContract._();
}

class RenderGraphNativeMethods {
  static const String initialize = 'initialize';
  static const String dispose = 'dispose';
  static const String loadRenderGraph = 'load_render_graph';
  static const String updateRenderGraph = 'update_render_graph';
  static const String validateRenderGraph = 'validate_render_graph';
  static const String renderGpuPreviewFrame = 'render_gpu_preview_frame';
  static const String startExportJob = 'start_export_job';
  static const String cancelExportJob = 'cancel_export_job';
  static const String getSessionState = 'get_session_state';
  static const String probeDeviceCapabilities = 'probe_device_capabilities';

  const RenderGraphNativeMethods._();
}

class RenderGraphTrackTypes {
  static const String video = 'video';
  static const String overlay = 'overlay';
  static const String text = 'text';
  static const String adjustment = 'adjustment';
  static const String audio = 'audio';

  const RenderGraphTrackTypes._();
}

class RenderGraphClipTypes {
  static const String video = 'video';
  static const String image = 'image';
  static const String audio = 'audio';
  static const String text = 'text';
  static const String adjustment = 'adjustment';
  static const String unknown = 'unknown';

  const RenderGraphClipTypes._();
}

class RenderGraphFitModes {
  static const String fit = 'fit';
  static const String fill = 'fill';
  static const String stretch = 'stretch';

  const RenderGraphFitModes._();
}
