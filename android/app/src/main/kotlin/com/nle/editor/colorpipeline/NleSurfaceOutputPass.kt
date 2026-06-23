package com.nle.editor.colorpipeline

import android.opengl.GLES20

class NleSurfaceOutputPass(
    private val colorManagementGlsl: String,
) {
    private val quad = NleFullscreenQuad()

    private val program = NleShaderProgram(
        vertexShaderSource = NleColorPipelineShaders.fullscreenVertex,
        fragmentShaderSource = NleColorPipelineShaders.passthroughFragment(
            colorManagementGlsl,
        ),
    )

    fun prepare() {
        program.compile()
    }

    fun renderToCurrentSurface(
        inputTextureId: Int,
        surfaceWidth: Int,
        surfaceHeight: Int,
    ) {
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        GLES20.glViewport(0, 0, surfaceWidth, surfaceHeight)

        GLES20.glDisable(GLES20.GL_BLEND)
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        program.use()

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, inputTextureId)

        val loc = GLES20.glGetUniformLocation(program.programId, "uTexture")
        if (loc >= 0) GLES20.glUniform1i(loc, 0)

        quad.draw(program.programId)

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)

        NleGlError.check("NleSurfaceOutputPass.renderToCurrentSurface")
    }

    fun release() {
        program.release()
    }
}
