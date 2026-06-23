package com.nle.editor.colorpipeline

import android.opengl.GLES20

class NleShaderProgram(
    private val vertexShaderSource: String,
    private val fragmentShaderSource: String,
) {
    var programId: Int = 0
        private set

    fun compile() {
        release()

        val vertex = compileShader(GLES20.GL_VERTEX_SHADER, vertexShaderSource)
        val fragment = compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentShaderSource)

        val program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertex)
        GLES20.glAttachShader(program, fragment)
        GLES20.glLinkProgram(program)

        val link = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, link, 0)

        GLES20.glDeleteShader(vertex)
        GLES20.glDeleteShader(fragment)

        if (link[0] == 0) {
            val log = GLES20.glGetProgramInfoLog(program)
            GLES20.glDeleteProgram(program)
            throw IllegalStateException("Shader link failed: $log")
        }

        programId = program
    }

    fun use() {
        GLES20.glUseProgram(programId)
    }

    fun release() {
        if (programId != 0) {
            GLES20.glDeleteProgram(programId)
            programId = 0
        }
    }

    private fun compileShader(type: Int, source: String): Int {
        val shader = GLES20.glCreateShader(type)

        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)

        val compiled = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0)

        if (compiled[0] == 0) {
            val log = GLES20.glGetShaderInfoLog(shader)
            GLES20.glDeleteShader(shader)
            throw IllegalStateException("Shader compile failed: $log")
        }

        return shader
    }
}
