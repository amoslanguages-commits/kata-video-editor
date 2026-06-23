package com.nle.editor.colorpipeline

class NlePingPongRenderTargets(
    private val resolver: NleGpuRenderFormatResolver = NleGpuRenderFormatResolver(),
) {
    private var targetA: NleGpuFramebuffer? = null
    private var targetB: NleGpuFramebuffer? = null
    private var currentSourceIsA = true

    val source: NleGpuFramebuffer
        get() = if (currentSourceIsA) requireNotNull(targetA) else requireNotNull(targetB)

    val destination: NleGpuFramebuffer
        get() = if (currentSourceIsA) requireNotNull(targetB) else requireNotNull(targetA)

    fun create(config: NleColorPipelineResolvedConfig) {
        release()

        val info = resolver.formatInfo(config.workingFormat)

        val texA = NleGpuFloatTexture(
            width = config.width,
            height = config.height,
            info = info,
        )

        val texB = NleGpuFloatTexture(
            width = config.width,
            height = config.height,
            info = info,
        )

        targetA = NleGpuFramebuffer(texA).also { it.create() }
        targetB = NleGpuFramebuffer(texB).also { it.create() }

        currentSourceIsA = true
    }

    fun swap() {
        currentSourceIsA = !currentSourceIsA
    }

    fun resetSourceToA() {
        currentSourceIsA = true
    }

    fun release() {
        targetA?.texture?.release()
        targetB?.texture?.release()
        targetA?.release()
        targetB?.release()
        targetA = null
        targetB = null
        currentSourceIsA = true
    }
}
