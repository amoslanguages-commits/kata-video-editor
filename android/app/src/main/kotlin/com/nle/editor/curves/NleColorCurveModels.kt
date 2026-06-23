package com.nle.editor.curves

enum class NleCurveType {
    RGB_MASTER,
    RED,
    GREEN,
    BLUE,
    LUMA,
    HUE_VS_SAT,
    HUE_VS_HUE,
    HUE_VS_LUM,
    LUM_VS_SAT,
    SAT_VS_SAT;

    companion object {
        fun parse(value: String?): NleCurveType {
            return when (value?.lowercase()) {
                "rgbmaster" -> RGB_MASTER
                "red" -> RED
                "green" -> GREEN
                "blue" -> BLUE
                "luma" -> LUMA
                "huevssat" -> HUE_VS_SAT
                "huevshue" -> HUE_VS_HUE
                "huevslum" -> HUE_VS_LUM
                "lumvssat" -> LUM_VS_SAT
                "satvssat" -> SAT_VS_SAT
                else -> RGB_MASTER
            }
        }
    }
}

enum class NleCurveInterpolation {
    LINEAR,
    SMOOTH;

    companion object {
        fun parse(value: String?): NleCurveInterpolation {
            return when (value?.lowercase()) {
                "linear" -> LINEAR
                "smooth" -> SMOOTH
                else -> SMOOTH
            }
        }
    }
}

enum class NleCurveEvaluationSpace {
    SCENE_LINEAR,
    DISPLAY_REFERRED;

    companion object {
        fun parse(value: String?): NleCurveEvaluationSpace {
            return when (value?.lowercase()) {
                "scenelinear" -> SCENE_LINEAR
                "displayreferred" -> DISPLAY_REFERRED
                else -> SCENE_LINEAR
            }
        }
    }
}

data class NleCurvePoint(
    val x: Float,
    val y: Float
)

data class NleColorCurve(
    val type: NleCurveType,
    val enabled: Boolean,
    val points: List<NleCurvePoint>,
    val interpolation: NleCurveInterpolation,
    val intensity: Float
) {
    companion object {
        fun identity(type: NleCurveType): NleColorCurve {
            return NleColorCurve(
                type = type,
                enabled = true,
                points = listOf(NleCurvePoint(0f, 0f), NleCurvePoint(1f, 1f)),
                interpolation = NleCurveInterpolation.SMOOTH,
                intensity = 1.0f
            )
        }
    }

    val isIdentity: Boolean
        get() {
            if (!enabled) return true
            if (points.size != 2) return false
            val a = points[0]
            val b = points[1]
            return a.x == 0f && a.y == 0f && b.x == 1f && b.y == 1f && intensity == 1.0f
        }
}

data class NleColorCurveStack(
    val enabled: Boolean,
    val evaluationSpace: NleCurveEvaluationSpace,
    val curves: List<NleColorCurve>
) {
    companion object {
        fun identity(): NleColorCurveStack {
            return NleColorCurveStack(
                enabled = true,
                evaluationSpace = NleCurveEvaluationSpace.SCENE_LINEAR,
                curves = NleCurveType.values().map { NleColorCurve.identity(it) }
            )
        }
    }

    fun curve(type: NleCurveType): NleColorCurve {
        return curves.firstOrNull { it.type == type } ?: NleColorCurve.identity(type)
    }

    val isIdentity: Boolean
        get() {
            if (!enabled) return true
            return curves.all { it.isIdentity }
        }
}
