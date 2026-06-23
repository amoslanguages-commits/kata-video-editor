package com.kata.videoeditor.nle.gpu

import android.opengl.GLES11Ext
import android.opengl.GLES20

/**
 * Utility for creating GL_TEXTURE_EXTERNAL_OES textures used by the V2 decoder pipeline.
 *
 * Must be called on a thread that has an active EGL context (i.e. after
 * [NleEglWindowSurface.makeCurrent] has been called on the export thread).
 */
object NleOesTextureUtil {

    /**
     * Allocates and configures a single GL_TEXTURE_EXTERNAL_OES texture.
     *
     * @return The texture ID.
     */
    fun createOesTexture(): Int {
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)

        val textureId = textures[0]

        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)

        GLES20.glTexParameterf(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR.toFloat(),
        )
        GLES20.glTexParameterf(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR.toFloat(),
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE,
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE,
        )

        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0)

        return textureId
    }
}
