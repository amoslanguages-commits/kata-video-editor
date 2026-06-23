package com.kata.videoeditor.nle.audio

import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class NleRenderGraphAudioParser {
    fun parse(
        projectId: String,
        renderGraphJson: String,
        fallbackDurationMicros: Long,
    ): NleAudioTimeline {
        val graph = JSONObject(renderGraphJson)

        val assets = graph.optJSONArray("assets") ?: JSONArray()
        val tracks = graph.optJSONArray("tracks") ?: JSONArray()
        val clips = graph.optJSONArray("clips") ?: JSONArray()

        val assetsById = buildAssetsMap(assets)
        val trackStates = buildTrackStates(tracks)
        val anySolo = trackStates.values.any { it.solo }

        val audioClips = mutableListOf<NleAudioClip>()

        for (i in 0 until clips.length()) {
            val clip = clips.optJSONObject(i) ?: continue

            val clipType = clip.optStringFlexible("clipType", "type", "video")
            val isAudioCapable = clipType == "audio" || clipType == "video"

            if (!isAudioCapable) {
                continue
            }

            val assetId = clip.optStringFlexible("assetId", "asset_id", "")
            if (assetId.isBlank()) continue

            val asset = assetsById[assetId] ?: continue

            val hasAudio = asset.optBoolean("hasAudio", clipType == "audio")
            if (!hasAudio) continue

            val trackId = clip.optStringFlexible("trackId", "track_id", "")
            val trackState = trackStates[trackId] ?: NleAudioTrackState(trackId = trackId)

            if (trackState.muted) continue
            if (anySolo && !trackState.solo) continue

            val inputPath = resolveAssetPath(asset)
            if (inputPath == null || !File(inputPath).exists()) continue

            val start = clip.optLongFlexible("timelineStartMicros", "timeline_start_micros", 0L)
            val end = clip.optLongFlexible("timelineEndMicros", "timeline_end_micros", 0L)

            if (end <= start) continue

            val sourceIn = clip.optLongFlexible("sourceInMicros", "source_in_micros", 0L)
            val sourceOut = clip.optLongFlexible(
                "sourceOutMicros",
                "source_out_micros",
                sourceIn + (end - start)
            )

            audioClips.add(
                NleAudioClip(
                    clipId = clip.optString("id", "audio_clip_$i"),
                    assetId = assetId,
                    trackId = trackId,
                    inputPath = inputPath,
                    timelineStartMicros = start,
                    timelineEndMicros = end,
                    sourceInMicros = sourceIn,
                    sourceOutMicros = sourceOut,
                    clipVolume = clip.optFloatFlexible("volume", "audioVolume", 1f)
                        .coerceIn(0f, 4f),
                    trackVolume = trackState.volume.coerceIn(0f, 4f),
                    fadeInMicros = clip.optLongFlexible("fadeInMicros", "audioFadeInMicros", 0L)
                        .coerceAtLeast(0L),
                    fadeOutMicros = clip.optLongFlexible("fadeOutMicros", "audioFadeOutMicros", 0L)
                        .coerceAtLeast(0L),
                    speed = clip.optDoubleFlexible("speed", "playbackSpeed", 1.0)
                        .coerceIn(0.25, 4.0)
                )
            )
        }

        val duration = maxOf(
            fallbackDurationMicros,
            audioClips.maxOfOrNull { it.timelineEndMicros } ?: 0L
        )

        return NleAudioTimeline(
            projectId = projectId,
            durationMicros = duration,
            clips = audioClips.sortedBy { it.timelineStartMicros }
        )
    }

    private fun buildAssetsMap(array: JSONArray): Map<String, JSONObject> {
        val map = mutableMapOf<String, JSONObject>()

        for (i in 0 until array.length()) {
            val asset = array.optJSONObject(i) ?: continue
            val id = asset.optString("id", "")

            if (id.isNotBlank()) {
                map[id] = asset
            }
        }

        return map
    }

    private fun buildTrackStates(array: JSONArray): Map<String, NleAudioTrackState> {
        val map = mutableMapOf<String, NleAudioTrackState>()

        for (i in 0 until array.length()) {
            val track = array.optJSONObject(i) ?: continue
            val id = track.optString("id", "")
            if (id.isBlank()) continue

            map[id] = NleAudioTrackState(
                trackId = id,
                volume = track.optDouble("volume", 1.0).toFloat(),
                muted = track.optBoolean("mute", track.optBoolean("muted", false)),
                solo = track.optBoolean("solo", false)
            )
        }

        return map
    }

    private fun resolveAssetPath(asset: JSONObject): String? {
        val keys = listOf(
            "proxyPath",
            "previewPath",
            "exportPath",
            "originalPath",
            "path",
            "uri"
        )

        for (key in keys) {
            val value = asset.optString(key, "")

            if (value.isNotBlank() && File(value).exists()) {
                return value
            }
        }

        return null
    }

    private fun JSONObject.optStringFlexible(
        primary: String,
        alternate: String,
        default: String,
    ): String {
        val a = optString(primary, "")
        if (a.isNotBlank()) return a

        val b = optString(alternate, "")
        if (b.isNotBlank()) return b

        return default
    }

    private fun JSONObject.optLongFlexible(
        primary: String,
        alternate: String,
        default: Long,
    ): Long {
        if (has(primary)) return optLong(primary, default)
        if (has(alternate)) return optLong(alternate, default)
        return default
    }

    private fun JSONObject.optDoubleFlexible(
        primary: String,
        alternate: String,
        default: Double,
    ): Double {
        if (has(primary)) return optDouble(primary, default)
        if (has(alternate)) return optDouble(alternate, default)
        return default
    }

    private fun JSONObject.optFloatFlexible(
        primary: String,
        alternate: String,
        default: Float,
    ): Float {
        return optDoubleFlexible(primary, alternate, default.toDouble()).toFloat()
    }
}
