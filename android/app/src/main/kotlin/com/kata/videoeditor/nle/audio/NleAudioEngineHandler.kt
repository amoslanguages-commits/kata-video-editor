package com.kata.videoeditor.nle.audio

import com.kata.videoeditor.nle.NleExportProfile
import com.kata.videoeditor.nle.NleNativeErrorCode
import com.kata.videoeditor.nle.NleNativeEvent
import com.kata.videoeditor.nle.NleNativeEventEmitter
import org.json.JSONObject
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * Handles all `audio_*` bridge commands for the Android engine.
 *
 * - Keeps the per-project audio state (track/clip volumes, mutes, solos, fades,
 *   master volume, ducking) sent by the Dart audio controller.
 * - `audio_request_mixdown` renders a real AAC (.m4a) mix of the project's audio
 *   using the existing [NleAudioMixExporter] pipeline, driven by the project's
 *   current render graph (which carries asset file paths).
 */
class NleAudioEngineHandler(
    private val eventEmitter: NleNativeEventEmitter,
    private val sessionGraphProvider: (String) -> SessionGraph?,
) {
    data class SessionGraph(
        val renderGraphJson: String,
        val durationMicros: Long,
    )

    private data class TrackState(
        var volume: Float = 1f,
        var muted: Boolean = false,
        var solo: Boolean = false,
    )

    private data class ClipState(
        var volume: Float = 1f,
        var muted: Boolean = false,
        var fadeInUs: Long = 0L,
        var fadeOutUs: Long = 0L,
    )

    private class ProjectAudioState {
        var masterVolume = 1f
        var autoDuckingEnabled = false
        var duckingAmountDb = -12f
        val tracks = mutableMapOf<String, TrackState>()
        val clips = mutableMapOf<String, ClipState>()
        @Volatile var metersActive = false
        @Volatile var lastGraphJson: String? = null
        @Volatile var mixdownRunning: AtomicBoolean? = null
    }

    private val projects = ConcurrentHashMap<String, ProjectAudioState>()

    private fun stateFor(projectId: String): ProjectAudioState =
        projects.getOrPut(projectId) { ProjectAudioState() }

    fun clear() {
        projects.clear()
    }

    // ── Graph load / update ──────────────────────────────────────────────────

    fun loadGraph(projectId: String, audioGraphJson: String, commandId: String?, updated: Boolean): Map<String, Any?> {
        val state = stateFor(projectId)
        val (trackCount, clipCount) = applyGraph(state, audioGraphJson)
        eventEmitter.emit(
            NleNativeEvent(
                type = if (updated) "audio_graph_updated" else "audio_graph_loaded",
                projectId = projectId,
                commandId = commandId,
                payload = mapOf(
                    "trackCount" to trackCount,
                    "clipCount" to clipCount,
                    "masterVolume" to state.masterVolume.toDouble(),
                    "autoDuckingEnabled" to state.autoDuckingEnabled,
                ),
            ),
        )
        return mapOf("accepted" to true, "trackCount" to trackCount, "clipCount" to clipCount)
    }

    private fun applyGraph(state: ProjectAudioState, json: String): Pair<Int, Int> {
        return try {
            val root = JSONObject(json)
            state.masterVolume = root.optDouble("masterVolume", 1.0).toFloat()
            state.autoDuckingEnabled = root.optBoolean("autoDuckingEnabled", false)
            state.duckingAmountDb = root.optDouble("duckingAmountDb", -12.0).toFloat()
            val tracks = root.optJSONArray("tracks")
            var clipCount = 0
            if (tracks != null) {
                for (i in 0 until tracks.length()) {
                    val t = tracks.optJSONObject(i) ?: continue
                    val trackId = t.optString("id", "")
                    if (trackId.isNotBlank()) {
                        state.tracks[trackId] = TrackState(
                            volume = t.optDouble("volume", 1.0).toFloat(),
                            muted = t.optBoolean("isMuted", t.optBoolean("muted", false)),
                            solo = t.optBoolean("isSolo", t.optBoolean("solo", false)),
                        )
                    }
                    val clips = t.optJSONArray("clips") ?: continue
                    for (j in 0 until clips.length()) {
                        val c = clips.optJSONObject(j) ?: continue
                        val clipId = c.optString("id", "")
                        if (clipId.isBlank()) continue
                        state.clips[clipId] = ClipState(
                            volume = c.optDouble("volume", 1.0).toFloat(),
                            muted = c.optBoolean("isMuted", false),
                            fadeInUs = c.optJSONObject("fadeIn")?.optLong("durationMicros", 0L)
                                ?: c.optLong("fadeInMicros", 0L),
                            fadeOutUs = c.optJSONObject("fadeOut")?.optLong("durationMicros", 0L)
                                ?: c.optLong("fadeOutMicros", 0L),
                        )
                        clipCount++
                    }
                }
            }
            state.lastGraphJson = json
            (tracks?.length() ?: 0) to clipCount
        } catch (_: Throwable) {
            0 to 0
        }
    }

    // ── Track / clip parameter updates ───────────────────────────────────────

    fun setTrackVolume(projectId: String, trackId: String, volume: Float, commandId: String?): Map<String, Any?> {
        val state = stateFor(projectId)
        state.tracks.getOrPut(trackId) { TrackState() }.volume = volume.coerceIn(0f, 2f)
        emitMeterUpdateIfActive(projectId, state, commandId)
        return mapOf("accepted" to true, "trackId" to trackId, "volume" to volume.toDouble())
    }

    fun setTrackMute(projectId: String, trackId: String, muted: Boolean, commandId: String?): Map<String, Any?> {
        val state = stateFor(projectId)
        state.tracks.getOrPut(trackId) { TrackState() }.muted = muted
        emitMeterUpdateIfActive(projectId, state, commandId)
        return mapOf("accepted" to true, "trackId" to trackId, "muted" to muted)
    }

    fun setTrackSolo(projectId: String, trackId: String, solo: Boolean, commandId: String?): Map<String, Any?> {
        val state = stateFor(projectId)
        state.tracks.getOrPut(trackId) { TrackState() }.solo = solo
        emitMeterUpdateIfActive(projectId, state, commandId)
        return mapOf("accepted" to true, "trackId" to trackId, "solo" to solo)
    }

    fun setClipVolume(projectId: String, clipId: String, volume: Float, commandId: String?): Map<String, Any?> {
        val state = stateFor(projectId)
        state.clips.getOrPut(clipId) { ClipState() }.volume = volume.coerceIn(0f, 2f)
        emitMeterUpdateIfActive(projectId, state, commandId)
        return mapOf("accepted" to true, "clipId" to clipId, "volume" to volume.toDouble())
    }

    fun setClipMute(projectId: String, clipId: String, muted: Boolean, commandId: String?): Map<String, Any?> {
        val state = stateFor(projectId)
        state.clips.getOrPut(clipId) { ClipState() }.muted = muted
        emitMeterUpdateIfActive(projectId, state, commandId)
        return mapOf("accepted" to true, "clipId" to clipId, "muted" to muted)
    }

    fun setClipFade(projectId: String, clipId: String, fadeInUs: Long, fadeOutUs: Long, commandId: String?): Map<String, Any?> {
        val state = stateFor(projectId)
        val clip = state.clips.getOrPut(clipId) { ClipState() }
        clip.fadeInUs = fadeInUs.coerceAtLeast(0L)
        clip.fadeOutUs = fadeOutUs.coerceAtLeast(0L)
        emitMeterUpdateIfActive(projectId, state, commandId)
        return mapOf("accepted" to true, "clipId" to clipId, "fadeInUs" to fadeInUs, "fadeOutUs" to fadeOutUs)
    }

    // ── Meter updates ────────────────────────────────────────────────────────

    fun startMeterUpdates(projectId: String, commandId: String?): Map<String, Any?> {
        val state = stateFor(projectId)
        state.metersActive = true
        emitMeterUpdate(projectId, state, commandId)
        return mapOf("accepted" to true, "metersActive" to true)
    }

    fun stopMeterUpdates(projectId: String, commandId: String?): Map<String, Any?> {
        val state = stateFor(projectId)
        state.metersActive = false
        return mapOf("accepted" to true, "metersActive" to false)
    }

    private fun emitMeterUpdateIfActive(projectId: String, state: ProjectAudioState, commandId: String?) {
        if (state.metersActive) {
            emitMeterUpdate(projectId, state, commandId)
        }
    }

    private fun emitMeterUpdate(projectId: String, state: ProjectAudioState, commandId: String?) {
        // No real-time playback DSP is attached to this handler, so signal
        // levels are reported as silence while reflecting the live mixer state
        // (volumes / mutes / solos) — the UI meters show the graph state
        // instead of failing with an unsupported-command error.
        eventEmitter.emit(
            NleNativeEvent(
                type = "audio_meter_update",
                projectId = projectId,
                commandId = commandId,
                payload = mapOf(
                    "masterLevel" to 0.0,
                    "masterClipping" to false,
                    "trackLevels" to state.tracks.map { (id, t) ->
                        mapOf(
                            "trackId" to id,
                            "level" to 0.0,
                            "muted" to t.muted,
                            "solo" to t.solo,
                            "volume" to t.volume.toDouble(),
                        )
                    },
                    "clipStates" to state.clips.map { (id, c) ->
                        mapOf(
                            "clipId" to id,
                            "muted" to c.muted,
                            "volume" to c.volume.toDouble(),
                            "fadeInUs" to c.fadeInUs,
                            "fadeOutUs" to c.fadeOutUs,
                        )
                    },
                ),
            ),
        )
    }

    // ── Mixdown ──────────────────────────────────────────────────────────────

    fun requestMixdown(
        projectId: String,
        audioGraphJson: String?,
        outputPath: String?,
        profileMap: Map<String, Any?>,
        commandId: String?,
    ): Map<String, Any?> {
        val state = stateFor(projectId)
        if (audioGraphJson != null) {
            applyGraph(state, audioGraphJson)
        }
        val session = sessionGraphProvider(projectId)
            ?: throw IllegalStateException(NleNativeErrorCode.SESSION_NOT_FOUND)
        if (state.mixdownRunning?.get() == true) {
            throw IllegalStateException("An audio mixdown is already running for this project.")
        }

        val targetPath = outputPath?.takeIf { it.isNotBlank() }
            ?: File.createTempFile("nle_audio_mix_", ".m4a").absolutePath

        val cancelled = AtomicBoolean(false)
        state.mixdownRunning = cancelled

        eventEmitter.emit(
            NleNativeEvent(
                type = "audio_mixdown_started",
                projectId = projectId,
                commandId = commandId,
                payload = mapOf("outputPath" to targetPath),
            ),
        )

        thread(name = "nle-audio-mixdown-$projectId") {
            try {
                // Normalise the Dart profile keys onto the export profile keys.
                val normalizedProfile = HashMap<String, Any?>(profileMap)
                normalizedProfile["audioSampleRate"] = profileMap["audioSampleRate"] ?: profileMap["sampleRate"] ?: 48000
                normalizedProfile["audioChannels"] = profileMap["audioChannels"] ?: profileMap["channels"] ?: 2
                normalizedProfile["audioBitrate"] = profileMap["audioBitrate"] ?: profileMap["bitrate"] ?: 192000
                val profile = NleExportProfile.fromPayload(normalizedProfile)

                val resultPath = NleAudioMixExporter().exportAudioMix(
                    projectId = projectId,
                    renderGraphJson = session.renderGraphJson,
                    durationMicros = session.durationMicros,
                    outputM4aPath = targetPath,
                    profile = profile,
                    cancelled = cancelled,
                    onProgress = { progress, stage ->
                        eventEmitter.emit(
                            NleNativeEvent(
                                type = "audio_mixdown_progress",
                                projectId = projectId,
                                payload = mapOf(
                                    "progress" to progress,
                                    "stage" to stage,
                                    "outputPath" to targetPath,
                                ),
                            ),
                        )
                    },
                )

                if (resultPath == null) {
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = "audio_mixdown_failed",
                            projectId = projectId,
                            payload = mapOf(
                                "outputPath" to targetPath,
                                "message" to "No audible audio clips were found in the current render graph.",
                            ),
                        ),
                    )
                } else {
                    val file = File(resultPath)
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = "audio_mixdown_completed",
                            projectId = projectId,
                            payload = mapOf(
                                "outputPath" to resultPath,
                                "durationMicros" to session.durationMicros,
                                "fileSizeBytes" to file.length(),
                                "formatInfo" to mapOf(
                                    "sampleRate" to profile.audioSampleRate,
                                    "channels" to profile.audioChannels,
                                    "bitDepth" to 16,
                                    "codec" to "aac",
                                    "bitrate" to profile.audioBitrate,
                                ),
                            ),
                        ),
                    )
                }
            } catch (e: Throwable) {
                eventEmitter.emit(
                    NleNativeEvent(
                        type = "audio_mixdown_failed",
                        projectId = projectId,
                        payload = mapOf(
                            "outputPath" to targetPath,
                            "message" to (e.message ?: "Audio mixdown failed."),
                        ),
                    ),
                )
            } finally {
                state.mixdownRunning = null
            }
        }

        return mapOf("accepted" to true, "outputPath" to targetPath)
    }

    // ── State ────────────────────────────────────────────────────────────────

    fun getState(projectId: String): Map<String, Any?> {
        val state = stateFor(projectId)
        return mapOf(
            "initialized" to true,
            "projectId" to projectId,
            "masterVolume" to state.masterVolume.toDouble(),
            "autoDuckingEnabled" to state.autoDuckingEnabled,
            "duckingAmountDb" to state.duckingAmountDb.toDouble(),
            "trackCount" to state.tracks.size,
            "clipCount" to state.clips.size,
            "metersActive" to state.metersActive,
            "mixdownRunning" to (state.mixdownRunning != null),
        )
    }
}
