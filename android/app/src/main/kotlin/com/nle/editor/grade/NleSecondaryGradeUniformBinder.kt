package com.nle.editor.grade

import android.opengl.GLES20

class NleSecondaryGradeUniformBinder {

    fun bind(
        programId: Int,
        layer: NleSecondaryGradeLayer,
        textureWidth: Int,
        textureHeight: Int,
    ) {
        val q = layer.qualifier
        val c = layer.correction

        // Qualifier range uniforms
        uniformBool(programId, "uQualifierEnabled", q.enabled)
        uniformFloat(programId, "uHueCenter", q.hue.center)
        uniformFloat(programId, "uHueWidth", q.hue.width)
        uniformFloat(programId, "uHueSoftness", q.hue.softness)

        uniformFloat(programId, "uSatCenter", q.saturation.center)
        uniformFloat(programId, "uSatWidth", q.saturation.width)
        uniformFloat(programId, "uSatSoftness", q.saturation.softness)

        uniformFloat(programId, "uLumCenter", q.luminance.center)
        uniformFloat(programId, "uLumWidth", q.luminance.width)
        uniformFloat(programId, "uLumSoftness", q.luminance.softness)

        uniformFloat(programId, "uCleanBlack", q.cleanBlack)
        uniformFloat(programId, "uCleanWhite", q.cleanWhite)
        uniformFloat(programId, "uBlur", q.blur)
        uniformBool(programId, "uInvert", q.invert)
        
        val viewModeInt = when (q.viewMode) {
            NleQualifierViewMode.NORMAL -> 0
            NleQualifierViewMode.MATTE -> 1
            NleQualifierViewMode.OVERLAY -> 2
        }
        uniformInt(programId, "uViewMode", viewModeInt)

        // Correction uniforms
        uniformBool(programId, "uCorrectionEnabled", c.enabled)
        uniformFloat(programId, "uSecondaryGradeIntensity", c.intensity)
        uniformFloat(programId, "uExposure", c.exposure)
        uniformFloat(programId, "uContrast", c.contrast)
        uniformFloat(programId, "uSaturation", c.saturation)
        uniformFloat(programId, "uTemperature", c.temperature)
        uniformFloat(programId, "uTint", c.tint)
        uniformFloat(programId, "uLift", c.lift)
        uniformFloat(programId, "uGamma", c.gamma)
        uniformFloat(programId, "uGain", c.gain)
        uniformFloat(programId, "uOffset", c.offset)

        // Texture size uniform
        uniformVec2(programId, "uTextureSize", floatArrayOf(textureWidth.toFloat(), textureHeight.toFloat()))
    }

    private fun uniformBool(programId: Int, name: String, value: Boolean) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform1i(loc, if (value) 1 else 0)
        }
    }

    private fun uniformInt(programId: Int, name: String, value: Int) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform1i(loc, value)
        }
    }

    private fun uniformFloat(programId: Int, name: String, value: Float) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform1f(loc, value)
        }
    }

    private fun uniformVec2(programId: Int, name: String, value: FloatArray) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform2fv(loc, 1, value, 0)
        }
    }
}
