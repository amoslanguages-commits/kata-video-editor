package com.nle.editor.grade

import android.opengl.GLES20
import com.nle.editor.color.NleResolvedColorPipeline
import com.nle.editor.colorpipeline.NleColorPass
import com.nle.editor.colorpipeline.NleFullscreenQuad
import com.nle.editor.colorpipeline.NleGlError
import com.nle.editor.colorpipeline.NleGpuFramebuffer
import com.nle.editor.colorpipeline.NleShaderProgram

class NlePrimaryGradePass(
    private val grade: NlePrimaryGrade,
    private val primaryGradeGlsl: String,
) : NleColorPass {
    override val id: String = "primary_grade"
    override val label: String = "Primary Grade"
    override val enabled: Boolean = grade.enabled && grade.intensity > 0f

    private val quad = NleFullscreenQuad()
    private val binder = NlePrimaryGradeUniformBinder()

    private val program = NleShaderProgram(
        vertexShaderSource = vertexShader,
        fragmentShaderSource = fragmentShader(
            colorManagementGlsl = com.kata.videoeditor.nle.NleContextHolder.loadColorManagementGlsl(),
            primaryGradeGlsl = primaryGradeGlsl,
        ),
    )

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

        binder.bind(program.programId, grade)

        quad.draw(program.programId)

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)

        NleGlError.check("NlePrimaryGradePass.render")
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

        private fun fragmentShader(colorManagementGlsl: String, primaryGradeGlsl: String): String {
            return """
                precision highp float;

                varying vec2 vTexCoord;

                uniform sampler2D uTexture;

                $colorManagementGlsl

                $primaryGradeGlsl

                void main() {
                    vec4 src = texture2D(uTexture, vTexCoord);
                    vec3 working = src.rgb;

                    vec3 graded = nleApplyPrimaryGrade(working);

                    gl_FragColor = vec4(graded, src.a);
                }
            """.trimIndent()
        }
    }
}
