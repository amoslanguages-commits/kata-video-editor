package com.kata.videoeditor.nle

import org.json.JSONArray
import org.json.JSONObject

/**
 * Parses the render graph JSON produced by the Dart [RenderGraphService] and
 * extracts the information needed to drive a native export.
 *
 * V1 strategy:
 *   • Choose the **visual track** with the lowest track index (first video
 *     track, ignoring audio-only or text-only tracks).
 *   • Resolve each clip on that track to an absolute file path via the
 *     asset look-up table.
 *   • Return an [NleExportTimeline] whose clips are sorted ascending by
 *     [NleExportClip.timelineStartMicros].
 *
 * Track-type detection heuristic:
 *   A track is considered "visual" when at least one of its clips has
 *   `type == "video"` or `type == "image"`.
 */
class NleRenderGraphExportParser {

    /**
     * Parse [renderGraphJson] and return an [NleExportTimeline].
     *
     * @throws IllegalArgumentException if no visual clips can be found or if
     *         a required asset is missing from the asset table.
     */
    fun parse(renderGraphJson: String): NleExportTimeline {
        val root   = JSONObject(renderGraphJson)
        val assets = buildAssetPathMap(root.optJSONArray("assets") ?: JSONArray())
        val tracks = root.optJSONArray("tracks") ?: JSONArray()
        val clips  = root.optJSONArray("clips")  ?: JSONArray()

        // Group clips by trackId
        val clipsByTrack = mutableMapOf<String, MutableList<JSONObject>>()
        for (i in 0 until clips.length()) {
            val clip = clips.optJSONObject(i) ?: continue
            val trackId = clip.optString("trackId", "")
            if (trackId.isBlank()) continue
            clipsByTrack.getOrPut(trackId) { mutableListOf() }.add(clip)
        }

        // Find the first visual track (lowest index that has video/image clips)
        data class TrackCandidate(val index: Int, val id: String)
        val candidates = mutableListOf<TrackCandidate>()
        for (i in 0 until tracks.length()) {
            val track   = tracks.optJSONObject(i) ?: continue
            val trackId = track.optString("id", "")
            if (trackId.isBlank()) continue

            val trackClips = clipsByTrack[trackId] ?: continue
            val hasVisual  = trackClips.any { c ->
                val type = c.optString("type", c.optString("clipType", ""))
                type == "video" || type == "image"
            }
            if (hasVisual) {
                val index = track.optInt("index", i)
                candidates.add(TrackCandidate(index, trackId))
            }
        }

        if (candidates.isEmpty()) {
            throw IllegalArgumentException(
                "${NleNativeErrorCode.EXPORT_NO_CLIPS}: No visual track found in render graph."
            )
        }

        // Pick the lowest-index visual track
        val bestTrackId = candidates.minBy { it.index }.id
        val rawClips    = clipsByTrack[bestTrackId]
            ?: throw IllegalArgumentException(
                "${NleNativeErrorCode.EXPORT_NO_CLIPS}: Visual track $bestTrackId has no clips."
            )

        // Build export clips
        val exportClips = mutableListOf<NleExportClip>()
        for (raw in rawClips) {
            val clipType = raw.optString("type", raw.optString("clipType", ""))
            if (clipType != "video" && clipType != "image") continue

            val clipId  = raw.optString("id", "")
            val assetId = raw.optString("assetId", "")
            if (assetId.isBlank()) continue

            val sourcePath = assets[assetId]
            if (sourcePath.isNullOrBlank()) {
                throw IllegalArgumentException(
                    "${NleNativeErrorCode.EXPORT_MISSING_ASSET}: Asset $assetId for clip $clipId not found."
                )
            }

            val timelineStart = raw.optLong("timelineStartMicros", 0L)
            val timelineEnd   = raw.optLong("timelineEndMicros",   0L)
            if (timelineEnd <= timelineStart) continue  // degenerate clip

            val sourceIn  = raw.optLong("sourceInMicros",  0L)
            val sourceOut = raw.optLong("sourceOutMicros", timelineEnd - timelineStart)

            exportClips.add(
                NleExportClip(
                    clipId              = clipId,
                    assetId             = assetId,
                    sourcePath          = sourcePath,
                    timelineStartMicros = timelineStart,
                    timelineEndMicros   = timelineEnd,
                    sourceInMicros      = sourceIn,
                    sourceOutMicros     = if (sourceOut > sourceIn) sourceOut else sourceIn + (timelineEnd - timelineStart)
                )
            )
        }

        if (exportClips.isEmpty()) {
            throw IllegalArgumentException(
                "${NleNativeErrorCode.EXPORT_NO_CLIPS}: No renderable clips found on visual track."
            )
        }

        exportClips.sortBy { it.timelineStartMicros }
        val totalDuration = exportClips.maxOf { it.timelineEndMicros }

        return NleExportTimeline(
            clips               = exportClips,
            totalDurationMicros = totalDuration,
            renderGraphJson     = renderGraphJson
        )
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    /** Builds a map of assetId → absolute file path from the assets array. */
    private fun buildAssetPathMap(assets: JSONArray): Map<String, String> {
        val map = mutableMapOf<String, String>()
        for (i in 0 until assets.length()) {
            val asset   = assets.optJSONObject(i) ?: continue
            val id      = asset.optString("id", "")
            // The render graph stores the file path in "sourcePath" or "originalPath"
            val path    = asset.optString("sourcePath", "")
                .ifBlank { asset.optString("originalPath", "") }
                .ifBlank { asset.optString("filePath", "") }
            if (id.isNotBlank() && path.isNotBlank()) {
                map[id] = path
            }
        }
        return map
    }
}
