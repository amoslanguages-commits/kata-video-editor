package com.nle.editor.compositor

import android.opengl.GLES11Ext
import android.opengl.GLES20
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

class NleGlLayerProgram(
    private val externalOes: Boolean,
) {

    private val programId: Int

    private val aPosition: Int
    private val aTexCoord: Int
    private val uMvpMatrix: Int
    private val uTexture: Int
    private val uOpacity: Int
    private val uBrightness: Int
    private val uContrast: Int
    private val uSaturation: Int

    private val positionBuffer: FloatBuffer
    private var texCoordBuffer: FloatBuffer

    init {
        val vertexShader = compileShader(
            GLES20.GL_VERTEX_SHADER,
            VERTEX_SHADER,
        )

        val fragmentShader = compileShader(
            GLES20.GL_FRAGMENT_SHADER,
            if (externalOes) FRAGMENT_SHADER_OES else FRAGMENT_SHADER_2D,
        )

        programId = GLES20.glCreateProgram()
        GLES20.glAttachShader(programId, vertexShader)
        GLES20.glAttachShader(programId, fragmentShader)
        GLES20.glLinkProgram(programId)

        val linkStatus = IntArray(1)
        GLES20.glGetProgramiv(
            programId,
            GLES20.GL_LINK_STATUS,
            linkStatus,
            0,
        )

        if (linkStatus[0] == 0) {
            val log = GLES20.glGetProgramInfoLog(programId)
            GLES20.glDeleteProgram(programId)
            throw IllegalStateException("Failed to link GL program: $log")
        }

        GLES20.glDeleteShader(vertexShader)
        GLES20.glDeleteShader(fragmentShader)

        aPosition = GLES20.glGetAttribLocation(programId, "aPosition")
        aTexCoord = GLES20.glGetAttribLocation(programId, "aTexCoord")
        uMvpMatrix = GLES20.glGetUniformLocation(programId, "uMvpMatrix")
        uTexture = GLES20.glGetUniformLocation(programId, "uTexture")
        uOpacity = GLES20.glGetUniformLocation(programId, "uOpacity")
        uBrightness = GLES20.glGetUniformLocation(programId, "uBrightness")
        uContrast = GLES20.glGetUniformLocation(programId, "uContrast")
        uSaturation = GLES20.glGetUniformLocation(programId, "uSaturation")

        positionBuffer = makeFloatBuffer(FULLSCREEN_QUAD)
        texCoordBuffer = makeFloatBuffer(DEFAULT_TEX_COORDS)
    }

    fun draw(
        texture: NleLayerTexture,
        mvpMatrix: FloatArray,
        texCoords: FloatArray,
        opacity: Float,
        brightness: Float,
        contrast: Float,
        saturation: Float,
    ) {
        texCoordBuffer = makeFloatBuffer(texCoords)

        GLES20.glUseProgram(programId)

        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(
            aPosition,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            positionBuffer,
        )

        GLES20.glEnableVertexAttribArray(aTexCoord)
        GLES20.glVertexAttribPointer(
            aTexCoord,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            texCoordBuffer,
        )

        GLES20.glUniformMatrix4fv(
            uMvpMatrix,
            1,
            false,
            mvpMatrix,
            0,
        )

        GLES20.glUniform1f(uOpacity, opacity.coerceIn(0f, 1f))
        GLES20.glUniform1f(uBrightness, brightness.coerceIn(-1f, 1f))
        GLES20.glUniform1f(uContrast, contrast.coerceAtLeast(0f))
        GLES20.glUniform1f(uSaturation, saturation.coerceAtLeast(0f))

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(texture.target, texture.textureId)
        GLES20.glUniform1i(uTexture, 0)

        GLES20.glDrawArrays(
            GLES20.GL_TRIANGLE_STRIP,
            0,
            4,
        )

        GLES20.glBindTexture(texture.target, 0)
        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTexCoord)
        GLES20.glUseProgram(0)
    }

    fun release() {
        GLES20.glDeleteProgram(programId)
    }

    private fun compileShader(
        type: Int,
        source: String,
    ): Int {
        val shader = GLES20.glCreateShader(type)

        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)

        val status = IntArray(1)
        GLES20.glGetShaderiv(
            shader,
            GLES20.GL_COMPILE_STATUS,
            status,
            0,
        )

        if (status[0] == 0) {
            val log = GLES20.glGetShaderInfoLog(shader)
            GLES20.glDeleteShader(shader)
            throw IllegalStateException("Shader compile failed: $log")
        }

        return shader
    }

    private fun makeFloatBuffer(values: FloatArray): FloatBuffer {
        return ByteBuffer
            .allocateDirect(values.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(values)
                position(0)
            }
    }

    companion object {
        private val FULLSCREEN_QUAD = floatArrayOf(
            -1f, -1f,
            1f, -1f,
            -1f, 1f,
            1f, 1f,
        )

        private val DEFAULT_TEX_COORDS = floatArrayOf(
            0f, 1f,
            1f, 1f,
            0f, 0f,
            1f, 0f,
        )

        private const val VERTEX_SHADER = """
            attribute vec2 aPosition;
            attribute vec2 aTexCoord;

            uniform mat4 uMvpMatrix;

            varying vec2 vTexCoord;

            void main() {
                gl_Position = uMvpMatrix * vec4(aPosition, 0.0, 1.0);
                vTexCoord = aTexCoord;
            }
        """

        private const val COLOR_FUNCTIONS = """
            vec3 applyBrightness(vec3 color, float brightness) {
                return color + brightness;
            }

            vec3 applyContrast(vec3 color, float contrast) {
                return (color - 0.5) * contrast + 0.5;
            }

            vec3 applySaturation(vec3 color, float saturation) {
                float luminance = dot(color, vec3(0.299, 0.587, 0.114));
                return mix(vec3(luminance), color, saturation);
            }
        """

        private const val FRAGMENT_SHADER_2D = """
            precision mediump float;

            uniform sampler2D uTexture;
            uniform float uOpacity;
            uniform float uBrightness;
            uniform float uContrast;
            uniform float uSaturation;

            varying vec2 vTexCoord;

            $COLOR_FUNCTIONS

            void main() {
                vec4 tex = texture2D(uTexture, vTexCoord);

                vec3 color = tex.rgb;
                color = applyBrightness(color, uBrightness);
                color = applyContrast(color, uContrast);
                color = applySaturation(color, uSaturation);

                gl_FragColor = vec4(clamp(color, 0.0, 1.0), tex.a * uOpacity);
            }
        """

        private const val FRAGMENT_SHADER_OES = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;

            uniform samplerExternalOES uTexture;
            uniform float uOpacity;
            uniform float uBrightness;
            uniform float uContrast;
            uniform float uSaturation;

            varying vec2 vTexCoord;

            $COLOR_FUNCTIONS

            void main() {
                vec4 tex = texture2D(uTexture, vTexCoord);

                vec3 color = tex.rgb;
                color = applyBrightness(color, uBrightness);
                color = applyContrast(color, uContrast);
                color = applySaturation(color, uSaturation);

                gl_FragColor = vec4(clamp(color, 0.0, 1.0), tex.a * uOpacity);
            }
        """
    }
}
