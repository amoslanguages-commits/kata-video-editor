package com.nle.editor.colorpipeline

import android.opengl.GLES20
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

class NleFullscreenQuad {
    private val vertexBuffer: FloatBuffer

    init {
        val vertices = floatArrayOf(
            -1f, -1f, 0f, 0f,
             1f, -1f, 1f, 0f,
            -1f,  1f, 0f, 1f,
             1f,  1f, 1f, 1f,
        )

        vertexBuffer = ByteBuffer
            .allocateDirect(vertices.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(vertices)

        vertexBuffer.position(0)
    }

    fun draw(programId: Int) {
        val positionLoc = GLES20.glGetAttribLocation(programId, "aPosition")
        val texLoc = GLES20.glGetAttribLocation(programId, "aTexCoord")

        vertexBuffer.position(0)
        GLES20.glEnableVertexAttribArray(positionLoc)
        GLES20.glVertexAttribPointer(
            positionLoc,
            2,
            GLES20.GL_FLOAT,
            false,
            4 * 4,
            vertexBuffer,
        )

        vertexBuffer.position(2)
        GLES20.glEnableVertexAttribArray(texLoc)
        GLES20.glVertexAttribPointer(
            texLoc,
            2,
            GLES20.GL_FLOAT,
            false,
            4 * 4,
            vertexBuffer,
        )

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(positionLoc)
        GLES20.glDisableVertexAttribArray(texLoc)
    }
}
