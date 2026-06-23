package com.kata.videoeditor.nle.gpu

// ── Transform ─────────────────────────────────────────────────────────────────

/**
 * Spatial transform applied to a visual layer before compositing.
 *
 * @param positionX      Normalized X offset from centre (−1 = left edge, +1 = right edge).
 * @param positionY      Normalized Y offset from centre (−1 = top, +1 = bottom).
 * @param scale          Uniform scale factor (1.0 = fill normally).
 * @param rotationDegrees Clockwise rotation in degrees.
 * @param opacity        Layer opacity 0…1.
 * @param fitMode        "fit" | "fill" | "crop" | "stretch"
 */
data class NleCompositorTransform(
    val positionX: Float = 0f,
    val positionY: Float = 0f,
    val scale: Float = 1f,
    val rotationDegrees: Float = 0f,
    val opacity: Float = 1f,
    val fitMode: String = "fit",
)

// ── Visual layer ──────────────────────────────────────────────────────────────

/**
 * One resolved visual (video / image) clip layer within a compositor frame.
 *
 * @param clipId         Source clip ID (for debugging / caching).
 * @param assetId        Asset ID this clip references.
 * @param inputPath      Absolute path of the media file to sample from.
 * @param sourceTimeMicros Frame timestamp inside the source file (µs).
 * @param transform      Spatial transform applied to this layer.
 * @param effects        Color-grading settings (brightness / contrast / saturation).
 * @param opacityOverride When non-null, overrides [transform.opacity] — used by transitions.
 */
data class NleCompositorVisualLayer(
    val clipId: String?,
    val assetId: String?,
    val inputPath: String?,
    val sourceTimeMicros: Long,
    val transform: NleCompositorTransform,
    val effects: NleCompositorEffectSettings = NleCompositorEffectSettings(),
    val opacityOverride: Float? = null,
)

// ── Frame ─────────────────────────────────────────────────────────────────────

/**
 * Complete description of one compositor output frame.
 *
 * @param projectId           Project this frame belongs to.
 * @param timelineTimeMicros  Timeline position this frame represents (µs).
 * @param backgroundColor     ARGB background fill before layers are drawn.
 * @param visualLayers        Ordered list of video/image layers (bottom → top).
 * @param textOverlays        Text overlays drawn above all visual layers.
 * @param transition          Active transition state, or null if none.
 */
data class NleCompositorFrame(
    val projectId: String,
    val timelineTimeMicros: Long,
    val backgroundColor: Int = 0xFF000000.toInt(),
    val visualLayers: List<NleCompositorVisualLayer> = emptyList(),
    val textOverlays: List<NleTextOverlay> = emptyList(),
    val transition: NleTransitionState? = null,
)
