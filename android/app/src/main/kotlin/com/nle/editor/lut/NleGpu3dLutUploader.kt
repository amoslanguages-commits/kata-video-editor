package com.nle.editor.lut

import android.opengl.GLES20
import android.opengl.GLES30
import java.nio.ByteBuffer
import java.nio.ByteOrder

class NleGpu3dLutUploader {

    fun upload(
        lutAssetId: String,
        filePath: String,
        data: NleCubeLutData,
    ): NleGpuLutTexture {
        data.validate()

        val textureIds = IntArray(1)
        GLES20.glGenTextures(1, textureIds, 0)

        val textureId = textureIds[0]

        GLES30.glBindTexture(GLES30.GL_TEXTURE_3D, textureId)

        GLES30.glTexParameteri(
            GLES30.GL_TEXTURE_3D,
            GLES30.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR,
        )

        GLES30.glTexParameteri(
            GLES30.GL_TEXTURE_3D,
            GLES30.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR,
        )

        GLES30.glTexParameteri(
            GLES30.GL_TEXTURE_3D,
            GLES30.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE,
        )

        GLES30.glTexParameteri(
            GLES30.GL_TEXTURE_3D,
            GLES30.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE,
        )

        GLES30.glTexParameteri(
            GLES30.GL_TEXTURE_3D,
            GLES30.GL_TEXTURE_WRAP_R,
            GLES20.GL_CLAMP_TO_EDGE,
        )

        val buffer = ByteBuffer
            .allocateDirect(data.values.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()

        buffer.put(data.values)
        buffer.position(0)

        GLES30.glTexImage3D(
            GLES30.GL_TEXTURE_3D,
            0,
            GLES30.GL_RGB32F,
            data.size,
            data.size,
            data.size,
            0,
            GLES30.GL_RGB,
            GLES30.GL_FLOAT,
            buffer,
        )

        GLES30.glBindTexture(GLES30.GL_TEXTURE_3D, 0)

        return NleGpuLutTexture(
            lutAssetId = lutAssetId,
            path = filePath,
            size = data.size,
            textureId = textureId,
            textureMode = NleLutTextureMode.TEXTURE_3D,
        )
    }
}
