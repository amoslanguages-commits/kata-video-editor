package com.kata.videoeditor.nle

import org.json.JSONObject
import java.util.UUID

/**
 * Holds the in-memory state for one open project on the native side.
 * One session per [projectId] is stored in [NleEngineManager].
 */
class NleEngineSession(
    val projectId: String,
    initialRenderGraphJson: String
) {
    val sessionId: String = UUID.randomUUID().toString()

    var renderGraphJson: String = initialRenderGraphJson
        private set

    var renderGraph: JSONObject = JSONObject(initialRenderGraphJson)
        private set

    var isPlaying: Boolean = false
        private set

    var playheadMicros: Long = 0L
        private set

    /** Total timeline duration in microseconds, derived from the render graph. */
    var durationMicros: Long = NleTimelineDurationParser.parse(JSONObject(initialRenderGraphJson))
        private set

    /** Playback speed multiplier (0.25–4.0). */
    var playbackRate: Float = 1.0f
        private set

    val createdAtMillis: Long = System.currentTimeMillis()

    var updatedAtMillis: Long = createdAtMillis
        private set

    // ── Mutation ─────────────────────────────────────────────────────────────

    fun updateGraph(newGraphJson: String) {
        renderGraphJson = newGraphJson
        renderGraph     = JSONObject(newGraphJson)
        durationMicros  = NleTimelineDurationParser.parse(renderGraph)
        touch()
    }

    fun play() {
        isPlaying = true
        touch()
    }

    fun pause() {
        isPlaying = false
        touch()
    }

    fun seek(positionMicros: Long) {
        playheadMicros = positionMicros.coerceAtLeast(0L)
        touch()
    }

    fun updatePlayhead(positionMicros: Long, playing: Boolean) {
        playheadMicros = positionMicros
        isPlaying      = playing
        // No touch() — called at 60fps; avoid churning updatedAtMillis
    }

    fun setPlaybackRate(rate: Float) {
        playbackRate = rate.coerceIn(0.25f, 4.0f)
        touch()
    }

    // ── Serialisation ────────────────────────────────────────────────────────

    fun toMap(): Map<String, Any?> = mapOf(
        "sessionId"       to sessionId,
        "projectId"       to projectId,
        "isPlaying"       to isPlaying,
        "playheadMicros"  to playheadMicros,
        "durationMicros"  to durationMicros,
        "playbackRate"    to playbackRate.toDouble(),
        "createdAtMillis" to createdAtMillis,
        "updatedAtMillis" to updatedAtMillis
    )

    private fun touch() {
        updatedAtMillis = System.currentTimeMillis()
    }
}
