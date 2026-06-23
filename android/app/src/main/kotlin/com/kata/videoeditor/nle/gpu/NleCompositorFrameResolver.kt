package com.kata.videoeditor.nle.gpu

import android.graphics.Color
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Resolves a [NleCompositorFrame] from the render graph JSON at a given
 * timeline position.
 *
 * Step 19 additions over Step 18:
 *  - Multi-layer visual output (supports transitions with two simultaneous layers)
 *  - Text overlay resolution (clips with type == "text")
 *  - Per-layer colour-grading effect settings (brightness / contrast / saturation)
 *  - Dissolve / fade transition detection with smooth-step progress
 */
class NleCompositorFrameResolver {

    fun resolveFrame(
        projectId: String,
        renderGraphJson: String,
        timelineTimeMicros: Long,
    ): NleCompositorFrame {
        val graph = JSONObject(renderGraphJson)

        val assets      = graph.optJSONArray("assets")      ?: JSONArray()
        val tracks      = graph.optJSONArray("tracks")      ?: JSONArray()
        val clips       = graph.optJSONArray("clips")       ?: JSONArray()
        val transitions = graph.optJSONArray("transitions") ?: JSONArray()

        val assetsById = buildAssetsMap(assets)
        val clipsById  = buildClipsMap(clips)

        val visualTrackId = chooseFirstVisualTrackId(tracks)

        val visualLayers        = mutableListOf<NleCompositorVisualLayer>()
        var transitionState: NleTransitionState? = null

        if (visualTrackId != null) {
            val activeTransition = findActiveTransition(
                transitions        = transitions,
                clipsById          = clipsById,
                visualTrackId      = visualTrackId,
                timelineTimeMicros = timelineTimeMicros
            )

            if (activeTransition != null) {
                transitionState = activeTransition.first
                val (outgoing, incoming) = activeTransition.second

                visualLayers += buildVisualLayer(
                    clip               = outgoing,
                    assetsById         = assetsById,
                    timelineTimeMicros = timelineTimeMicros,
                    opacityOverride    = 1f - transitionState.progress
                )
                visualLayers += buildVisualLayer(
                    clip               = incoming,
                    assetsById         = assetsById,
                    timelineTimeMicros = timelineTimeMicros,
                    opacityOverride    = transitionState.progress
                )
            } else {
                val activeClip = findActiveVisualClip(
                    clips              = clips,
                    visualTrackId      = visualTrackId,
                    timelineTimeMicros = timelineTimeMicros
                )
                if (activeClip != null) {
                    visualLayers += buildVisualLayer(
                        clip               = activeClip,
                        assetsById         = assetsById,
                        timelineTimeMicros = timelineTimeMicros,
                        opacityOverride    = null
                    )
                }
            }
        }

        val textOverlays = resolveActiveTextOverlays(
            clips              = clips,
            timelineTimeMicros = timelineTimeMicros
        )

        return NleCompositorFrame(
            projectId          = projectId,
            timelineTimeMicros = timelineTimeMicros,
            backgroundColor    = parseBackgroundColor(graph),
            visualLayers       = visualLayers,
            textOverlays       = textOverlays,
            transition         = transitionState
        )
    }

    // ── Visual layer builder ──────────────────────────────────────────────────

    private fun buildVisualLayer(
        clip: JSONObject,
        assetsById: Map<String, JSONObject>,
        timelineTimeMicros: Long,
        opacityOverride: Float?,
    ): NleCompositorVisualLayer {
        val assetId = clip.optStringFlexible("assetId", "asset_id", "")
        val asset   = assetsById[assetId]

        val timelineStart = clip.optLongFlexible("timelineStartMicros", "timeline_start_micros", 0L)
        val sourceIn      = clip.optLongFlexible("sourceInMicros",      "source_in_micros",      0L)
        val sourceOut     = clip.optLongFlexible("sourceOutMicros",     "source_out_micros",     sourceIn)
        val speed         = clip.optDoubleFlexible("speed", "playbackSpeed", 1.0).coerceIn(0.25, 4.0)

        val local      = (timelineTimeMicros - timelineStart).coerceAtLeast(0L)
        var sourceTime = sourceIn + (local * speed).toLong()
        if (sourceOut > sourceIn) sourceTime = sourceTime.coerceIn(sourceIn, sourceOut)

        return NleCompositorVisualLayer(
            clipId          = clip.optString("id", "").ifBlank { null },
            assetId         = assetId.ifBlank { null },
            inputPath       = asset?.let { resolveAssetPath(it) },
            sourceTimeMicros = sourceTime,
            transform       = NleCompositorTransform(
                positionX       = clip.optFloatFlexible("positionX",       "position_x",    0f),
                positionY       = clip.optFloatFlexible("positionY",       "position_y",    0f),
                scale           = clip.optFloatFlexible("scale",           "transformScale",1f).coerceIn(0.05f, 20f),
                rotationDegrees = clip.optFloatFlexible("rotation",        "rotationDegrees",0f),
                opacity         = clip.optFloatFlexible("opacity",         "alpha",         1f).coerceIn(0f, 1f),
                fitMode         = clip.optStringFlexible("fitMode",        "fit",           "fit")
            ),
            effects         = NleCompositorEffectSettings(
                brightness  = clip.optFloatFlexible("brightness",  "exposure",   0f).coerceIn(-1f, 1f),
                contrast    = clip.optFloatFlexible("contrast",    "contrast",   1f).coerceIn(0f, 4f),
                saturation  = clip.optFloatFlexible("saturation",  "saturation", 1f).coerceIn(0f, 4f)
            ),
            opacityOverride = opacityOverride
        )
    }

    // ── Text overlay resolution ───────────────────────────────────────────────

    private fun resolveActiveTextOverlays(
        clips: JSONArray,
        timelineTimeMicros: Long,
    ): List<NleTextOverlay> {
        val result = mutableListOf<NleTextOverlay>()

        for (i in 0 until clips.length()) {
            val clip = clips.optJSONObject(i) ?: continue

            val clipType = clip.optStringFlexible("clipType", "type", "")
            if (clipType != "text") continue

            val start = clip.optLongFlexible("timelineStartMicros", "timeline_start_micros", 0L)
            val end   = clip.optLongFlexible("timelineEndMicros",   "timeline_end_micros",   0L)

            if (timelineTimeMicros < start || timelineTimeMicros >= end) continue

            val text = clip.optStringFlexible("textContent", "text", "")
            if (text.isBlank()) continue

            val styleJson = clip.optStringFlexible("textStyle", "styleJson", "")

            result += NleTextOverlay(
                clipId              = clip.optString("id", "text_$i"),
                text                = text,
                timelineStartMicros = start,
                timelineEndMicros   = end,
                positionX           = clip.optFloatFlexible("positionX",  "position_x",    0f),
                positionY           = clip.optFloatFlexible("positionY",  "position_y",    0f),
                scale               = clip.optFloatFlexible("scale",      "transformScale",1f).coerceIn(0.05f, 20f),
                rotationDegrees     = clip.optFloatFlexible("rotation",   "rotationDegrees",0f),
                opacity             = clip.optFloatFlexible("opacity",    "alpha",         1f).coerceIn(0f, 1f),
                style               = NleTextStyleParser.parse(styleJson)
            )
        }

        return result.sortedBy { it.timelineStartMicros }
    }

    // ── Transition detection ──────────────────────────────────────────────────

    /**
     * Returns the active transition state and its two participating clips, or null.
     *
     * A transition is active when [timelineTimeMicros] falls within:
     *   [incomingStart − duration/2, incomingStart + duration/2)
     */
    private fun findActiveTransition(
        transitions: JSONArray,
        clipsById: Map<String, JSONObject>,
        visualTrackId: String,
        timelineTimeMicros: Long,
    ): Pair<NleTransitionState, Pair<JSONObject, JSONObject>>? {
        for (i in 0 until transitions.length()) {
            val t = transitions.optJSONObject(i) ?: continue
            if (t.optBoolean("isDisabled", false)) continue

            val outgoingId = t.optStringFlexible("outgoingClipId", "outgoing_clip_id", "")
            val incomingId = t.optStringFlexible("incomingClipId", "incoming_clip_id", "")

            val outgoing = clipsById[outgoingId] ?: continue
            val incoming = clipsById[incomingId] ?: continue

            // Both clips must be on the primary visual track
            if (outgoing.optStringFlexible("trackId", "track_id", "") != visualTrackId) continue
            if (incoming.optStringFlexible("trackId", "track_id", "") != visualTrackId) continue

            val duration      = t.optLongFlexible("durationMicros", "duration_micros", 500_000L).coerceAtLeast(1L)
            val incomingStart = incoming.optLongFlexible("timelineStartMicros", "timeline_start_micros", 0L)

            val transStart = incomingStart - duration / 2L
            val transEnd   = incomingStart + duration / 2L

            if (timelineTimeMicros < transStart || timelineTimeMicros >= transEnd) continue

            val rawProgress = (timelineTimeMicros - transStart).toFloat() / duration.toFloat()
            val progress    = smoothStep(rawProgress.coerceIn(0f, 1f))

            val type = t.optStringFlexible("transitionType", "type", "dissolve")

            return NleTransitionState(
                transitionId   = t.optString("id", "transition_$i"),
                type           = type,
                progress       = progress,
                outgoingClipId = outgoingId,
                incomingClipId = incomingId
            ) to (outgoing to incoming)
        }

        return null
    }

    /** Ken Perlin's smooth-step: eases in and out. */
    private fun smoothStep(x: Float): Float {
        val t = x.coerceIn(0f, 1f)
        return t * t * (3f - 2f * t)
    }

    // ── Clip / asset lookup ───────────────────────────────────────────────────

    private fun findActiveVisualClip(
        clips: JSONArray,
        visualTrackId: String,
        timelineTimeMicros: Long,
    ): JSONObject? {
        val candidates = mutableListOf<JSONObject>()

        for (i in 0 until clips.length()) {
            val clip = clips.optJSONObject(i) ?: continue
            if (clip.optStringFlexible("trackId", "track_id", "") != visualTrackId) continue

            val type = clip.optStringFlexible("clipType", "type", "video")
            if (type == "text" || type == "audio") continue

            val start = clip.optLongFlexible("timelineStartMicros", "timeline_start_micros", 0L)
            val end   = clip.optLongFlexible("timelineEndMicros",   "timeline_end_micros",   0L)

            if (timelineTimeMicros >= start && timelineTimeMicros < end) {
                candidates += clip
            }
        }

        return candidates.sortedBy {
            it.optIntFlexible("sortOrder", "sort_order", 0)
        }.lastOrNull()
    }

    private fun buildAssetsMap(array: JSONArray): Map<String, JSONObject> {
        val map = mutableMapOf<String, JSONObject>()
        for (i in 0 until array.length()) {
            val a  = array.optJSONObject(i) ?: continue
            val id = a.optString("id", "")
            if (id.isNotBlank()) map[id] = a
        }
        return map
    }

    private fun buildClipsMap(array: JSONArray): Map<String, JSONObject> {
        val map = mutableMapOf<String, JSONObject>()
        for (i in 0 until array.length()) {
            val c  = array.optJSONObject(i) ?: continue
            val id = c.optString("id", "")
            if (id.isNotBlank()) map[id] = c
        }
        return map
    }

    private fun chooseFirstVisualTrackId(tracksArray: JSONArray): String? {
        val candidates = mutableListOf<Pair<Int, String>>()
        for (i in 0 until tracksArray.length()) {
            val track = tracksArray.optJSONObject(i) ?: continue
            val id    = track.optString("id", "")
            if (id.isBlank()) continue

            val type = track.optStringFlexible("type", "trackType", "")
            if (type == "video" || type == "visual" || type == "overlay") {
                candidates += track.optIntFlexible("index", "sortIndex", i) to id
            }
        }
        return candidates.sortedBy { it.first }.firstOrNull()?.second
    }

    private fun resolveAssetPath(asset: JSONObject): String? {
        for (key in listOf("proxyPath", "previewPath", "exportPath", "originalPath", "path", "uri")) {
            val v = asset.optString(key, "")
            if (v.isNotBlank() && File(v).exists()) return v
        }
        return null
    }

    private fun parseBackgroundColor(graph: JSONObject): Int {
        val project = graph.optJSONObject("project") ?: return 0xFF000000.toInt()
        val raw     = project.optString("backgroundColor", "")
        if (raw.isBlank()) return 0xFF000000.toInt()
        return try { Color.parseColor(raw) } catch (_: Throwable) { 0xFF000000.toInt() }
    }

    // ── JSONObject extension helpers ──────────────────────────────────────────

    private fun JSONObject.optStringFlexible(primary: String, alternate: String, default: String): String {
        val a = optString(primary, ""); if (a.isNotBlank()) return a
        val b = optString(alternate, ""); if (b.isNotBlank()) return b
        return default
    }

    private fun JSONObject.optLongFlexible(primary: String, alternate: String, default: Long): Long {
        if (has(primary)) return optLong(primary, default)
        if (has(alternate)) return optLong(alternate, default)
        return default
    }

    private fun JSONObject.optIntFlexible(primary: String, alternate: String, default: Int): Int {
        if (has(primary)) return optInt(primary, default)
        if (has(alternate)) return optInt(alternate, default)
        return default
    }

    private fun JSONObject.optDoubleFlexible(primary: String, alternate: String, default: Double): Double {
        if (has(primary)) return optDouble(primary, default)
        if (has(alternate)) return optDouble(alternate, default)
        return default
    }

    private fun JSONObject.optFloatFlexible(primary: String, alternate: String, default: Float): Float =
        optDoubleFlexible(primary, alternate, default.toDouble()).toFloat()
}
