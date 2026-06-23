package com.nle.editor.grade

enum class NleQualifierViewMode {
    NORMAL,
    MATTE,
    OVERLAY;

    companion object {
        fun parse(value: String?): NleQualifierViewMode {
            return when (value?.lowercase()) {
                "matte" -> MATTE
                "overlay" -> OVERLAY
                else -> NORMAL
            }
        }
    }
}

data class NleRangeControl(
    val center: Float,
    val width: Float,
    val softness: Float,
) {
    fun clamp(): NleRangeControl {
        return NleRangeControl(
            center = center.coerceIn(0f, 1f),
            width = width.coerceIn(0f, 1f),
            softness = softness.coerceIn(0f, 1f)
        )
    }
}

data class NleHslQualifier(
    val enabled: Boolean,
    val hue: NleRangeControl,
    val saturation: NleRangeControl,
    val luminance: NleRangeControl,
    val cleanBlack: Float,
    val cleanWhite: Float,
    val blur: Float,
    val invert: Boolean,
    val viewMode: NleQualifierViewMode,
) {
    fun isIdentity(): Boolean = !enabled
}

data class NleSecondaryCorrection(
    val enabled: Boolean,
    val intensity: Float,
    val exposure: Float,
    val contrast: Float,
    val saturation: Float,
    val temperature: Float,
    val tint: Float,
    val lift: Float,
    val gamma: Float,
    val gain: Float,
    val offset: Float,
) {
    fun isIdentity(): Boolean {
        return enabled &&
            intensity == 1f &&
            exposure == 0f &&
            contrast == 1f &&
            saturation == 1f &&
            temperature == 0f &&
            tint == 0f &&
            lift == 0f &&
            gamma == 1f &&
            gain == 1f &&
            offset == 0f
    }
}

data class NleSecondaryGradeLayer(
    val id: String,
    val name: String,
    val enabled: Boolean,
    val qualifier: NleHslQualifier,
    val correction: NleSecondaryCorrection,
) {
    fun isIdentity(): Boolean {
        return !enabled || (qualifier.isIdentity() && correction.isIdentity())
    }
}

data class NleSecondaryGradeStack(
    val enabled: Boolean,
    val layers: List<NleSecondaryGradeLayer>,
) {
    fun isIdentity(): Boolean {
        return !enabled || layers.all { it.isIdentity() }
    }
}
