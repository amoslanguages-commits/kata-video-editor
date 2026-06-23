package com.nle.editor.curves

import android.opengl.GLES20
import com.nle.editor.color.NleResolvedColorPipeline
import com.nle.editor.colorpipeline.NleColorPass
import com.nle.editor.colorpipeline.NleFullscreenQuad
import com.nle.editor.colorpipeline.NleGlError
import com.nle.editor.colorpipeline.NleGpuFramebuffer
import com.nle.editor.colorpipeline.NleShaderProgram

class NleColorCurvesPass(
    private val stack: NleColorCurveStack,
    private val colorCurvesGlsl: String,
) : NleColorPass {
    override val id: String = "color_curves"
    override val label: String = "Color Curves"
    override val enabled: Boolean = stack.enabled && !stack.isIdentity

    private val quad = NleFullscreenQuad()
    private val binder = NleColorCurvesUniformBinder()

    private val program = NleShaderProgram(
        vertexShaderSource = vertexShader,
        fragmentShaderSource = fragmentShader(
            colorManagementGlsl = com.kata.videoeditor.nle.NleContextHolder.loadColorManagementGlsl(),
            colorCurvesGlsl = colorCurvesGlsl,
        ),
    )

    private val textures = IntArray(3)

    override fun prepare() {
        program.compile()

        // Generate 3 textures
        GLES20.glGenTextures(3, textures, 0)

        // 1. RGB Curve Texture
        val rgbBuffer = NleCurveLutGenerator.buildPackedRgbCurveTexture(stack)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[0])
        setupTextureParams()
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, 256, 1, 0,
            GLES20.GL_RGBA, GLES20.GL_FLOAT, rgbBuffer
        )

        // 2. HSL Curve Texture A
        val hslBufferA = NleCurveLutGenerator.buildPackedHslCurveTextureA(stack)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[1])
        setupTextureParams()
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, 256, 1, 0,
            GLES20.GL_RGBA, GLES20.GL_FLOAT, hslBufferA
        )

        // 3. HSL Curve Texture B
        val hslBufferB = NleCurveLutGenerator.buildPackedHslCurveTextureB(stack)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[2])
        setupTextureParams()
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, 256, 1, 0,
            GLES20.GL_RGBA, GLES20.GL_FLOAT, hslBufferB
        )

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        NleGlError.check("NleColorCurvesPass.prepare")
    }

    private fun setupTextureParams() {
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
    }

    override fun render(
        inputTextureId: Int,
        destination: NleGpuFramebuffer,
        pipeline: NleResolvedColorPipeline,
    ) {
        if (!enabled) return

        destination.bind()

        GLES20.glDisable(GLES20.GL_BLEND)
        GLES20.glClearColor(0f, 0f, 0f, 0f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        program.use()

        // Bind input texture to texture unit 0
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, inputTextureId)
        val inputLoc = GLES20.glGetUniformLocation(program.programId, "uTexture")
        if (inputLoc >= 0) GLES20.glUniform1i(inputLoc, 0)

        // Bind RGB Curve texture to unit 1
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[0])

        // Bind HSL Curve texture A to unit 2
        GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[1])

        // Bind HSL Curve texture B to unit 3
        GLES20.glActiveTexture(GLES20.GL_TEXTURE3)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[2])

        // Bind uniforms
        binder.bind(
            programId = program.programId,
            enabled = stack.enabled,
            evaluationSpace = if (stack.evaluationSpace == NleCurveEvaluationSpace.DISPLAY_REFERRED) 1 else 0,
            rgbTextureUnit = 1,
            hslTextureUnitA = 2,
            hslTextureUnitB = 3
        )

        // Draw fullscreen quad
        quad.draw(program.programId)

        // Cleanup bindings
        GLES20.glActiveTexture(GLES20.GL_TEXTURE3)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)

        NleGlError.check("NleColorCurvesPass.render")
    }

    override fun release() {
        program.release()
        if (textures[0] != 0 || textures[1] != 0 || textures[2] != 0) {
            GLES20.glDeleteTextures(3, textures, 0)
            textures[0] = 0
            textures[1] = 0
            textures[2] = 0
        }
    }

    companion object {
        private const val vertexShader = """
            attribute vec2 aPosition;
            attribute vec2 aTexCoord;

            varying vec2 vTexCoord;

            void main() {
                vTexCoord = aTexCoord;
                gl_Position = vec4(aPosition, 0.0, 1.0);
            }
        """

        private fun fragmentShader(colorManagementGlsl: String, colorCurvesGlsl: String): String {
            return """
                precision highp float;

                varying vec2 vTexCoord;

                uniform sampler2D uTexture;

                $colorManagementGlsl

                $colorCurvesGlsl

                void main() {
                    vec4 src = texture2D(uTexture, vTexCoord);
                    vec3 working = src.rgb;

                    vec3 graded = nleApplyColorCurves(working);

                    gl_FragColor = vec4(graded, src.a);
                }
            """.trimIndent()
        }
    }
}
