package com.kata.videoeditor.nle.gpu

import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.Matrix
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * OpenGL ES 2.0 shader program that samples a `GL_TEXTURE_EXTERNAL_OES` texture
 * and applies per-clip color adjustments (brightness, contrast, saturation, opacity).
 *
 * Used by the V2 true-decoder export pipeline to composite decoded video frames
 * onto the MediaCodec encoder input surface.
 *
 * The full-screen quad (TRIANGLE_STRIP) covers NDC [-1, 1] on both axes.
 * The texture-coordinate transform provided by [SurfaceTexture.getTransformMatrix]
 * is applied in the vertex shader to correctly orient the OES image.
 */
class NleExternalOesProgram {

    // ── Shaders ───────────────────────────────────────────────────────────────

    private val vertexShaderSource = """
        uniform mat4 uMvpMatrix;
        uniform mat4 uTexMatrix;
        attribute vec4 aPosition;
        attribute vec2 aTexCoord;
        varying vec2 vTexCoord;

        void main() {
            gl_Position = uMvpMatrix * aPosition;
            vTexCoord = (uTexMatrix * vec4(aTexCoord, 0.0, 1.0)).xy;
        }
    """.trimIndent()

    private val fragmentShaderSource = """
        #extension GL_OES_EGL_image_external : require
        precision mediump float;

        varying vec2 vTexCoord;

        uniform samplerExternalOES uTexture;
        uniform float uOpacity;
        uniform float uBrightness;
        uniform float uContrast;
        uniform float uSaturation;

        vec3 applySaturation(vec3 color, float saturation) {
            float luma = dot(color, vec3(0.299, 0.587, 0.114));
            return mix(vec3(luma), color, saturation);
        }

        void main() {
            vec4 src = texture2D(uTexture, vTexCoord);
            vec3 color = src.rgb;

            // Brightness: additive offset in [-1, 1].
            color += uBrightness;

            // Contrast: scale around 0.5.
            color = (color - 0.5) * uContrast + 0.5;

            // Saturation: blend between luma and full color.
            color = applySaturation(color, uSaturation);

            color = clamp(color, 0.0, 1.0);

            gl_FragColor = vec4(color, src.a * uOpacity);
        }
    """.trimIndent()

    // ── Geometry ─────────────────────────────────────────────────────────────

    // Interleaved [x, y, z, u, v] per vertex.  TRIANGLE_STRIP order.
    private val quadVertices = floatArrayOf(
        -1f, -1f, 0f,   0f, 1f,
         1f, -1f, 0f,   1f, 1f,
        -1f,  1f, 0f,   0f, 0f,
         1f,  1f, 0f,   1f, 0f,
    )

    private val vertexBuffer: FloatBuffer =
        ByteBuffer.allocateDirect(quadVertices.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply { put(quadVertices); position(0) }

    // ── GL handles ────────────────────────────────────────────────────────────

    private val program   = createProgram(vertexShaderSource, fragmentShaderSource)

    private val aPosition  = GLES20.glGetAttribLocation (program, "aPosition")
    private val aTexCoord  = GLES20.glGetAttribLocation (program, "aTexCoord")
    private val uMvpMatrix = GLES20.glGetUniformLocation(program, "uMvpMatrix")
    private val uTexMatrix = GLES20.glGetUniformLocation(program, "uTexMatrix")
    private val uTexture   = GLES20.glGetUniformLocation(program, "uTexture")
    private val uOpacity   = GLES20.glGetUniformLocation(program, "uOpacity")
    private val uBrightness = GLES20.glGetUniformLocation(program, "uBrightness")
    private val uContrast  = GLES20.glGetUniformLocation(program, "uContrast")
    private val uSaturation = GLES20.glGetUniformLocation(program, "uSaturation")

    // ── Draw ─────────────────────────────────────────────────────────────────

    /**
     * Renders [textureId] (a `GL_TEXTURE_EXTERNAL_OES`) with the given transform and
     * color adjustments.
     *
     * @param textureId      OES texture holding the decoded frame.
     * @param textureMatrix  4×4 matrix from [android.graphics.SurfaceTexture.getTransformMatrix].
     * @param mvpMatrix      Model-View-Projection matrix (incorporates clip transform).
     * @param opacity        Alpha multiplier [0, 1].
     * @param brightness     Additive brightness offset (e.g. 0.0 = no change, +0.1 = brighter).
     * @param contrast       Contrast scale around 0.5 (1.0 = no change).
     * @param saturation     Saturation factor (1.0 = no change, 0.0 = greyscale).
     */
    fun draw(
        textureId: Int,
        textureMatrix: FloatArray,
        mvpMatrix: FloatArray,
        opacity: Float,
        brightness: Float,
        contrast: Float,
        saturation: Float,
    ) {
        GLES20.glUseProgram(program)

        // Position attribute (stride = 5 floats × 4 bytes = 20 bytes, offset 0)
        vertexBuffer.position(0)
        GLES20.glVertexAttribPointer(aPosition, 3, GLES20.GL_FLOAT, false, 5 * 4, vertexBuffer)
        GLES20.glEnableVertexAttribArray(aPosition)

        // TexCoord attribute (stride = 20 bytes, offset = 3 floats × 4 bytes = 12 bytes)
        vertexBuffer.position(3)
        GLES20.glVertexAttribPointer(aTexCoord, 2, GLES20.GL_FLOAT, false, 5 * 4, vertexBuffer)
        GLES20.glEnableVertexAttribArray(aTexCoord)

        // Matrices
        GLES20.glUniformMatrix4fv(uMvpMatrix, 1, false, mvpMatrix, 0)
        GLES20.glUniformMatrix4fv(uTexMatrix, 1, false, textureMatrix, 0)

        // Color uniforms
        GLES20.glUniform1f(uOpacity,    opacity.coerceIn(0f, 1f))
        GLES20.glUniform1f(uBrightness, brightness)
        GLES20.glUniform1f(uContrast,   contrast.coerceAtLeast(0f))
        GLES20.glUniform1f(uSaturation, saturation.coerceAtLeast(0f))

        // Bind the OES texture to unit 0.
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glUniform1i(uTexture, 0)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        // Unbind
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0)
        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTexCoord)
    }

    /** Deletes the GL program. Call on the GL thread. */
    fun release() {
        try { GLES20.glDeleteProgram(program) } catch (_: Throwable) {}
    }

    // ── Companion ─────────────────────────────────────────────────────────────

    companion object {
        /** Returns a 4×4 identity matrix. */
        fun identityMatrix(): FloatArray = FloatArray(16).also { Matrix.setIdentityM(it, 0) }
    }

    // ── GL helpers ────────────────────────────────────────────────────────────

    private fun createProgram(vertexSource: String, fragmentSource: String): Int {
        val vertex   = compileShader(GLES20.GL_VERTEX_SHADER,   vertexSource)
        val fragment = compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)

        val prog = GLES20.glCreateProgram()
        GLES20.glAttachShader(prog, vertex)
        GLES20.glAttachShader(prog, fragment)
        GLES20.glLinkProgram(prog)

        val status = IntArray(1)
        GLES20.glGetProgramiv(prog, GLES20.GL_LINK_STATUS, status, 0)

        if (status[0] != GLES20.GL_TRUE) {
            val log = GLES20.glGetProgramInfoLog(prog)
            GLES20.glDeleteProgram(prog)
            GLES20.glDeleteShader(vertex)
            GLES20.glDeleteShader(fragment)
            throw RuntimeException("OES program link failed: $log")
        }

        GLES20.glDeleteShader(vertex)
        GLES20.glDeleteShader(fragment)
        return prog
    }

    private fun compileShader(type: Int, source: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)

        val status = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, status, 0)

        if (status[0] != GLES20.GL_TRUE) {
            val log = GLES20.glGetShaderInfoLog(shader)
            GLES20.glDeleteShader(shader)
            throw RuntimeException("OES shader compile failed ($type): $log")
        }

        return shader
    }
}
