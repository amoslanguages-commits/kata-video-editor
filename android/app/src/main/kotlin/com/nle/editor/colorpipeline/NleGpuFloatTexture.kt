package com.nle.editor.colorpipeline

import android.opengl.GLES20
import android.opengl.GLES30
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_CLAMP_TO_EDGE
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_LINEAR
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_NEAREST
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_TEXTURE_2D
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_TEXTURE_MAG_FILTER
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_TEXTURE_MIN_FILTER
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_TEXTURE_WRAP_S
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_TEXTURE_WRAP_T

class NleGpuFloatTexture(
    val width: Int,
    val height: Int,
    val info: NleGpuRenderFormatInfo,
) {
    var textureId: Int = 0
        private set

    fun create() {
        release()

        val ids = IntArray(1)
        GLES20.glGenTextures(1, ids, 0)
        textureId = ids[0]

        GLES20.glBindTexture(GL_TEXTURE_2D, textureId)

        val filter = if (info.supportsLinearFiltering) GL_LINEAR else GL_NEAREST

        GLES20.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter)
        GLES20.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter)
        GLES20.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

        GLES30.glTexImage2D(
            GL_TEXTURE_2D,
            0,
            info.internalFormat,
            width,
            height,
            0,
            info.formatEnum,
            info.typeEnum,
            null,
        )

        GLES20.glBindTexture(GL_TEXTURE_2D, 0)

        NleGlError.check("NleGpuFloatTexture.create")
    }

    fun release() {
        if (textureId != 0) {
            GLES20.glDeleteTextures(1, intArrayOf(textureId), 0)
            textureId = 0
        }
    }
}
