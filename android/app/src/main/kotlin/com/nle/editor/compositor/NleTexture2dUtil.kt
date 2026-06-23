package com.nle.editor.compositor

import android.graphics.Bitmap
import android.opengl.GLES20
import android.opengl.GLUtils

object NleTexture2dUtil {

    fun createTextureFromBitmap(
        bitmap: Bitmap,
        ownsTexture: Boolean = true,
    ): NleLayerTexture {
        val ids = IntArray(1)
        GLES20.glGenTextures(1, ids, 0)

        val textureId = ids[0]

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE,
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE,
        )

        GLUtils.texImage2D(
            GLES20.GL_TEXTURE_2D,
            0,
            bitmap,
            0,
        )

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)

        return NleLayerTexture(
            textureId = textureId,
            target = GLES20.GL_TEXTURE_2D,
            width = bitmap.width,
            height = bitmap.height,
            ownsTexture = ownsTexture,
        )
    }
}
