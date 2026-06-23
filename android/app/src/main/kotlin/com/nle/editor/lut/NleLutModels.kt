package com.nle.editor.lut

enum class NleLutDomain {
    SCENE_LINEAR,
    DISPLAY_REFERRED,
    LOG;

    companion object {
        fun parse(value: String?): NleLutDomain {
            return when (value?.lowercase()) {
                "displayreferred", "display_referred" -> DISPLAY_REFERRED
                "log" -> LOG
                "scenelinear", "scene_linear" -> SCENE_LINEAR
                else -> SCENE_LINEAR
            }
        }
    }
}

enum class NleLutInterpolation {
    NEAREST,
    TRILINEAR;

    companion object {
        fun parse(value: String?): NleLutInterpolation {
            return when (value?.lowercase()) {
                "nearest" -> NEAREST
                "trilinear" -> TRILINEAR
                else -> TRILINEAR
            }
        }
    }
}

enum class NleLutTextureMode {
    TEXTURE_3D,
    TEXTURE_2D_ATLAS,
}

data class NleLutLayer(
    val id: String,
    val lutAssetId: String,
    val lutPath: String,
    val name: String,
    val size: Int,
    val intensity: Float,
    val enabled: Boolean,
    val domain: NleLutDomain,
    val interpolation: NleLutInterpolation,
)

data class NleLutStack(
    val clipId: String,
    val layers: List<NleLutLayer>,
) {
    val hasEnabledLuts: Boolean
        get() = layers.any { it.enabled && it.intensity > 0f }
}

data class NleCubeLutData(
    val title: String,
    val size: Int,
    val values: FloatArray,
) {
    val expectedFloatCount: Int
        get() = size * size * size * 3

    fun validate() {
        require(size > 1) {
            "Invalid LUT size: $size"
        }

        require(values.size == expectedFloatCount) {
            "Invalid LUT data length. Expected $expectedFloatCount, got ${values.size}"
        }
    }
}
