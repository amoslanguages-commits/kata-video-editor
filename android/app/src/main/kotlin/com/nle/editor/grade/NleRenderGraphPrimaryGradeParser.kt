package com.nle.editor.grade

import org.json.JSONObject

object NleRenderGraphPrimaryGradeParser {

    fun parseClipGrade(clipJson: JSONObject): NlePrimaryGrade {
        val json = clipJson.optJSONObject("primaryGrade")
            ?: return NlePrimaryGrade.identity()

        return NlePrimaryGrade(
            enabled = json.optBoolean("enabled", true),
            mode = NlePrimaryGradeMode.parse(json.optString("mode")),
            intensity = json.optDouble("intensity", 1.0).toFloat()
                .coerceIn(0f, 1f),
            lift = parseWheel(
                json.optJSONObject("lift"),
                defaultMaster = 0f,
                defaultRgb = NleRgbVector.ZERO,
            ),
            gamma = parseWheel(
                json.optJSONObject("gamma"),
                defaultMaster = 1f,
                defaultRgb = NleRgbVector.ONE,
            ),
            gain = parseWheel(
                json.optJSONObject("gain"),
                defaultMaster = 1f,
                defaultRgb = NleRgbVector.ONE,
            ),
            offset = parseWheel(
                json.optJSONObject("offset"),
                defaultMaster = 0f,
                defaultRgb = NleRgbVector.ZERO,
            ),
            contrast = json.optDouble("contrast", 1.0).toFloat()
                .coerceIn(0f, 4f),
            pivot = json.optDouble("pivot", 0.18).toFloat()
                .coerceIn(0.001f, 4f),
            saturation = json.optDouble("saturation", 1.0).toFloat()
                .coerceIn(0f, 4f),
        )
    }

    private fun parseWheel(
        json: JSONObject?,
        defaultMaster: Float,
        defaultRgb: NleRgbVector,
    ): NlePrimaryWheelControl {
        if (json == null) {
            return NlePrimaryWheelControl(
                master = defaultMaster,
                rgb = defaultRgb,
            )
        }

        val rgbJson = json.optJSONObject("rgb")

        return NlePrimaryWheelControl(
            master = json.optDouble("master", defaultMaster.toDouble()).toFloat(),
            rgb = if (rgbJson != null) {
                NleRgbVector(
                    r = rgbJson.optDouble("r", defaultRgb.r.toDouble()).toFloat(),
                    g = rgbJson.optDouble("g", defaultRgb.g.toDouble()).toFloat(),
                    b = rgbJson.optDouble("b", defaultRgb.b.toDouble()).toFloat(),
                )
            } else {
                defaultRgb
            },
        )
    }
}
