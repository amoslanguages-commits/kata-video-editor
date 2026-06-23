package com.nle.editor.curves

import android.opengl.GLES20

class NleColorCurvesUniformBinder {

    fun bind(
        programId: Int,
        enabled: Boolean,
        evaluationSpace: Int, // 0 = Scene-Linear, 1 = Display-Referred
        rgbTextureUnit: Int,
        hslTextureUnitA: Int,
        hslTextureUnitB: Int
    ) {
        uniformBool(programId, "uCurvesEnabled", enabled)
        uniformInt(programId, "uEvaluationSpace", evaluationSpace)
        uniformInt(programId, "uRgbCurveTexture", rgbTextureUnit)
        uniformInt(programId, "uHslCurveTextureA", hslTextureUnitA)
        uniformInt(programId, "uHslCurveTextureB", hslTextureUnitB)
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
}
