package com.nle.editor.grade

import android.opengl.GLES20

class NlePrimaryGradeUniformBinder {

    fun bind(
        programId: Int,
        grade: NlePrimaryGrade,
    ) {
        uniformBool(programId, "uPrimaryGradeEnabled", grade.enabled)
        uniformInt(
            programId,
            "uPrimaryGradeMode",
            if (grade.mode == NlePrimaryGradeMode.LOG) 1 else 0,
        )

        uniformFloat(
            programId,
            "uPrimaryGradeIntensity",
            grade.intensity.coerceIn(0f, 1f),
        )

        uniformVec3(
            programId,
            "uLift",
            combineAdditiveWheel(grade.lift),
        )

        uniformVec3(
            programId,
            "uGamma",
            combineMultiplicativeWheel(grade.gamma),
        )

        uniformVec3(
            programId,
            "uGain",
            combineMultiplicativeWheel(grade.gain),
        )

        uniformVec3(
            programId,
            "uOffset",
            combineAdditiveWheel(grade.offset),
        )

        uniformFloat(programId, "uContrast", grade.contrast.coerceIn(0f, 4f))
        uniformFloat(programId, "uPivot", grade.pivot.coerceIn(0.001f, 4f))
        uniformFloat(programId, "uSaturation", grade.saturation.coerceIn(0f, 4f))
    }

    private fun combineAdditiveWheel(
        wheel: NlePrimaryWheelControl,
    ): FloatArray {
        return floatArrayOf(
            wheel.rgb.r + wheel.master,
            wheel.rgb.g + wheel.master,
            wheel.rgb.b + wheel.master,
        )
    }

    private fun combineMultiplicativeWheel(
        wheel: NlePrimaryWheelControl,
    ): FloatArray {
        // Multiplicative combinations are scaled by master and must be positive non-zero.
        return floatArrayOf(
            (wheel.rgb.r * wheel.master).coerceAtLeast(0.0001f),
            (wheel.rgb.g * wheel.master).coerceAtLeast(0.0001f),
            (wheel.rgb.b * wheel.master).coerceAtLeast(0.0001f),
        )
    }

    private fun uniformBool(
        programId: Int,
        name: String,
        value: Boolean,
    ) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform1i(loc, if (value) 1 else 0)
        }
    }

    private fun uniformInt(
        programId: Int,
        name: String,
        value: Int,
    ) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform1i(loc, value)
        }
    }

    private fun uniformFloat(
        programId: Int,
        name: String,
        value: Float,
    ) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform1f(loc, value)
        }
    }

    private fun uniformVec3(
        programId: Int,
        name: String,
        value: FloatArray,
    ) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform3fv(loc, 1, value, 0)
        }
    }
}
