package com.kata.videoeditor.nle

object NleChannels {
    const val METHOD_CHANNEL = "nle_editor/native_methods"
    const val EVENT_CHANNEL  = "nle_editor/native_events"
}

object NleNativeCommandType {
    const val INITIALIZE              = "initialize"
    const val DISPOSE                 = "dispose"

    const val LOAD_RENDER_GRAPH       = "load_render_graph"
    const val UPDATE_RENDER_GRAPH     = "update_render_graph"
    const val VALIDATE_RENDER_GRAPH   = "validate_render_graph"

    const val PLAY                    = "play"
    const val PAUSE                   = "pause"
    const val SEEK                    = "seek"

    const val START_JOB               = "start_job"
    const val CANCEL_JOB              = "cancel_job"
    const val START_PROXY_JOB         = "start_proxy_job"
    const val CANCEL_PROXY_JOB        = "cancel_proxy_job"

    const val START_EXPORT_JOB        = "start_export_job"
    const val CANCEL_EXPORT_JOB       = "cancel_export_job"

    const val PROBE_DEVICE_CAPABILITIES = "probe_device_capabilities"
    const val GET_SESSION_STATE         = "get_session_state"

    const val CREATE_PREVIEW_TEXTURE     = "create_preview_texture"
    const val DISPOSE_PREVIEW_TEXTURE    = "dispose_preview_texture"
    const val ATTACH_PREVIEW_TEXTURE     = "attach_preview_texture"
    const val RESIZE_PREVIEW_TEXTURE     = "resize_preview_texture"
    const val RENDER_PREVIEW_PLACEHOLDER = "render_preview_placeholder"

    const val SET_PLAYBACK_RATE       = "set_playback_rate"
    const val GET_AUDIO_ENGINE_STATE  = "get_audio_engine_state"

    const val RENDER_GPU_PREVIEW_FRAME = "render_gpu_preview_frame"

    // 30G-PRO: Scopes Commands
    const val SCOPES_CONFIGURE     = "scopes_configure"
    const val SCOPES_REQUEST_FRAME = "scopes_request_frame"
    const val SCOPES_START_LIVE    = "scopes_start_live"
    const val SCOPES_STOP_LIVE     = "scopes_stop_live"

    // 30J-PRO: HDR Output Commands
    const val HDR_SCAN_CAPABILITY   = "hdr_scan_capability"
    const val HDR_VALIDATE_EXPORT   = "hdr_validate_export"
    const val HDR_CONFIGURE_PREVIEW = "hdr_configure_preview"

    // 31A-QA: Color QA Commands
    const val QA_RUN_COLOR_CHECKS       = "qa_run_color_checks"
    const val QA_RUN_SHADER_COMPILE_TEST = "qa_run_shader_compile_test"
    const val QA_RUN_MEMORY_LEAK_PROBE   = "qa_run_memory_leak_probe"
}

object NleNativeEventType {
    const val ENGINE_READY    = "engine_ready"
    const val ENGINE_DISPOSED = "engine_disposed"

    const val GRAPH_LOADED    = "graph_loaded"
    const val GRAPH_UPDATED   = "graph_updated"
    const val GRAPH_VALIDATED = "graph_validated"

    const val PLAYBACK_STARTED  = "playback_started"
    const val PLAYBACK_PAUSED   = "playback_paused"
    const val PLAYHEAD_CHANGED  = "playhead_changed"

    const val JOB_STARTED   = "job_started"
    const val JOB_PROGRESS  = "job_progress"
    const val JOB_COMPLETED = "job_completed"
    const val JOB_FAILED    = "job_failed"
    const val JOB_CANCELLED = "job_cancelled"

    const val PROXY_STARTED   = "proxy_started"
    const val PROXY_PROGRESS  = "proxy_progress"
    const val PROXY_COMPLETED = "proxy_completed"
    const val PROXY_CANCELLED = "proxy_cancelled"

    const val EXPORT_STARTED   = "export_started"
    const val EXPORT_PROGRESS  = "export_progress"
    const val EXPORT_COMPLETED = "export_completed"
    const val EXPORT_CANCELLED = "export_cancelled"

    const val DEVICE_CAPABILITIES = "device_capabilities"

    const val PREVIEW_SURFACE_READY    = "preview_surface_ready"
    const val PREVIEW_SURFACE_ATTACHED = "preview_surface_attached"
    const val PREVIEW_SURFACE_RESIZED  = "preview_surface_resized"
    const val PREVIEW_SURFACE_DISPOSED = "preview_surface_disposed"
    const val PREVIEW_FRAME_RENDERED   = "preview_frame_rendered"

    const val AUDIO_ENGINE_STATE_CHANGED = "audio_engine_state_changed"
    const val PLAYBACK_ENDED             = "playback_ended"

    const val GPU_PREVIEW_FRAME_RENDERED = "gpu_preview_frame_rendered"

    // 30G-PRO: Scopes Events
    const val SCOPES_FRAME_DATA = "scopes_frame_data"

    // 30J-PRO: HDR Events
    const val HDR_DEVICE_CAPABILITY = "hdr_device_capability"
    const val HDR_EXPORT_VALIDATION = "hdr_export_validation"

    const val ENGINE_ERROR    = "engine_error"
    const val DECODER_ERROR   = "decoder_error"
    const val EXPORT_FAILED   = "export_failed"
    const val PROXY_FAILED    = "proxy_failed"
    const val MISSING_FILE    = "missing_file"
    const val MEMORY_WARNING  = "memory_warning"
    const val THERMAL_WARNING = "thermal_warning"
}
