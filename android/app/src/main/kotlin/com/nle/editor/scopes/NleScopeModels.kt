package com.nle.editor.scopes

enum class NleScopeType {
    WAVEFORM,
    RGB_PARADE,
    VECTORSCOPE,
    HISTOGRAM;

    companion object {
        fun parse(value: String?): NleScopeType {
            return when (value?.lowercase()) {
                "rgbparade", "rgb_parade" -> RGB_PARADE
                "vectorscope" -> VECTORSCOPE
                "histogram" -> HISTOGRAM
                "waveform" -> WAVEFORM
                else -> WAVEFORM
            }
        }
    }
}

enum class NleScopeColorSpace {
    DISPLAY_REFERRED,
    SCENE_LINEAR;

    companion object {
        fun parse(value: String?): NleScopeColorSpace {
            return when (value?.lowercase()) {
                "scenelinear", "scene_linear" -> SCENE_LINEAR
                "displayreferred", "display_referred" -> DISPLAY_REFERRED
                else -> DISPLAY_REFERRED
            }
        }
    }
}

data class NleScopeSettings(
    val enabled: Boolean,
    val activeType: NleScopeType,
    val colorSpace: NleScopeColorSpace,
    val showSkinToneLine: Boolean,
    val showClippingWarnings: Boolean,
    val showGrid: Boolean,
    val showOverlay: Boolean,
    val refreshFps: Double,
    val sampleWidth: Int,
    val sampleHeight: Int,
) {
    companion object {
        fun fromPayload(map: Map<String, Any?>): NleScopeSettings {
            return NleScopeSettings(
                enabled = map["enabled"] as? Boolean ?: true,
                activeType = NleScopeType.parse(map["activeType"] as? String),
                colorSpace = NleScopeColorSpace.parse(map["colorSpace"] as? String),
                showSkinToneLine = map["showSkinToneLine"] as? Boolean ?: true,
                showClippingWarnings = map["showClippingWarnings"] as? Boolean ?: true,
                showGrid = map["showGrid"] as? Boolean ?: true,
                showOverlay = map["showOverlay"] as? Boolean ?: false,
                refreshFps = (map["refreshFps"] as? Number)?.toDouble() ?: 12.0,
                sampleWidth = (map["sampleWidth"] as? Number)?.toInt() ?: 256,
                sampleHeight = (map["sampleHeight"] as? Number)?.toInt() ?: 144,
            )
        }
    }
}
