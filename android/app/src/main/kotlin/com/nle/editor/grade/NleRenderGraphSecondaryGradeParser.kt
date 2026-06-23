package com.nle.editor.grade

import org.json.JSONObject
import org.json.JSONArray

object NleRenderGraphSecondaryGradeParser {

    fun parseClipStack(clipJson: JSONObject): NleSecondaryGradeStack? {
        val json = clipJson.optJSONObject("secondaryGrades") ?: return null

        val enabled = json.optBoolean("enabled", true)
        val layersArray = json.optJSONArray("layers")
        val layersList = mutableListOf<NleSecondaryGradeLayer>()

        if (layersArray != null) {
            for (i in 0 until layersArray.length()) {
                val layerJson = layersArray.optJSONObject(i) ?: continue
                val id = layerJson.optString("id", "")
                val name = layerJson.optString("name", "Secondary")
                val layerEnabled = layerJson.optBoolean("enabled", true)

                val qualifierJson = layerJson.optJSONObject("qualifier")
                val qualifier = if (qualifierJson != null) {
                    parseQualifier(qualifierJson)
                } else {
                    NleHslQualifier(
                        enabled = false,
                        hue = NleRangeControl(0.5f, 1.0f, 0.0f),
                        saturation = NleRangeControl(0.5f, 1.0f, 0.0f),
                        luminance = NleRangeControl(0.5f, 1.0f, 0.0f),
                        cleanBlack = 0.0f,
                        cleanWhite = 0.0f,
                        blur = 0.0f,
                        invert = false,
                        viewMode = NleQualifierViewMode.NORMAL
                    )
                }

                val correctionJson = layerJson.optJSONObject("correction")
                val correction = if (correctionJson != null) {
                    parseCorrection(correctionJson)
                } else {
                    NleSecondaryCorrection(
                        enabled = true,
                        intensity = 1.0f,
                        exposure = 0.0f,
                        contrast = 1.0f,
                        saturation = 1.0f,
                        temperature = 0.0f,
                        tint = 0.0f,
                        lift = 0.0f,
                        gamma = 1.0f,
                        gain = 1.0f,
                        offset = 0.0f
                    )
                }

                layersList.add(
                    NleSecondaryGradeLayer(
                        id = id,
                        name = name,
                        enabled = layerEnabled,
                        qualifier = qualifier,
                        correction = correction
                    )
                )
            }
        }

        return NleSecondaryGradeStack(
            enabled = enabled,
            layers = layersList
        )
    }

    private fun parseQualifier(json: JSONObject): NleHslQualifier {
        return NleHslQualifier(
            enabled = json.optBoolean("enabled", false),
            hue = parseRange(json.optJSONObject("hue"), 0.5f, 1.0f, 0.0f),
            saturation = parseRange(json.optJSONObject("saturation"), 0.5f, 1.0f, 0.0f),
            luminance = parseRange(json.optJSONObject("luminance"), 0.5f, 1.0f, 0.0f),
            cleanBlack = json.optDouble("cleanBlack", 0.0).toFloat(),
            cleanWhite = json.optDouble("cleanWhite", 0.0).toFloat(),
            blur = json.optDouble("blur", 0.0).toFloat(),
            invert = json.optBoolean("invert", false),
            viewMode = NleQualifierViewMode.parse(json.optString("viewMode"))
        )
    }

    private fun parseRange(json: JSONObject?, defaultCenter: Float, defaultWidth: Float, defaultSoftness: Float): NleRangeControl {
        if (json == null) {
            return NleRangeControl(defaultCenter, defaultWidth, defaultSoftness)
        }
        return NleRangeControl(
            center = json.optDouble("center", defaultCenter.toDouble()).toFloat(),
            width = json.optDouble("width", defaultWidth.toDouble()).toFloat(),
            softness = json.optDouble("softness", defaultSoftness.toDouble()).toFloat()
        ).clamp()
    }

    private fun parseCorrection(json: JSONObject): NleSecondaryCorrection {
        return NleSecondaryCorrection(
            enabled = json.optBoolean("enabled", true),
            intensity = json.optDouble("intensity", 1.0).toFloat(),
            exposure = json.optDouble("exposure", 0.0).toFloat(),
            contrast = json.optDouble("contrast", 1.0).toFloat(),
            saturation = json.optDouble("saturation", 1.0).toFloat(),
            temperature = json.optDouble("temperature", 0.0).toFloat(),
            tint = json.optDouble("tint", 0.0).toFloat(),
            lift = json.optDouble("lift", 0.0).toFloat(),
            gamma = json.optDouble("gamma", 1.0).toFloat(),
            gain = json.optDouble("gain", 1.0).toFloat(),
            offset = json.optDouble("offset", 0.0).toFloat()
        )
    }
}
