package com.kata.videoeditor.nle.gpu

import android.opengl.GLES20
import java.nio.FloatBuffer

/**
 * GLES 2.0 shader program for rendering a 2-D texture quad with:
 *  - MVP transform
 *  - Opacity
 *  - Brightness / Contrast / Saturation colour grading
 *
 * Uniform ranges:
 *  - uOpacity:     0.0 … 1.0
 *  - uBrightness: -1.0 … +1.0  (0 = neutral)
 *  - uContrast:    0.0 … 4.0   (1 = neutral)
 *  - uSaturation:  0.0 … 4.0   (1 = neutral, 0 = greyscale)
 */
class NleTextureProgram {

    private val vertexShaderSrc = """
        attribute vec4 aPosition;
        attribute vec2 aTexCoord;
        uniform   mat4 uMvpMatrix;
        varying   vec2 vTexCoord;

        void main() {
            gl_Position = uMvpMatrix * aPosition;
            vTexCoord   = aTexCoord;
        }
    """.trimIndent()

    private val fragmentShaderSrc = """
        precision mediump float;

        varying vec2 vTexCoord;

        uniform sampler2D uTexture;
        uniform float     uOpacity;
        uniform float     uBrightness;
        uniform float     uContrast;
        uniform float     uSaturation;

        vec3 applySaturation(vec3 c, float sat) {
            float grey = dot(c, vec3(0.299, 0.587, 0.114));
            return mix(vec3(grey), c, sat);
        }

        void main() {
            vec4 sample = texture2D(uTexture, vTexCoord);

            vec3 rgb = sample.rgb;
            rgb = rgb + uBrightness;
            rgb = ((rgb - 0.5) * uContrast) + 0.5;
            rgb = applySaturation(rgb, uSaturation);
            rgb = clamp(rgb, 0.0, 1.0);

            gl_FragColor = vec4(rgb, sample.a * uOpacity);
        }
    """.trimIndent()

    private var program      = 0
    private var aPosition    = -1
    private var aTexCoord    = -1
    private var uMvpMatrix   = -1
    private var uTexture     = -1
    private var uOpacity     = -1
    private var uBrightness  = -1
    private var uContrast    = -1
    private var uSaturation  = -1

    fun initialize() {
        if (program != 0) return

        program = NleGlUtil.createProgram(
            vertexSource   = vertexShaderSrc,
            fragmentSource = fragmentShaderSrc
        )

        aPosition   = GLES20.glGetAttribLocation(program,  "aPosition")
        aTexCoord   = GLES20.glGetAttribLocation(program,  "aTexCoord")
        uMvpMatrix  = GLES20.glGetUniformLocation(program, "uMvpMatrix")
        uTexture    = GLES20.glGetUniformLocation(program, "uTexture")
        uOpacity    = GLES20.glGetUniformLocation(program, "uOpacity")
        uBrightness = GLES20.glGetUniformLocation(program, "uBrightness")
        uContrast   = GLES20.glGetUniformLocation(program, "uContrast")
        uSaturation = GLES20.glGetUniformLocation(program, "uSaturation")
    }

    /**
     * Draw [textureId] with the given transform and color-grading parameters.
     *
     * Must be called on the GL thread with a current EGL context.
     */
    fun draw(
        textureId:    Int,
        vertexBuffer: FloatBuffer,
        texCoordBuffer: FloatBuffer,
        mvpMatrix:    FloatArray,
        opacity:      Float,
        brightness:   Float = 0f,
        contrast:     Float = 1f,
        saturation:   Float = 1f,
    ) {
        initialize()

        GLES20.glUseProgram(program)

        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glEnableVertexAttribArray(aTexCoord)

        GLES20.glVertexAttribPointer(aPosition,  2, GLES20.GL_FLOAT, false, 0, vertexBuffer)
        GLES20.glVertexAttribPointer(aTexCoord,  2, GLES20.GL_FLOAT, false, 0, texCoordBuffer)

        GLES20.glUniformMatrix4fv(uMvpMatrix, 1, false, mvpMatrix, 0)

        GLES20.glUniform1f(uOpacity,    opacity.coerceIn(0f, 1f))
        GLES20.glUniform1f(uBrightness, brightness.coerceIn(-1f, 1f))
        GLES20.glUniform1f(uContrast,   contrast.coerceIn(0f, 4f))
        GLES20.glUniform1f(uSaturation, saturation.coerceIn(0f, 4f))

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glUniform1i(uTexture, 0)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTexCoord)

        NleGlUtil.checkGlError("NleTextureProgram.draw")
    }

    fun release() {
        if (program != 0) {
            GLES20.glDeleteProgram(program)
            program = 0
        }
    }
}
