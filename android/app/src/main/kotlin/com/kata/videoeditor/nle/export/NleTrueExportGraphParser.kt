package com.kata.videoeditor.nle.export

import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class NleTrueExportGraphParser {

    fun parse(
        projectId: String,
        renderGraphJson: String,
        outputWidth: Int,
        outputHeight: Int,
        frameRate: Int,
        preferProxy: Boolean = false,
    ): NleTrueExportTimeline {
        val root    = JSONObject(renderGraphJson)
        val project = root.optJSONObject("project") ?: root
        val assetsArray = root.optJSONArray("assets") ?: project.optJSONArray("assets") ?: JSONArray()
        val tracksArray = root.optJSONArray("tracks") ?: project.optJSONArray("tracks") ?: JSONArray()
        val clipsArray = root.optJSONArray("clips") ?: project.optJSONArray("clips") ?: JSONArray()

        val assets = parseAssets(assetsArray, preferProxy)
        val visualTrackIds = parseVisualTrackIds(tracksArray)
        val clips = parseVisualClips(clipsArray, tracksArray, visualTrackIds)
        if (clips.isEmpty()) throw IllegalStateException("No visual clips found in render graph for V2 export.")

        val durationUs = project.optLong("durationMicros", clips.maxOfOrNull { it.timelineEndUs } ?: 0L)
        return NleTrueExportTimeline(
            projectId = projectId,
            durationUs = durationUs,
            width = outputWidth,
            height = outputHeight,
            frameRate = frameRate,
            backgroundColor = parseBackgroundColor(project.optString("backgroundColor", "#000000")),
            assetsById = assets,
            visualClips = clips.sortedBy { it.timelineStartUs },
        )
    }

    private fun parseAssets(array: JSONArray, preferProxy: Boolean): Map<String, NleTrueExportAsset> {
        val result = linkedMapOf<String, NleTrueExportAsset>()
        for (i in 0 until array.length()) {
            val obj = array.optJSONObject(i) ?: continue
            val id = obj.optString("id")
            if (id.isBlank()) continue
            val path = resolveAssetPath(obj, preferProxy)
            if (path.isBlank()) continue
            result[id] = NleTrueExportAsset(
                id = id,
                path = path,
                width = obj.optIntAny("width", "naturalWidth", default = 0),
                height = obj.optIntAny("height", "naturalHeight", default = 0),
                durationUs = obj.optLongAny("durationMicros", "duration_micros", default = 0L),
                hasVideo = obj.optBoolean("hasVideo", true),
                hasAudio = obj.optBoolean("hasAudio", true),
            )
        }
        return result
    }

    private fun resolveAssetPath(obj: JSONObject, preferProxy: Boolean): String {
        val proxyCandidates = listOf(obj.optString("proxyPath", ""), obj.optString("proxy_uri", ""))
        val originalCandidates = listOf(
            obj.optString("exportPath", ""),
            obj.optString("sourcePath", ""),
            obj.optString("originalPath", ""),
            obj.optString("filePath", ""),
            obj.optString("path", ""),
            obj.optString("uri", ""),
        )
        val candidates = if (preferProxy) proxyCandidates + originalCandidates else originalCandidates + proxyCandidates
        for (candidate in candidates) {
            if (candidate.isBlank()) continue
            if (candidate.startsWith("content://")) return candidate
            if (File(candidate).exists()) return candidate
        }
        return candidates.firstOrNull { it.isNotBlank() } ?: ""
    }

    private fun parseVisualTrackIds(tracks: JSONArray): Set<String> {
        val ids = mutableSetOf<String>()
        for (i in 0 until tracks.length()) {
            val track = tracks.optJSONObject(i) ?: continue
            val type = track.optString("trackType", track.optString("type", "video"))
            if (type == "video" || type == "visual" || type == "main" || type == "overlay" || type == "text" || type == "adjustment") {
                val id = track.optString("id")
                if (id.isNotBlank()) ids.add(id)
            }
        }
        return ids
    }

    private fun parseVisualClips(topLevelClips: JSONArray, tracks: JSONArray, visualTrackIds: Set<String>): List<NleTrueExportClip> {
        val clips = mutableListOf<NleTrueExportClip>()
        parseClipArray(topLevelClips, null, visualTrackIds, clips)
        for (i in 0 until tracks.length()) {
            val track = tracks.optJSONObject(i) ?: continue
            val trackId = track.optString("id")
            val type = track.optString("trackType", track.optString("type", "video"))
            val isVisualTrack = visualTrackIds.contains(trackId) || type == "video" || type == "visual" || type == "main" || type == "overlay" || type == "text" || type == "adjustment"
            if (!isVisualTrack) continue
            parseClipArray(track.optJSONArray("clips") ?: JSONArray(), trackId, visualTrackIds, clips)
        }
        return clips
    }

    private fun parseClipArray(array: JSONArray, fallbackTrackId: String?, visualTrackIds: Set<String>, output: MutableList<NleTrueExportClip>) {
        for (c in 0 until array.length()) {
            val clip = array.optJSONObject(c) ?: continue
            if (clip.optBoolean("isDisabled", false)) continue
            val trackId = clip.optStringAny("trackId", "track_id", default = fallbackTrackId ?: "")
            if (fallbackTrackId == null && visualTrackIds.isNotEmpty() && trackId.isNotBlank() && !visualTrackIds.contains(trackId)) continue
            val clipType = clip.optStringAny("clipType", "type", default = "video")
            if (clipType != "video" && clipType != "image" && clipType != "text" && clipType != "adjustment") continue
            val assetId = clip.optStringAny("assetId", "asset_id", default = "")
            if (assetId.isBlank() && clipType != "text") continue
            val startUs = clip.optLongAny("timelineStartMicros", "timeline_start_micros", "startMicros", default = 0L)
            val endUs = clip.optLongAny("timelineEndMicros", "timeline_end_micros", "endMicros", default = 0L)
            if (endUs <= startUs) continue
            val sourceStartUs = clip.optLongAny("sourceInMicros", "source_in_micros", "sourceStartMicros", "trimStartMicros", default = 0L)
            val sourceEndUs = clip.optLongAny("sourceOutMicros", "source_out_micros", "sourceEndMicros", "trimEndMicros", default = sourceStartUs + (endUs - startUs))
            output.add(
                NleTrueExportClip(
                    id = clip.optStringAny("id", "clipId", default = "clip_$c"),
                    trackId = trackId,
                    assetId = assetId,
                    clipType = clipType,
                    timelineStartUs = startUs,
                    timelineEndUs = endUs,
                    sourceStartUs = sourceStartUs,
                    sourceEndUs = sourceEndUs,
                    speed = clip.optDouble("speed", 1.0).coerceAtLeast(0.01),
                    positionX = clip.optFloatAny("positionX", default = 0f),
                    positionY = clip.optFloatAny("positionY", default = 0f),
                    scale = clip.optFloatAny("scale", default = 1f),
                    rotation = clip.optFloatAny("rotation", default = 0f),
                    opacity = clip.optFloatAny("opacity", default = 1f),
                    brightness = clip.optFloatAny("brightness", default = 0f),
                    contrast = clip.optFloatAny("contrast", default = 1f),
                    saturation = clip.optFloatAny("saturation", default = 1f),
                    fitMode = clip.optStringAny("fitMode", default = "fit"),
                )
            )
        }
    }

    private fun parseBackgroundColor(color: String): FloatArray {
        val clean = color.trim().removePrefix("#")
        val hex = if (clean.length == 6) "FF$clean" else clean.padStart(8, 'F')
        val value = runCatching { hex.toLong(16).toInt() }.getOrDefault(0xFF000000.toInt())
        val a = ((value ushr 24) and 0xFF) / 255f
        val r = ((value ushr 16) and 0xFF) / 255f
        val g = ((value ushr 8) and 0xFF) / 255f
        val b = (value and 0xFF) / 255f
        return floatArrayOf(r, g, b, a)
    }
}

private fun JSONObject.optStringAny(vararg names: String, default: String = ""): String {
    for (name in names) {
        val value = optString(name, "")
        if (value.isNotBlank()) return value
    }
    return default
}

private fun JSONObject.optLongAny(vararg names: String, default: Long = 0L): Long {
    for (name in names) if (has(name)) return optLong(name, default)
    return default
}

private fun JSONObject.optIntAny(vararg names: String, default: Int = 0): Int {
    for (name in names) if (has(name)) return optInt(name, default)
    return default
}

private fun JSONObject.optFloatAny(vararg names: String, default: Float = 0f): Float {
    for (name in names) if (has(name)) return optDouble(name, default.toDouble()).toFloat()
    return default
}
