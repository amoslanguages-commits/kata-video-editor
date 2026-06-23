package com.kata.videoeditor.nle.export

import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import kotlin.math.max

/**
 * Parses the NLE render-graph JSON into the V2 [NleTrueExportTimeline] model.
 *
 * Supports the same JSON schema consumed by the V1 [com.kata.videoeditor.nle.NleRenderGraphExportParser],
 * but produces the richer V2 domain objects that include per-clip transform, color,
 * speed, and fit-mode metadata.
 *
 * Asset path resolution order (prefers originals over proxies):
 *   `exportPath` → `originalPath` → `path` → `uri`
 */
class NleTrueExportGraphParser {

    fun parse(
        projectId: String,
        renderGraphJson: String,
        outputWidth: Int,
        outputHeight: Int,
        frameRate: Int,
    ): NleTrueExportTimeline {
        val root    = JSONObject(renderGraphJson)
        val project = root.optJSONObject("project") ?: root

        val assetsArray = root.optJSONArray("assets")
            ?: project.optJSONArray("assets")
            ?: JSONArray()

        val tracksArray = root.optJSONArray("tracks")
            ?: project.optJSONArray("tracks")
            ?: JSONArray()
        val clipsArray = root.optJSONArray("clips")
            ?: project.optJSONArray("clips")
            ?: JSONArray()

        val assets         = parseAssets(assetsArray)
        val visualTrackIds = parseVisualTrackIds(tracksArray)
        val clips          = parseVisualClips(clipsArray, tracksArray, visualTrackIds)

        if (clips.isEmpty()) {
            throw IllegalStateException("No visual clips found in render graph for V2 export.")
        }

        val durationUs = project.optLong(
            "durationMicros",
            clips.maxOfOrNull { it.timelineEndUs } ?: 0L,
        )

        return NleTrueExportTimeline(
            projectId       = projectId,
            durationUs      = durationUs,
            width           = outputWidth,
            height          = outputHeight,
            frameRate       = frameRate,
            backgroundColor = parseBackgroundColor(project.optString("backgroundColor", "#FF000000")),
            assetsById      = assets,
            visualClips     = clips.sortedBy { it.timelineStartUs },
        )
    }

    // ── Assets ────────────────────────────────────────────────────────────────

    private fun parseAssets(array: JSONArray): Map<String, NleTrueExportAsset> {
        val result = linkedMapOf<String, NleTrueExportAsset>()

        for (i in 0 until array.length()) {
            val obj = array.optJSONObject(i) ?: continue
            val id  = obj.optString("id")
            if (id.isBlank()) continue

            val path = resolveAssetPath(obj)
            if (path.isBlank()) continue

            result[id] = NleTrueExportAsset(
                id        = id,
                path      = path,
                width     = obj.optIntAny("width", "naturalWidth", default = 0),
                height    = obj.optIntAny("height", "naturalHeight", default = 0),
                durationUs = obj.optLongAny("durationMicros", "duration_micros", default = 0L),
                hasVideo  = obj.optBoolean("hasVideo", true),
                hasAudio  = obj.optBoolean("hasAudio", true),
            )
        }

        return result
    }

    /**
     * Returns the best available file path for export.
     *
     * Preference order: exportPath → originalPath → path → uri.
     * content:// URIs are accepted as-is for MediaExtractor.
     */
    private fun resolveAssetPath(obj: JSONObject): String {
        val candidates = listOf(
            obj.optString("exportPath",   ""),
            obj.optString("sourcePath",   ""),
            obj.optString("originalPath", ""),
            obj.optString("filePath",     ""),
            obj.optString("path",         ""),
            obj.optString("uri",          ""),
        )

        for (candidate in candidates) {
            if (candidate.isBlank()) continue
            if (candidate.startsWith("content://")) return candidate
            if (File(candidate).exists()) return candidate
        }

        return candidates.firstOrNull { it.isNotBlank() } ?: ""
    }

    // ── Tracks ────────────────────────────────────────────────────────────────

    private fun parseVisualTrackIds(tracks: JSONArray): Set<String> {
        val ids = mutableSetOf<String>()

        for (i in 0 until tracks.length()) {
            val track = tracks.optJSONObject(i) ?: continue
            val type  = track.optString("trackType", track.optString("type", "video"))

            if (type == "video" || type == "visual" || type == "main" || type == "overlay" || type == "text" || type == "adjustment") {
                val id = track.optString("id")
                if (id.isNotBlank()) ids.add(id)
            }
        }

        return ids
    }

    // ── Clips ─────────────────────────────────────────────────────────────────

    private fun parseVisualClips(
        topLevelClips: JSONArray,
        tracks: JSONArray,
        visualTrackIds: Set<String>,
    ): List<NleTrueExportClip> {
        val clips = mutableListOf<NleTrueExportClip>()

        parseClipArray(
            array = topLevelClips,
            fallbackTrackId = null,
            visualTrackIds = visualTrackIds,
            output = clips,
        )

        for (i in 0 until tracks.length()) {
            val track   = tracks.optJSONObject(i) ?: continue
            val trackId = track.optString("id")
            val type    = track.optString("trackType", track.optString("type", "video"))

            val isVisualTrack = visualTrackIds.contains(trackId) ||
                type == "video" || type == "visual" || type == "main" ||
                type == "overlay" || type == "text" || type == "adjustment"

            if (!isVisualTrack) continue

            val clipArray = track.optJSONArray("clips") ?: JSONArray()
            parseClipArray(
                array = clipArray,
                fallbackTrackId = trackId,
                visualTrackIds = visualTrackIds,
                output = clips,
            )
        }

        return clips
    }

    private fun parseClipArray(
        array: JSONArray,
        fallbackTrackId: String?,
        visualTrackIds: Set<String>,
        output: MutableList<NleTrueExportClip>,
    ) {
        for (c in 0 until array.length()) {
            val clip = array.optJSONObject(c) ?: continue
            if (clip.optBoolean("isDisabled", false)) continue

            val trackId = clip.optStringAny("trackId", "track_id", default = fallbackTrackId ?: "")
            if (
                fallbackTrackId == null &&
                visualTrackIds.isNotEmpty() &&
                trackId.isNotBlank() &&
                !visualTrackIds.contains(trackId)
            ) {
                continue
            }

            val clipType = clip.optStringAny("clipType", "type", default = "video")
            if (clipType != "video" && clipType != "image" && clipType != "text" && clipType != "adjustment") continue

            val assetId = clip.optStringAny("assetId", "asset_id", default = "")
            if (assetId.isBlank() && clipType != "text") continue

            val startUs = clip.optLongAny(
                "timelineStartMicros",
                "timeline_start_micros",
                "startMicros",
                default = 0L,
            )
            val endUs = clip.optLongAny(
                "timelineEndMicros",
                "timeline_end_micros",
                "endMicros",
                default = 0L,
            )
            if (endUs <= startUs) continue

            val sourceStartUs = clip.optLongAny(
                "sourceInMicros",
                "source_in_micros",
                "sourceStartMicros",
                "trimStartMicros",
                default = 0L,
            )
            val sourceEndUs = clip.optLongAny(
                "sourceOutMicros",
                "source_out_micros",
                "sourceEndMicros",
                "trimEndMicros",
                default = sourceStartUs + (endUs - startUs),
            )

            val transform = clip.optJSONObject("transform")
            val color = clip.optJSONObject("color")
            val crop = clip.optJSONObject("crop")
            val text = clip.optJSONObject("text")

            val textContent = clip.optStringAny(
                "textContent",
                default = text?.optString("content") ?: "",
            ).ifBlank { null }
            val textStyle = clip.optStringAny(
                "textStyle",
                "textStyleJson",
                default = text?.optString("styleJson") ?: "",
            ).ifBlank { null }

            output.add(
                NleTrueExportClip(
                    id              = clip.optString("id", "clip_$c"),
                    trackId         = trackId,
                    assetId         = if (assetId.isBlank()) null else assetId,
                    clipType        = clipType,
                    textContent     = textContent,
                    textStyle       = textStyle,
                    timelineStartUs = startUs,
                    timelineEndUs   = endUs,
                    sourceStartUs   = sourceStartUs,
                    sourceEndUs     = max(sourceEndUs, sourceStartUs + 1L),
                    speed           = clip.optDoubleAny("speed", "playbackSpeed", default = 1.0).coerceAtLeast(0.01),
                    positionX       = clip.optDoubleAny("positionX", "position_x", default = transform?.optDouble("positionX", 0.0) ?: 0.0).toFloat(),
                    positionY       = clip.optDoubleAny("positionY", "position_y", default = transform?.optDouble("positionY", 0.0) ?: 0.0).toFloat(),
                    scale           = clip.optDoubleAny("scale", "transformScale", default = transform?.optDouble("scale", 1.0) ?: 1.0).toFloat(),
                    rotation        = clip.optDoubleAny("rotation", "rotationDegrees", default = transform?.optDouble("rotation", 0.0) ?: 0.0).toFloat(),
                    opacity         = clip.optDoubleAny("opacity", "alpha", default = transform?.optDouble("opacity", 1.0) ?: 1.0).toFloat(),
                    brightness      = clip.optDoubleAny("brightness", "exposure", default = color?.optDoubleAny("brightness", "exposure", default = 0.0) ?: 0.0).toFloat(),
                    contrast        = clip.optDoubleAny("contrast", default = color?.optDouble("contrast", 1.0) ?: 1.0).toFloat(),
                    saturation      = clip.optDoubleAny("saturation", default = color?.optDouble("saturation", 1.0) ?: 1.0).toFloat(),
                    fitMode         = clip.optStringAny("fitMode", default = crop?.optString("fitMode", "fit") ?: "fit"),
                )
            )
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Parses a hex color string (with or without #, AARRGGBB or RRGGBB) into
     * a [FloatArray] of [r, g, b, a] in [0, 1] range.
     */
    private fun parseBackgroundColor(value: String): FloatArray {
        val clean = value.removePrefix("#").trim()

        val argb = try {
            clean.toLong(16)
        } catch (_: Throwable) {
            0xFF000000L
        }

        val a: Int
        val r: Int
        val g: Int
        val b: Int

        if (clean.length >= 8) {
            a = ((argb shr 24) and 0xFF).toInt()
            r = ((argb shr 16) and 0xFF).toInt()
            g = ((argb shr 8)  and 0xFF).toInt()
            b = (argb          and 0xFF).toInt()
        } else {
            a = 255
            r = ((argb shr 16) and 0xFF).toInt()
            g = ((argb shr 8)  and 0xFF).toInt()
            b = (argb          and 0xFF).toInt()
        }

        return floatArrayOf(r / 255f, g / 255f, b / 255f, a / 255f)
    }

    private fun JSONObject.optStringAny(vararg keys: String, default: String = ""): String {
        for (key in keys) {
            if (has(key) && !isNull(key)) {
                return optString(key, default)
            }
        }
        return default
    }

    private fun JSONObject.optLongAny(vararg keys: String, default: Long): Long {
        for (key in keys) {
            if (has(key) && !isNull(key)) {
                return optLong(key, default)
            }
        }
        return default
    }

    private fun JSONObject.optIntAny(vararg keys: String, default: Int): Int {
        for (key in keys) {
            if (has(key) && !isNull(key)) {
                return optInt(key, default)
            }
        }
        return default
    }

    private fun JSONObject.optDoubleAny(vararg keys: String, default: Double): Double {
        for (key in keys) {
            if (has(key) && !isNull(key)) {
                return optDouble(key, default)
            }
        }
        return default
    }
}
