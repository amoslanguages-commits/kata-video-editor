package com.nle.editor.sync

/**
 * Hard limits for audio/video sync QA.
 *
 * All values are in microseconds unless noted.
 */
object NleSyncThresholds {

    /** Maximum allowed A/V start-time difference (µs). */
    const val MAX_START_SYNC_US: Long = 20_000L   // 20 ms

    /** Maximum allowed A/V end-time difference (µs). */
    const val MAX_END_SYNC_US: Long = 35_000L     // 35 ms

    /** Maximum per-frame drift from expected presentation time (µs). */
    const val MAX_FRAME_DRIFT_US: Long = 16_667L  // ~1 frame @ 60fps

    /** Maximum cumulative A/V drift over a session (µs). */
    const val MAX_CUMULATIVE_DRIFT_US: Long = 100_000L // 100 ms

    /** Maximum render cost that we accept without flagging a dropped-frame. */
    const val MAX_RENDER_COST_MS: Long = 50L

    /** Minimum valid audio sample rate (Hz). */
    const val MIN_AUDIO_SAMPLE_RATE_HZ: Int = 8_000

    /** Maximum allowed gap between consecutive audio frames (µs). */
    const val MAX_AUDIO_GAP_US: Long = 10_000L    // 10 ms
}
