package com.nle.editor.colorpipeline

enum class NleGpuRenderFormat {
    RGBA8,
    RGBA16F,
    RGBA32F,
}

enum class NleColorPassPrecision {
    COMPATIBILITY_8BIT,
    HALF_FLOAT_16F,
    FULL_FLOAT_32F,
}

enum class NleGpuPipelineMode {
    PREVIEW,
    EXPORT,
}

data class NleGpuRenderFormatInfo(
    val format: NleGpuRenderFormat,
    val internalFormat: Int,
    val formatEnum: Int,
    val typeEnum: Int,
    val precision: NleColorPassPrecision,
    val supportsLinearFiltering: Boolean,
    val description: String,
)

data class NleColorPipelineRenderTargetSpec(
    val width: Int,
    val height: Int,
    val format: NleGpuRenderFormat,
    val precision: NleColorPassPrecision,
    val useDepth: Boolean = false,
    val useStencil: Boolean = false,
)

data class NleColorPipelineResolvedConfig(
    val mode: NleGpuPipelineMode,
    val workingFormat: NleGpuRenderFormat,
    val precision: NleColorPassPrecision,
    val width: Int,
    val height: Int,
    val usePingPong: Boolean,
    val enableDither: Boolean,
    val enableBandingProtection: Boolean,
    val fallbackReason: String?,
)

data class NleColorPipelineStats(
    val passCount: Int,
    val format: NleGpuRenderFormat,
    val precision: NleColorPassPrecision,
    val width: Int,
    val height: Int,
    val usedFallback: Boolean,
    val fallbackReason: String?,
)
