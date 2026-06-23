package com.nle.editor.colorpipeline

import com.nle.editor.color.NleResolvedColorPipeline

interface NleColorPass {
    val id: String
    val label: String
    val enabled: Boolean

    fun prepare()

    fun render(
        inputTextureId: Int,
        destination: NleGpuFramebuffer,
        pipeline: NleResolvedColorPipeline,
    )

    fun release()
}
