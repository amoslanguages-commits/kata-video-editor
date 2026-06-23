package com.nle.editor.lut

import org.json.JSONObject

object NleRenderGraphLutParser {

    fun parseClipStack(clipJson: JSONObject): NleLutStack {
        val clipId = clipJson.optString("id")
        val stackJson = clipJson.optJSONObject("lutStack")

        if (stackJson == null) {
            return NleLutStack(
                clipId = clipId,
                layers = emptyList(),
            )
        }

        val layersJson = stackJson.optJSONArray("layers")
        val layers = mutableListOf<NleLutLayer>()

        if (layersJson != null) {
            for (i in 0 until layersJson.length()) {
                val layerJson = layersJson.optJSONObject(i) ?: continue

                layers.add(
                    NleLutLayer(
                        id = layerJson.optString("id"),
                        lutAssetId = layerJson.optString("lutAssetId"),
                        lutPath = layerJson.optString("lutPath"),
                        name = layerJson.optString("name", "LUT"),
                        size = layerJson.optInt("size", 0),
                        intensity = layerJson.optDouble("intensity", 1.0).toFloat()
                            .coerceIn(0f, 1f),
                        enabled = layerJson.optBoolean("enabled", true),
                        domain = NleLutDomain.parse(layerJson.optString("domain")),
                        interpolation = NleLutInterpolation.parse(
                            layerJson.optString("interpolation"),
                        ),
                    )
                )
            }
        }

        return NleLutStack(
            clipId = clipId,
            layers = layers,
        )
    }
}
