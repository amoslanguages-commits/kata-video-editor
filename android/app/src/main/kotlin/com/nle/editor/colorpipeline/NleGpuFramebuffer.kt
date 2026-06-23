package com.nle.editor.colorpipeline

import android.opengl.GLES20
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_COLOR_ATTACHMENT0
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_FRAMEBUFFER
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_FRAMEBUFFER_COMPLETE
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_TEXTURE_2D

class NleGpuFramebuffer(
    val texture: NleGpuFloatTexture,
) {
    var framebufferId: Int = 0
        private set

    val textureId: Int
        get() = texture.textureId

    val width: Int
        get() = texture.width

    val height: Int
        get() = texture.height

    fun create() {
        release()

        if (texture.textureId == 0) {
            texture.create()
        }

        val ids = IntArray(1)
        GLES20.glGenFramebuffers(1, ids, 0)
        framebufferId = ids[0]

        GLES20.glBindFramebuffer(GL_FRAMEBUFFER, framebufferId)

        GLES20.glFramebufferTexture2D(
            GL_FRAMEBUFFER,
            GL_COLOR_ATTACHMENT0,
            GL_TEXTURE_2D,
            texture.textureId,
            0,
        )

        val status = GLES20.glCheckFramebufferStatus(GL_FRAMEBUFFER)

        GLES20.glBindFramebuffer(GL_FRAMEBUFFER, 0)

        if (status != GL_FRAMEBUFFER_COMPLETE) {
            release()
            throw IllegalStateException("Framebuffer incomplete: $status")
        }

        NleGlError.check("NleGpuFramebuffer.create")
    }

    fun bind() {
        GLES20.glBindFramebuffer(GL_FRAMEBUFFER, framebufferId)
        GLES20.glViewport(0, 0, width, height)
    }

    fun release() {
        if (framebufferId != 0) {
            GLES20.glDeleteFramebuffers(1, intArrayOf(framebufferId), 0)
            framebufferId = 0
        }
    }
}
