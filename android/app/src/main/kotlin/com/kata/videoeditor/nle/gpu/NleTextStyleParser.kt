package com.kata.videoeditor.nle.gpu

import android.graphics.Color
import org.json.JSONObject

/**
 * Parses a JSON string representing a text clip's style properties into
 * an [NleTextOverlayStyle] data object.
 *
 * Unknown or missing keys fall back to [NleTextOverlayStyle] defaults.
 * Any parse error returns the default style rather than throwing.
 */
object NleTextStyleParser {

    fun parse(styleJson: String?): NleTextOverlayStyle {
        if (styleJson.isNullOrBlank()) return NleTextOverlayStyle()

        return try {
            val json = JSONObject(styleJson)

            NleTextOverlayStyle(
                fontSize          = json.optDouble("fontSize",          48.0).toFloat(),
                color             = parseColor(json.optString("color",             "#FFFFFFFF")),
                opacity           = json.optDouble("opacity",           1.0).toFloat().coerceIn(0f, 1f),
                strokeColor       = parseColor(json.optString("strokeColor",       "#FF000000")),
                strokeWidth       = json.optDouble("strokeWidth",       0.0).toFloat(),
                shadowEnabled     = json.optBoolean("shadowEnabled",    false),
                shadowColor       = parseColor(json.optString("shadowColor",       "#AA000000")),
                shadowBlur        = json.optDouble("shadowBlur",        8.0).toFloat(),
                shadowOffsetX     = json.optDouble("shadowOffsetX",     3.0).toFloat(),
                shadowOffsetY     = json.optDouble("shadowOffsetY",     3.0).toFloat(),
                backgroundEnabled = json.optBoolean("backgroundEnabled", false),
                backgroundColor   = parseColor(json.optString("backgroundColor",  "#66000000")),
                backgroundRadius  = json.optDouble("backgroundRadius",  18.0).toFloat(),
                alignment         = json.optString("alignment",         "center")
            )
        } catch (_: Throwable) {
            NleTextOverlayStyle()
        }
    }

    private fun parseColor(raw: String): Int {
        return try {
            Color.parseColor(raw)
        } catch (_: Throwable) {
            0xFFFFFFFF.toInt()
        }
    }
}
