package com.nle.editor.preview

enum class NlePreviewQualityMode {
    AUTO,
    PERFORMANCE,
    BALANCED,
    QUALITY,
}

enum class NlePreviewState {
    IDLE,
    PREPARING,
    READY,
    PLAYING,
    PAUSED,
    STOPPED,
    ERROR,
}

data class NlePreviewConfig(
    val projectId: String,
    val renderGraphJson: String,
    val qualityMode: NlePreviewQualityMode = NlePreviewQualityMode.AUTO,
    val preferProxy: Boolean = true,
    val maxPreviewWidth: Int = 1280,
    val maxPreviewHeight: Int = 720,
)

data class NlePreviewOutputSize(
    val width: Int,
    val height: Int,
)

data class NlePreviewFrameResult(
    val rendered: Boolean,
    val timelineTimeUs: Long,
    val dropped: Boolean = false,
    val reason: String? = null,
)
