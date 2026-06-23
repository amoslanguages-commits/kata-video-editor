package com.nle.editor.grade

enum class NlePrimaryGradeMode {
    LINEAR,
    LOG;

    companion object {
        fun parse(value: String?): NlePrimaryGradeMode {
            return when (value?.lowercase()) {
                "log" -> LOG
                "linear" -> LINEAR
                else -> LINEAR
            }
        }
    }
}

data class NleRgbVector(
    val r: Float,
    val g: Float,
    val b: Float,
) {
    companion object {
        val ZERO = NleRgbVector(0f, 0f, 0f)
        val ONE = NleRgbVector(1f, 1f, 1f)
    }
}

data class NlePrimaryWheelControl(
    val master: Float,
    val rgb: NleRgbVector,
)

data class NlePrimaryGrade(
    val enabled: Boolean,
    val mode: NlePrimaryGradeMode,
    val intensity: Float,
    val lift: NlePrimaryWheelControl,
    val gamma: NlePrimaryWheelControl,
    val gain: NlePrimaryWheelControl,
    val offset: NlePrimaryWheelControl,
    val contrast: Float,
    val pivot: Float,
    val saturation: Float,
) {
    companion object {
        fun identity(): NlePrimaryGrade {
            return NlePrimaryGrade(
                enabled = true,
                mode = NlePrimaryGradeMode.LINEAR,
                intensity = 1f,
                lift = NlePrimaryWheelControl(
                    master = 0f,
                    rgb = NleRgbVector.ZERO,
                ),
                gamma = NlePrimaryWheelControl(
                    master = 1f,
                    rgb = NleRgbVector.ONE,
                ),
                gain = NlePrimaryWheelControl(
                    master = 1f,
                    rgb = NleRgbVector.ONE,
                ),
                offset = NlePrimaryWheelControl(
                    master = 0f,
                    rgb = NleRgbVector.ZERO,
                ),
                contrast = 1f,
                pivot = 0.18f,
                saturation = 1f,
            )
        }
    }
}
