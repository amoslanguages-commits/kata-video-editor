package com.nle.editor.lut

import android.opengl.GLES20
import java.nio.ByteBuffer
import java.nio.ByteOrder

class NleGpu2dLutAtlasUploader {

    fun upload(
        lutAssetId: String,
        filePath: String,
        data: NleCubeLutData,
    ): NleGpuLutTexture {
        data.validate()

        val size = data.size
        val atlasWidth = size * size
        val atlasHeight = size

        val atlas = FloatArray(atlasWidth * atlasHeight * 3)

        // .cube ordering is usually blue-fastest or red-fastest depending generator.
        // The parser stores in file order.
        // 30C-PRO assumes common .cube order:
        // for B slice, for G row, for R column.
        //
        // Each B slice becomes a horizontal tile.
        //
        // atlasX = r + b * size
        // atlasY = g

        var sourceIndex = 0

        for (b in 0 until size) {
            for (g in 0 until size) {
                for (r in 0 until size) {
                    val atlasX = r + b * size
                    val atlasY = g
                    val atlasIndex = (atlasY * atlasWidth + atlasX) * 3

                    atlas[atlasIndex] = data.values[sourceIndex]
                    atlas[atlasIndex + 1] = data.values[sourceIndex + 1]
                    atlas[atlasIndex + 2] = data.values[sourceIndex + 2]

                    sourceIndex += 3
                }
            }
        }

        val textureIds = IntArray(1)
        GLES20.glGenTextures(1, textureIds, 0)

        val textureId = textureIds[0]

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

        val buffer = ByteBuffer
            .allocateDirect(atlas.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()

        buffer.put(atlas)
        buffer.position(0)

        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D,
            0,
            GLES20.GL_RGB,
            atlasWidth,
            atlasHeight,
            0,
            GLES20.GL_RGB,
            GLES20.GL_FLOAT,
            buffer,
        )

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)

        return NleGpuLutTexture(
            lutAssetId = lutAssetId,
            path = filePath,
            size = size,
            textureId = textureId,
            textureMode = NleLutTextureMode.TEXTURE_2D_ATLAS,
        )
    }
}
