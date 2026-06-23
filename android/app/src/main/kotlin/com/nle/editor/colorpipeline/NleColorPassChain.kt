package com.nle.editor.colorpipeline

import com.nle.editor.color.NleResolvedColorPipeline

class NleColorPassChain {
    private val passes = mutableListOf<NleColorPass>()

    var lastSceneLinearTextureId: Int = 0
        private set

    val passCount: Int
        get() = passes.count { it.enabled }

    fun setPasses(next: List<NleColorPass>) {
        release()
        passes.clear()
        passes.addAll(next)
        prepare()
    }

    fun setPassesDirectly(next: List<NleColorPass>) {
        passes.clear()
        passes.addAll(next)
    }

    fun addPass(pass: NleColorPass) {
        passes.add(pass)
        pass.prepare()
    }

    fun prepare() {
        for (pass in passes) {
            pass.prepare()
        }
    }

    fun render(
        initialTextureId: Int,
        targets: NlePingPongRenderTargets,
        pipeline: NleResolvedColorPipeline,
    ): Int {
        var currentTexture = initialTextureId
        lastSceneLinearTextureId = 0

        for (pass in passes) {
            if (!pass.enabled) continue

            if (pass.id == "output_display_transform") {
                lastSceneLinearTextureId = currentTexture
            }

            val destination = targets.destination

            pass.render(
                inputTextureId = currentTexture,
                destination = destination,
                pipeline = pipeline,
            )

            targets.swap()
            currentTexture = targets.source.textureId
        }

        // If we didn't hit a display transform pass, default scene linear to the final texture
        if (lastSceneLinearTextureId == 0) {
            lastSceneLinearTextureId = currentTexture
        }

        return currentTexture
    }

    fun release() {
        for (pass in passes) {
            pass.release()
        }
        passes.clear()
        lastSceneLinearTextureId = 0
    }
}
