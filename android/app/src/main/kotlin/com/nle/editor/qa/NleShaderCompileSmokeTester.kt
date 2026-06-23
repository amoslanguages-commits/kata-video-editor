package com.nle.editor.qa

import android.opengl.GLES20
import android.opengl.EGL14

class NleShaderCompileSmokeTester {

    fun testShader(
        name: String,
        vertexSource: String,
        fragmentSource: String,
    ): List<NleColorQaIssue> {
        val issues = mutableListOf<NleColorQaIssue>()

        // Check if there is an active EGL context on this thread
        val eglContext = EGL14.eglGetCurrentContext()
        if (eglContext == EGL14.EGL_NO_CONTEXT) {
            issues.add(
                NleColorQaIssue(
                    id = "SHADER_COMPILE_EGL_NO_CONTEXT",
                    severity = NleColorQaSeverity.INFO,
                    area = NleColorQaArea.SHADER_COMPILE,
                    title = "EGL Context not active on thread",
                    message = "Cannot compile shader \"$name\" because no EGL context is active on the current thread.",
                    suggestedFix = "Run shader compile tests on the GL rendering thread."
                )
            )
            return issues
        }

        // Test vertex shader compilation
        val vertex = compileShader(GLES20.GL_VERTEX_SHADER, vertexSource, name, issues)
        if (vertex == 0) return issues

        // Test fragment shader compilation
        val fragment = compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource, name, issues)
        if (fragment == 0) {
            GLES20.glDeleteShader(vertex)
            return issues
        }

        // Test linking program
        val program = GLES20.glCreateProgram()
        if (program == 0) {
            issues.add(
                NleColorQaIssue(
                    id = "SHADER_PROGRAM_CREATION_FAILED",
                    severity = NleColorQaSeverity.RELEASE_BLOCKER,
                    area = NleColorQaArea.SHADER_COMPILE,
                    title = "Shader Program creation failed",
                    message = "Could not create shader program object.",
                    suggestedFix = "Verify EGL context resource limits."
                )
            )
            GLES20.glDeleteShader(vertex)
            GLES20.glDeleteShader(fragment)
            return issues
        }

        GLES20.glAttachShader(program, vertex)
        GLES20.glAttachShader(program, fragment)
        GLES20.glLinkProgram(program)

        val linkStatus = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0)
        if (linkStatus[0] == 0) {
            val log = GLES20.glGetProgramInfoLog(program)
            issues.add(
                NleColorQaIssue(
                    id = "SHADER_LINK_FAILED",
                    severity = NleColorQaSeverity.RELEASE_BLOCKER,
                    area = NleColorQaArea.SHADER_COMPILE,
                    title = "Shader Program link failed",
                    message = "Error linking shader program for \"$name\": $log",
                    suggestedFix = "Check attribute/varying mappings between vertex and fragment shaders."
                )
            )
        }

        // Cleanup
        GLES20.glDetachShader(program, vertex)
        GLES20.glDetachShader(program, fragment)
        GLES20.glDeleteShader(vertex)
        GLES20.glDeleteShader(fragment)
        GLES20.glDeleteProgram(program)

        return issues
    }

    private fun compileShader(
        type: Int,
        source: String,
        shaderName: String,
        issues: MutableList<NleColorQaIssue>
    ): Int {
        val shader = GLES20.glCreateShader(type)
        val typeStr = if (type == GLES20.GL_VERTEX_SHADER) "vertex" else "fragment"

        if (shader == 0) {
            issues.add(
                NleColorQaIssue(
                    id = "SHADER_${typeStr.uppercase()}_CREATION_FAILED",
                    severity = NleColorQaSeverity.RELEASE_BLOCKER,
                    area = NleColorQaArea.SHADER_COMPILE,
                    title = "Shader creation failed",
                    message = "Could not create $typeStr shader object for \"$shaderName\".",
                    suggestedFix = "Verify GLES context is initialized."
                )
            )
            return 0
        }

        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)

        val compileStatus = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compileStatus, 0)
        if (compileStatus[0] == 0) {
            val log = GLES20.glGetShaderInfoLog(shader)
            issues.add(
                NleColorQaIssue(
                    id = "SHADER_${typeStr.uppercase()}_COMPILE_FAILED",
                    severity = NleColorQaSeverity.RELEASE_BLOCKER,
                    area = NleColorQaArea.SHADER_COMPILE,
                    title = "Shader compilation failed",
                    message = "Error compiling $typeStr shader for \"$shaderName\": $log",
                    suggestedFix = "Fix syntax errors in $typeStr GLSL shader source."
                )
            )
            GLES20.glDeleteShader(shader)
            return 0
        }

        return shader
    }
}
