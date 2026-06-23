package com.kata.videoeditor.nle.gpu

import android.graphics.Bitmap
import android.opengl.GLES20
import android.opengl.GLUtils
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

object NleGlUtil {
    fun createFloatBuffer(values: FloatArray): FloatBuffer {
        return ByteBuffer
            .allocateDirect(values.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(values)
                position(0)
            }
    }

    fun compileShader(
        type: Int,
        source: String,
    ): Int {
        val shader = GLES20.glCreateShader(type)

        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)

        val compiled = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0)

        if (compiled[0] == 0) {
            val info = GLES20.glGetShaderInfoLog(shader)
            GLES20.glDeleteShader(shader)
            throw RuntimeException("Shader compile failed: $info")
        }

        return shader
    }

    fun createProgram(
        vertexSource: String,
        fragmentSource: String,
    ): Int {
        val vertexShader = compileShader(GLES20.GL_VERTEX_SHADER, vertexSource)
        val fragmentShader = compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)

        val program = GLES20.glCreateProgram()

        GLES20.glAttachShader(program, vertexShader)
        GLES20.glAttachShader(program, fragmentShader)
        GLES20.glLinkProgram(program)

        val linked = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linked, 0)

        if (linked[0] == 0) {
            val info = GLES20.glGetProgramInfoLog(program)
            GLES20.glDeleteProgram(program)
            throw RuntimeException("Program link failed: $info")
        }

        GLES20.glDeleteShader(vertexShader)
        GLES20.glDeleteShader(fragmentShader)

        return program
    }

    fun createTextureFromBitmap(bitmap: Bitmap): Int {
        val textures = IntArray(1)

        GLES20.glGenTextures(1, textures, 0)

        val textureId = textures[0]

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)

        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE
        )

        GLUtils.texImage2D(
            GLES20.GL_TEXTURE_2D,
            0,
            bitmap,
            0
        )

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)

        checkGlError("createTextureFromBitmap")

        return textureId
    }

    fun deleteTexture(textureId: Int) {
        if (textureId <= 0) return

        val textures = intArrayOf(textureId)
        GLES20.glDeleteTextures(1, textures, 0)
    }

    fun checkGlError(label: String) {
        val error = GLES20.glGetError()

        if (error != GLES20.GL_NO_ERROR) {
            throw RuntimeException("$label GL error: 0x${Integer.toHexString(error)}")
        }
    }
}
