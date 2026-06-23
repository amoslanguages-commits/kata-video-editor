package com.kata.videoeditor.nle.gpu

/**
 * Visual styling properties for a text overlay clip.
 *
 * All color values are ARGB packed ints (same format as [android.graphics.Color]).
 */
data class NleTextOverlayStyle(
    val fontSize: Float = 48f,
    /** Text fill color (ARGB). */
    val color: Int = 0xFFFFFFFF.toInt(),
    val opacity: Float = 1f,
    val strokeColor: Int = 0xFF000000.toInt(),
    val strokeWidth: Float = 0f,
    val shadowEnabled: Boolean = false,
    val shadowColor: Int = 0xAA000000.toInt(),
    val shadowBlur: Float = 8f,
    val shadowOffsetX: Float = 3f,
    val shadowOffsetY: Float = 3f,
    val backgroundEnabled: Boolean = false,
    val backgroundColor: Int = 0x66000000,
    val backgroundRadius: Float = 18f,
    /** "left" | "center" | "right" */
    val alignment: String = "center",
)

/**
 * A single text overlay clip resolved from the render graph.
 *
 * @param clipId               Unique clip ID from the graph.
 * @param text                 The text string to render (supports `\n` for newlines).
 * @param timelineStartMicros  Inclusive start time on the timeline (µs).
 * @param timelineEndMicros    Exclusive end time on the timeline (µs).
 * @param positionX            Normalized X offset from center (-1..+1).
 * @param positionY            Normalized Y offset from center (-1..+1).
 * @param scale                Uniform scale factor applied after position.
 * @param rotationDegrees      Clockwise rotation in degrees.
 * @param opacity              Layer-level opacity (0..1), multiplied with style.opacity.
 * @param style                Full text style definition.
 */
data class NleTextOverlay(
    val clipId: String,
    val text: String,
    val timelineStartMicros: Long,
    val timelineEndMicros: Long,
    val positionX: Float,
    val positionY: Float,
    val scale: Float,
    val rotationDegrees: Float,
    val opacity: Float,
    val style: NleTextOverlayStyle,
) {
    /** True when [timeMicros] is within [timelineStartMicros, timelineEndMicros). */
    fun isActive(timeMicros: Long): Boolean =
        timeMicros >= timelineStartMicros && timeMicros < timelineEndMicros
}
