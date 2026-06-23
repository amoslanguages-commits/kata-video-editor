package com.nle.editor.preview

interface NlePreviewEventSink {
    fun onPreviewTextureReady(
        textureId: Long,
        width: Int,
        height: Int,
    )

    fun onPreviewFrameRendered(
        timelineTimeUs: Long,
    )

    fun onPreviewDroppedFrame(
        timelineTimeUs: Long,
        reason: String,
    )

    fun onPreviewEnded()

    fun onPreviewError(
        message: String,
    )

    fun onColorPipelineStats(
        passCount: Int,
        format: String,
        precision: String,
        usedFallback: Boolean,
        fallbackReason: String?,
    )
}
