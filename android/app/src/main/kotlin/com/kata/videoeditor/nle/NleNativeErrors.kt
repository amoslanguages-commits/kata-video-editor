package com.kata.videoeditor.nle

object NleNativeErrorCode {
    const val ENGINE_NOT_INITIALIZED = "android_engine_not_initialized"
    const val SESSION_NOT_FOUND = "android_session_not_found"
    const val INVALID_ARGUMENTS = "android_invalid_arguments"
    const val GRAPH_PARSE_FAILED = "android_graph_parse_failed"
    const val GRAPH_VALIDATION_FAILED = "android_graph_validation_failed"
    const val COMMAND_FAILED = "android_command_failed"
    const val JOB_NOT_FOUND = "android_job_not_found"
    const val UNSUPPORTED_COMMAND = "android_unsupported_command"

    const val PREVIEW_TEXTURE_NOT_FOUND = "android_preview_texture_not_found"
    const val PREVIEW_TEXTURE_CREATE_FAILED = "android_preview_texture_create_failed"
    const val PREVIEW_TEXTURE_RENDER_FAILED = "android_preview_texture_render_failed"

    const val AUDIO_ENGINE_INIT_FAILED = "android_audio_engine_init_failed"
    const val AUDIO_TRACK_WRITE_FAILED = "android_audio_track_write_failed"

    const val AUDIO_ENGINE_CREATE_FAILED = "android_audio_engine_create_failed"
    const val AUDIO_ENGINE_START_FAILED = "android_audio_engine_start_failed"
    const val AUDIO_ENGINE_WRITE_FAILED = "android_audio_engine_write_failed"
    const val AUDIO_ENGINE_RELEASE_FAILED = "android_audio_engine_release_failed"

    const val AUDIO_EXPORT_NO_TRACKS = "android_audio_export_no_tracks"
    const val AUDIO_EXPORT_INPUT_MISSING = "android_audio_export_input_missing"
    const val AUDIO_EXPORT_DECODE_FAILED = "android_audio_export_decode_failed"
    const val AUDIO_EXPORT_MIX_FAILED = "android_audio_export_mix_failed"
    const val AUDIO_EXPORT_ENCODE_FAILED = "android_audio_export_encode_failed"
    const val AUDIO_EXPORT_MUX_FAILED = "android_audio_export_mux_failed"

    const val PROXY_INPUT_MISSING = "android_proxy_input_missing"
    const val PROXY_OUTPUT_INVALID = "android_proxy_output_invalid"
    const val PROXY_PROBE_FAILED = "android_proxy_probe_failed"
    const val PROXY_ENCODER_FAILED = "android_proxy_encoder_failed"
    const val PROXY_CANCELLED = "android_proxy_cancelled"
    const val PROXY_JOB_NOT_FOUND = "android_proxy_job_not_found"
    const val PROXY_TRANSCODE_FAILED = "android_proxy_transcode_failed"

    const val EXPORT_INPUT_MISSING = "android_export_input_missing"
    const val EXPORT_OUTPUT_INVALID = "android_export_output_invalid"
    const val EXPORT_GRAPH_INVALID = "android_export_graph_invalid"
    const val EXPORT_NO_VISUAL_TRACK = "android_export_no_visual_track"
    const val EXPORT_NO_CLIPS = "android_export_no_clips"
    const val EXPORT_ENCODER_FAILED = "android_export_encoder_failed"
    const val EXPORT_CANCELLED = "android_export_cancelled"
    const val EXPORT_JOB_NOT_FOUND = "android_export_job_not_found"
    const val EXPORT_JOB_ALREADY_RUNNING = "android_export_job_already_running"
    const val EXPORT_FAILED = "android_export_failed"
    const val EXPORT_MISSING_ASSET = "android_export_missing_asset"

    // V2 Exporter Errors
    const val EXPORT_DECODER_FAILED = "android_export_decoder_failed"
    const val EXPORT_DECODER_TIMEOUT = "android_export_decoder_timeout"
    const val EXPORT_SURFACE_TEXTURE_FAILED = "android_export_surface_texture_failed"
    const val EXPORT_RENDER_FAILED = "android_export_render_failed"
    const val EXPORT_MUXER_FAILED = "android_export_muxer_failed"
    const val EXPORT_SYNC_WARNING = "android_export_sync_warning"
}
