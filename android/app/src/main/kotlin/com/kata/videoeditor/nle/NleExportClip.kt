package com.kata.videoeditor.nle

/**
 * Represents a single resolved clip on the export timeline.
 *
 * @param clipId            Unique ID from the render graph.
 * @param assetId           Asset referenced by this clip.
 * @param sourcePath        Absolute file path of the source media.
 * @param timelineStartMicros  When this clip begins on the output timeline (µs).
 * @param timelineEndMicros    When this clip ends on the output timeline (µs).
 * @param sourceInMicros    Trim-in point within the source file (µs).
 * @param sourceOutMicros   Trim-out point within the source file (µs).
 */
data class NleExportClip(
    val clipId: String,
    val assetId: String,
    val sourcePath: String,
    val timelineStartMicros: Long,
    val timelineEndMicros: Long,
    val sourceInMicros: Long,
    val sourceOutMicros: Long
) {
    /** Duration this clip occupies on the output timeline (µs). */
    val timelineDurationMicros: Long get() = timelineEndMicros - timelineStartMicros

    /** Duration of source content used by this clip (µs). */
    val sourceDurationMicros: Long get() = sourceOutMicros - sourceInMicros
}

/**
 * Ordered sequence of [NleExportClip] objects that form the export output.
 *
 * @param clips            Clips in ascending [NleExportClip.timelineStartMicros] order.
 * @param totalDurationMicros  Total duration of the final output (µs).
 * @param renderGraphJson  The original render-graph JSON used to build this timeline
 *                         (forwarded to the GPU compositor for frame resolution).
 */
data class NleExportTimeline(
    val clips: List<NleExportClip>,
    val totalDurationMicros: Long,
    val renderGraphJson: String = ""
)
