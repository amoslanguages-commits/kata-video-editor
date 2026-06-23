package com.nle.editor.grade

import android.opengl.GLES20
import com.nle.editor.color.NleResolvedColorPipeline
import com.nle.editor.colorpipeline.NleColorPass
import com.nle.editor.colorpipeline.NleFullscreenQuad
import com.nle.editor.colorpipeline.NleGlError
import com.nle.editor.colorpipeline.NleGpuFramebuffer
import com.nle.editor.colorpipeline.NleShaderProgram

class NleSecondaryGradePass(
    private var layer: NleSecondaryGradeLayer,
    private val secondaryGradeGlsl: String,
) : NleColorPass {
    override val id: String = "secondary_grade_${layer.id}"
    override val label: String = "Secondary Grade Layer: ${layer.name}"
    override val enabled: Boolean
        get() = layer.enabled && !layer.isIdentity()

    private val quad = NleFullscreenQuad()
    private val binder = NleSecondaryGradeUniformBinder()

    private val program = NleShaderProgram(
        vertexShaderSource = vertexShader,
        fragmentShaderSource = fragmentShader(
            colorManagementGlsl = com.kata.videoeditor.nle.NleContextHolder.loadColorManagementGlsl(),
            secondaryGradeGlsl = secondaryGradeGlsl,
        ),
    )

    fun updateLayer(nextLayer: NleSecondaryGradeLayer) {
        layer = nextLayer
    }

    override fun prepare() {
        program.compile()
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

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, inputTextureId)

        val inputLoc = GLES20.glGetUniformLocation(program.programId, "uTexture")
        if (inputLoc >= 0) GLES20.glUniform1i(inputLoc, 0)

        binder.bind(program.programId, layer, destination.width, destination.height)

        quad.draw(program.programId)

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)

        NleGlError.check("NleSecondaryGradePass.render")
    }

    override fun release() {
        program.release()
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

        private fun fragmentShader(colorManagementGlsl: String, secondaryGradeGlsl: String): String {
            return """
                precision highp float;

                varying vec2 vTexCoord;

                uniform sampler2D uTexture;

                $colorManagementGlsl

                $secondaryGradeGlsl

                void main() {
                    vec4 src = texture2D(uTexture, vTexCoord);
                    vec3 working = src.rgb;

                    // 1. Get raw mask at current coordinate (incorporating clean values)
                    float m = nleSecondaryGetMaskAt(uTexture, vTexCoord);

                    // 2. Multi-sample blur of the mask if requested
                    if (uBlur > 0.0) {
                        float blurRadius = uBlur * 5.0; // scale factor
                        vec2 texel = 1.0 / uTextureSize;
                        float sum = m;
                        sum += nleSecondaryGetMaskAt(uTexture, vTexCoord + vec2(-1.0, -1.0) * texel * blurRadius);
                        sum += nleSecondaryGetMaskAt(uTexture, vTexCoord + vec2( 0.0, -1.0) * texel * blurRadius);
                        sum += nleSecondaryGetMaskAt(uTexture, vTexCoord + vec2( 1.0, -1.0) * texel * blurRadius);
                        sum += nleSecondaryGetMaskAt(uTexture, vTexCoord + vec2(-1.0,  0.0) * texel * blurRadius);
                        sum += nleSecondaryGetMaskAt(uTexture, vTexCoord + vec2( 1.0,  0.0) * texel * blurRadius);
                        sum += nleSecondaryGetMaskAt(uTexture, vTexCoord + vec2(-1.0,  1.0) * texel * blurRadius);
                        sum += nleSecondaryGetMaskAt(uTexture, vTexCoord + vec2( 0.0,  1.0) * texel * blurRadius);
                        sum += nleSecondaryGetMaskAt(uTexture, vTexCoord + vec2( 1.0,  1.0) * texel * blurRadius);
                        m = sum / 9.0;
                    }

                    // 3. Invert mask if uInvert is true
                    if (uInvert) {
                        m = 1.0 - m;
                    }

                    // 4. Calculate selective primary grading correction
                    vec3 graded = nleSecondaryApplyPrimaryGrade(working);

                    // 5. Output based on View Mode
                    if (uViewMode == 1) { // Matte Mode
                        gl_FragColor = vec4(vec3(m), 1.0);
                    } else if (uViewMode == 2) { // Overlay Mode
                        // Tint unselected area with a dark reddish overlay (50% red tint)
                        vec3 tinted = mix(working * 0.3, vec3(0.5, 0.0, 0.0), 0.2);
                        vec3 outColor = mix(tinted, graded, m);
                        gl_FragColor = vec4(outColor, src.a);
                    } else { // Normal Mode
                        vec3 outColor = mix(working, graded, m * uSecondaryGradeIntensity);
                        gl_FragColor = vec4(outColor, src.a);
                    }
                }
            """.trimIndent()
        }
    }
}
