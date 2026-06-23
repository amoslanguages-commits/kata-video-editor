import Foundation

enum IosNleChannels {
    static let methodChannel = "nle_editor/native_methods"
    static let eventChannel = "nle_editor/native_events"
}

enum IosNleCommandType {
    static let initialize = "initialize"
    static let dispose = "dispose"

    static let loadRenderGraph = "load_render_graph"
    static let updateRenderGraph = "update_render_graph"
    static let validateRenderGraph = "validate_render_graph"

    static let play = "play"
    static let pause = "pause"
    static let seek = "seek"

    static let startJob = "start_job"
    static let cancelJob = "cancel_job"

    static let probeDeviceCapabilities = "probe_device_capabilities"
    static let getSessionState = "get_session_state"

    static let createPreviewTexture = "create_preview_texture"
    static let disposePreviewTexture = "dispose_preview_texture"
    static let attachPreviewTexture = "attach_preview_texture"
    static let resizePreviewTexture = "resize_preview_texture"
    static let renderPreviewPlaceholder = "render_preview_placeholder"
    static let renderGpuPreviewFrame = "render_gpu_preview_frame"

    static let setPlaybackRate = "set_playback_rate"
    static let getAudioEngineState = "get_audio_engine_state"

    static let startProxyJob = "start_proxy_job"
    static let cancelProxyJob = "cancel_proxy_job"

    static let startExportJob = "start_export_job"
    static let cancelExportJob = "cancel_export_job"
}

enum IosNleEventType {
    static let engineReady = "engine_ready"
    static let engineDisposed = "engine_disposed"

    static let graphLoaded = "graph_loaded"
    static let graphUpdated = "graph_updated"
    static let graphValidated = "graph_validated"

    static let playbackStarted = "playback_started"
    static let playbackPaused = "playback_paused"
    static let playbackCompleted = "playback_completed"
    static let playheadChanged = "playhead_changed"
    static let playbackRateChanged = "playback_rate_changed"

    static let jobStarted = "job_started"
    static let jobProgress = "job_progress"
    static let jobCompleted = "job_completed"
    static let jobFailed = "job_failed"
    static let jobCancelled = "job_cancelled"

    static let proxyStarted = "proxy_started"
    static let proxyProgress = "proxy_progress"
    static let proxyCompleted = "proxy_completed"
    static let proxyFailed = "proxy_failed"
    static let proxyCancelled = "proxy_cancelled"

    static let exportStarted = "export_started"
    static let exportProgress = "export_progress"
    static let exportCompleted = "export_completed"
    static let exportFailed = "export_failed"
    static let exportCancelled = "export_cancelled"

    static let deviceCapabilities = "device_capabilities"

    static let previewSurfaceReady = "preview_surface_ready"
    static let previewSurfaceAttached = "preview_surface_attached"
    static let previewSurfaceResized = "preview_surface_resized"
    static let previewSurfaceDisposed = "preview_surface_disposed"
    static let previewFrameRendered = "preview_frame_rendered"
    static let gpuPreviewFrameRendered = "gpu_preview_frame_rendered"

    static let engineError = "engine_error"
    static let decoderError = "decoder_error"
    static let missingFile = "missing_file"
    static let memoryWarning = "memory_warning"
    static let thermalWarning = "thermal_warning"
}
