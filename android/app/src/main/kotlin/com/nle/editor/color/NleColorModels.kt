package com.nle.editor.color

enum class NleColorSpace {
    AUTO,
    SRGB,
    REC709,
    DISPLAY_P3,
    REC2020,
    ACES_CG,
    ACES_2065,
    CAMERA_LOG,
    UNKNOWN;

    companion object {
        fun parse(value: String?): NleColorSpace {
            return when (value?.lowercase()) {
                "auto" -> AUTO
                "srgb" -> SRGB
                "rec709" -> REC709
                "displayp3", "display_p3", "display-p3" -> DISPLAY_P3
                "rec2020" -> REC2020
                "acescg", "aces_cg" -> ACES_CG
                "aces2065", "aces_2065" -> ACES_2065
                "cameralog", "camera_log" -> CAMERA_LOG
                else -> UNKNOWN
            }
        }
    }
}

enum class NleTransferCurve {
    AUTO,
    LINEAR,
    SRGB,
    REC709,
    GAMMA22,
    GAMMA24,
    LOG_C,
    SLOG3,
    CLOG3,
    VLOG,
    HLG,
    PQ,
    UNKNOWN;

    companion object {
        fun parse(value: String?): NleTransferCurve {
            return when (value?.lowercase()) {
                "auto" -> AUTO
                "linear" -> LINEAR
                "srgb" -> SRGB
                "rec709" -> REC709
                "gamma22" -> GAMMA22
                "gamma24" -> GAMMA24
                "logc", "log_c" -> LOG_C
                "slog3" -> SLOG3
                "clog3" -> CLOG3
                "vlog", "v_log" -> VLOG
                "hlg" -> HLG
                "pq" -> PQ
                else -> UNKNOWN
            }
        }
    }
}

enum class NleWorkingColorSpace {
    LINEAR_SRGB,
    LINEAR_REC709,
    ACES_CG;

    companion object {
        fun parse(value: String?): NleWorkingColorSpace {
            return when (value?.lowercase()) {
                "linearsrgb", "linear_srgb" -> LINEAR_SRGB
                "acescg", "aces_cg" -> ACES_CG
                "linearrec709", "linear_rec709" -> LINEAR_REC709
                else -> LINEAR_REC709
            }
        }
    }
}

enum class NleOutputColorSpace {
    REC709,
    SRGB,
    DISPLAY_P3,
    REC2020;

    companion object {
        fun parse(value: String?): NleOutputColorSpace {
            return when (value?.lowercase()) {
                "srgb" -> SRGB
                "displayp3", "display_p3", "display-p3" -> DISPLAY_P3
                "rec2020" -> REC2020
                "rec709" -> REC709
                else -> REC709
            }
        }
    }
}

enum class NleOutputTransferCurve {
    SRGB,
    REC709,
    GAMMA24,
    HLG,
    PQ;

    companion object {
        fun parse(value: String?): NleOutputTransferCurve {
            return when (value?.lowercase()) {
                "srgb" -> SRGB
                "gamma24" -> GAMMA24
                "hlg" -> HLG
                "pq" -> PQ
                "rec709" -> REC709
                else -> REC709
            }
        }
    }
}

enum class NleColorPipelineQuality {
    AUTO,
    COMPATIBILITY_8BIT,
    STANDARD_16F,
    HIGH_PRECISION_32F;

    companion object {
        fun parse(value: String?): NleColorPipelineQuality {
            return when (value?.lowercase()) {
                "compatibility8bit", "compatibility_8bit" -> COMPATIBILITY_8BIT
                "standard16f", "standard_16f" -> STANDARD_16F
                "highprecision32f", "high_precision_32f" -> HIGH_PRECISION_32F
                "auto" -> AUTO
                else -> AUTO
            }
        }
    }
}

enum class NleToneMapMode {
    NONE,
    SIMPLE_REINHARD,
    ACES_APPROX,
    HABLE;

    companion object {
        fun parse(value: String?): NleToneMapMode {
            return when (value?.lowercase()) {
                "simplereinhard", "simple_reinhard" -> SIMPLE_REINHARD
                "acesapprox", "aces_approx" -> ACES_APPROX
                "hable" -> HABLE
                else -> NONE
            }
        }
    }
}

data class NleInputColorTransform(
    val colorSpace: NleColorSpace,
    val transferCurve: NleTransferCurve,
    val fullRange: Boolean,
    val exposureBias: Float,
    val inputBlackLevel: Float,
    val inputWhiteLevel: Float,
)

data class NleWorkingColorTransform(
    val workingSpace: NleWorkingColorSpace,
    val sceneLinear: Boolean,
    val clampNegative: Boolean,
    val allowSuperWhites: Boolean,
)

data class NleOutputColorTransform(
    val colorSpace: NleOutputColorSpace,
    val transferCurve: NleOutputTransferCurve,
    val toneMapMode: NleToneMapMode,
    val outputBlackLevel: Float,
    val outputWhiteLevel: Float,
    val dither: Boolean,
    val legalRange: Boolean,
)

data class NleColorManagementPipeline(
    val enabled: Boolean,
    val quality: NleColorPipelineQuality,
    val defaultInput: NleInputColorTransform,
    val working: NleWorkingColorTransform,
    val previewOutput: NleOutputColorTransform,
    val exportOutput: NleOutputColorTransform,
    val forceCompatibilityMode: Boolean,
    val previewMatchesExport: Boolean,
    val assetInputTransforms: Map<String, NleInputColorTransform>,
)
