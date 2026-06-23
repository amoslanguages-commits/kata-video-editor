package com.nle.editor.colorpipeline

import android.opengl.GLES20
import com.nle.editor.color.NleColorPipelineUniformBinder
import com.nle.editor.color.NleResolvedColorPipeline

class NleOutputDisplayTransformPass(
    private val colorManagementGlsl: String,
) : NleColorPass {
    override val id: String = "output_display_transform"
    override val label: String = "Output Display Transform"
    override val enabled: Boolean = true

    private val quad = NleFullscreenQuad()
    private val uniformBinder = NleColorPipelineUniformBinder()

    private val program = NleShaderProgram(
        vertexShaderSource = NleColorPipelineShaders.fullscreenVertex,
        fragmentShaderSource = NleColorPipelineShaders.outputDisplayTransformFragment(
            colorManagementGlsl,
        ),
    )

    override fun prepare() {
        program.compile()
    }

    override fun render(
        inputTextureId: Int,
        destination: NleGpuFramebuffer,
        pipeline: NleResolvedColorPipeline,
    ) {
        destination.bind()

        GLES20.glDisable(GLES20.GL_BLEND)
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        program.use()

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, inputTextureId)

        val textureLoc = GLES20.glGetUniformLocation(program.programId, "uTexture")
        if (textureLoc >= 0) {
            GLES20.glUniform1i(textureLoc, 0)
        }

        uniformBinder.bind(
            programId = program.programId,
            pipeline = pipeline,
            assetId = null,
            forExport = false,
        )

        quad.draw(program.programId)

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)

        NleGlError.check("NleOutputDisplayTransformPass.render")
    }

    override fun release() {
        program.release()
    }
}
