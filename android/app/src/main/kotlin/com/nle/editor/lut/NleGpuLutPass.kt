package com.nle.editor.lut

import android.opengl.GLES20
import android.opengl.GLES30
import com.nle.editor.color.NleDeviceColorCapability
import com.nle.editor.color.NleResolvedColorPipeline
import com.nle.editor.colorpipeline.NleColorPass
import com.nle.editor.colorpipeline.NleFullscreenQuad
import com.nle.editor.colorpipeline.NleGlError
import com.nle.editor.colorpipeline.NleGpuFramebuffer
import com.nle.editor.colorpipeline.NleShaderProgram

class NleGpuLutPass(
    private val layer: NleLutLayer,
    private val capability: NleDeviceColorCapability,
    private val lutCache: NleGpuLutCache,
    private val lutGlsl: String,
) : NleColorPass {
    override val id: String = "gpu_lut_${layer.id}"
    override val label: String = "GPU LUT: ${layer.name}"
    override val enabled: Boolean = layer.enabled && layer.intensity > 0f

    private val quad = NleFullscreenQuad()

    private val program = NleShaderProgram(
        vertexShaderSource = vertexShader,
        fragmentShaderSource = fragmentShader(
            colorManagementGlsl = com.kata.videoeditor.nle.NleContextHolder.loadColorManagementGlsl(),
            lutGlsl = lutGlsl,
        ),
    )

    private var uploadedTexture: NleGpuLutTexture? = null

    override fun prepare() {
        program.compile()
    }

    override fun render(
        inputTextureId: Int,
        destination: NleGpuFramebuffer,
        pipeline: NleResolvedColorPipeline,
    ) {
        if (!enabled) return

        val lutTexture = uploadedTexture ?: lutCache.getOrUpload(
            layer = layer,
            capability = capability,
        ).also {
            uploadedTexture = it
        }

        destination.bind()

        GLES20.glDisable(GLES20.GL_BLEND)
        GLES20.glClearColor(0f, 0f, 0f, 0f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        program.use()

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, inputTextureId)

        val inputLoc = GLES20.glGetUniformLocation(program.programId, "uTexture")
        if (inputLoc >= 0) GLES20.glUniform1i(inputLoc, 0)

        bindLutTexture(lutTexture)

        uniformBool("uLutEnabled", true)
        uniformBool("uLutUse3dTexture", lutTexture.is3d())
        uniformFloat("uLutSize", lutTexture.size.toFloat())
        uniformFloat("uLutIntensity", layer.intensity)
        uniformInt("uLutDomain", layer.domain.ordinal)

        quad.draw(program.programId)

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)

        if (lutTexture.is3d()) {
            GLES30.glBindTexture(GLES30.GL_TEXTURE_3D, 0)
        }

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)

        NleGlError.check("NleGpuLutPass.render")
    }

    private fun bindLutTexture(texture: NleGpuLutTexture) {
        if (texture.is3d()) {
            GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
            GLES30.glBindTexture(GLES30.GL_TEXTURE_3D, texture.textureId)

            val loc = GLES20.glGetUniformLocation(program.programId, "uLut3dTexture")
            if (loc >= 0) GLES20.glUniform1i(loc, 1)
        } else {
            GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture.textureId)

            val loc = GLES20.glGetUniformLocation(program.programId, "uLut2dAtlasTexture")
            if (loc >= 0) GLES20.glUniform1i(loc, 2)
        }
    }

    private fun uniformBool(name: String, value: Boolean) {
        val loc = GLES20.glGetUniformLocation(program.programId, name)
        if (loc >= 0) GLES20.glUniform1i(loc, if (value) 1 else 0)
    }

    private fun uniformFloat(name: String, value: Float) {
        val loc = GLES20.glGetUniformLocation(program.programId, name)
        if (loc >= 0) GLES20.glUniform1f(loc, value)
    }

    private fun uniformInt(name: String, value: Int) {
        val loc = GLES20.glGetUniformLocation(program.programId, name)
        if (loc >= 0) GLES20.glUniform1i(loc, value)
    }

    override fun release() {
        program.release()
        uploadedTexture = null
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

        private fun fragmentShader(colorManagementGlsl: String, lutGlsl: String): String {
            return """
                #extension GL_OES_texture_3D : enable
                precision highp float;

                varying vec2 vTexCoord;

                uniform sampler2D uTexture;
                uniform int uLutDomain;

                $colorManagementGlsl

                float nleLog10(float x) {
                    return log(x) / 2.302585092994046;
                }

                float nleLinearToLogC(float x) {
                    if (x > NLE_LOGC_CUT) {
                        return NLE_LOGC_C * nleLog10(NLE_LOGC_A * x + NLE_LOGC_B) + NLE_LOGC_D;
                    } else {
                        return NLE_LOGC_E * x + NLE_LOGC_F;
                    }
                }

                vec3 nleLinearToLogC3(vec3 c) {
                    return vec3(
                        nleLinearToLogC(c.r),
                        nleLinearToLogC(c.g),
                        nleLinearToLogC(c.b)
                    );
                }

                $lutGlsl

                void main() {
                    vec4 src = texture2D(uTexture, vTexCoord);
                    
                    vec3 inputColor = src.rgb;
                    if (uLutDomain == 1) {
                        inputColor = nleLinearToSrgb3(nleClamp01(inputColor));
                    } else if (uLutDomain == 2) {
                        inputColor = nleLinearToLogC3(nleSafe3(inputColor));
                    }

                    vec3 lutColor = nleApplyGpuLut(inputColor);

                    if (uLutDomain == 1) {
                        lutColor = nleSrgbToLinear3(nleClamp01(lutColor));
                    } else if (uLutDomain == 2) {
                        lutColor = nleLogCToLinear3(nleSafe3(lutColor));
                    }

                    gl_FragColor = vec4(lutColor, src.a);
                }
            """.trimIndent()
        }
    }
}
