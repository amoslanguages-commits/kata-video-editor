package com.kata.videoeditor.nle.export

import kotlin.math.max

/**
 * Source asset (video/image file) used by the V2 true-decoder export pipeline.
 *
 * [path] is the file-system path or `content://` URI for [MediaExtractor].
 */
data class NleTrueExportAsset(
    val id: String,
    val path: String,
    val width: Int,
    val height: Int,
    val durationUs: Long,
    val hasVideo: Boolean,
    val hasAudio: Boolean,
)

/**
 * A single clip on the timeline that carries transform, color, and speed metadata.
 *
 * All time values are in microseconds.
 */
data class NleTrueExportClip(
    val id: String,
    val trackId: String,
    val assetId: String?,
    val clipType: String = "video",
    val textContent: String? = null,
    val textStyle: String? = null,
    val timelineStartUs: Long,
    val timelineEndUs: Long,
    val sourceStartUs: Long,
    val sourceEndUs: Long,
    val speed: Double,
    val positionX: Float,
    val positionY: Float,
    val scale: Float,
    val rotation: Float,
    val opacity: Float,
    val brightness: Float,
    val contrast: Float,
    val saturation: Float,
    val fitMode: String,
) {
    val durationUs: Long get() = timelineEndUs - timelineStartUs

    /** Returns true when [timelineTimeUs] falls within [timelineStartUs, timelineEndUs). */
    fun containsTimelineTime(timelineTimeUs: Long): Boolean =
        timelineTimeUs >= timelineStartUs && timelineTimeUs < timelineEndUs

    /**
     * Maps a timeline position to the corresponding source timestamp, accounting for
     * [speed] and [sourceStartUs] offset.
     */
    fun sourceTimeForTimeline(timelineTimeUs: Long): Long {
        val localUs  = (timelineTimeUs - timelineStartUs).coerceAtLeast(0L)
        val scaledUs = (localUs * speed).toLong()
        return (sourceStartUs + scaledUs).coerceIn(sourceStartUs, sourceEndUs)
    }
}

/**
 * A resolved layer that is active at a specific timeline position.
 */
data class NleTrueExportLayer(
    val asset: NleTrueExportAsset?,
    val clip: NleTrueExportClip,
    val sourceTimeUs: Long,
    val opacity: Float,
)

/**
 * The full V2 export timeline: a collection of clips and assets, plus output dimensions.
 */
data class NleTrueExportTimeline(
    val projectId: String,
    val durationUs: Long,
    val width: Int,
    val height: Int,
    val frameRate: Int,
    val backgroundColor: FloatArray,
    val assetsById: Map<String, NleTrueExportAsset>,
    val visualClips: List<NleTrueExportClip>,
) {
    /**
     * Helper to determine z-order of a clip.
     * Lower values are background, higher values are foreground.
     */
    private fun getZOrder(clip: NleTrueExportClip): Int {
        return when (clip.clipType.lowercase()) {
            "adjustment" -> 40
            "text" -> 30
            "image" -> 20
            else -> {
                if (clip.trackId.contains("overlay")) 20
                else if (clip.trackId.contains("text")) 30
                else 10
            }
        }
    }

    /**
     * Returns the ordered list of [NleTrueExportLayer]s that are active at [timelineTimeUs],
     * sorted bottom-to-top by z-order.
     */
    fun resolveLayersAt(timelineTimeUs: Long): List<NleTrueExportLayer> {
        val activeClips = visualClips
            .filter { it.containsTimelineTime(timelineTimeUs) }
            .sortedWith(compareBy({ getZOrder(it) }, { it.timelineStartUs }))

        return activeClips.mapNotNull { clip ->
            val asset = if (clip.clipType == "text") null else assetsById[clip.assetId]
            if (clip.clipType != "text" && asset == null) return@mapNotNull null

            NleTrueExportLayer(
                asset = asset,
                clip = clip,
                sourceTimeUs = clip.sourceTimeForTimeline(timelineTimeUs),
                opacity = clip.opacity,
            )
        }
    }
}
