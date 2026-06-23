package com.kata.videoeditor.nle

import org.json.JSONArray
import org.json.JSONObject

data class NleGraphValidationResult(
    val valid: Boolean,
    val warnings: List<String> = emptyList(),
    val errors: List<String> = emptyList(),
    val summary: Map<String, Any?> = emptyMap()
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "valid"    to valid,
        "warnings" to warnings,
        "errors"   to errors,
        "summary"  to summary
    )
}

class NleRenderGraphParser {

    fun parse(renderGraphJson: String): JSONObject =
        JSONObject(renderGraphJson)

    fun validate(renderGraph: JSONObject): NleGraphValidationResult {
        val warnings = mutableListOf<String>()
        val errors   = mutableListOf<String>()

        if (renderGraph.optJSONObject("project") == null) {
            errors.add("Missing 'project' object.")
        }

        val assets      = renderGraph.optJSONArray("assets")      ?: JSONArray()
        val tracks      = renderGraph.optJSONArray("tracks")      ?: JSONArray()
        val clips       = renderGraph.optJSONArray("clips")       ?: JSONArray()
        val transitions = renderGraph.optJSONArray("transitions") ?: JSONArray()

        if (tracks.length() == 0) warnings.add("Project has no tracks.")
        if (clips.length()  == 0) warnings.add("Project has no clips.")

        // Build known asset-id set
        val assetIds = mutableSetOf<String>()
        for (i in 0 until assets.length()) {
            assets.optJSONObject(i)?.optString("id", "")?.takeIf { it.isNotBlank() }
                ?.let { assetIds.add(it) }
        }

        // Validate each clip
        for (i in 0 until clips.length()) {
            val clip   = clips.optJSONObject(i) ?: continue
            val clipId = clip.optString("id", "clip_$i")
            val start  = clip.optLong("timelineStartMicros", -1L)
            val end    = clip.optLong("timelineEndMicros",   -1L)

            if (start < 0 || end <= start) {
                errors.add("Clip $clipId has invalid timing (start=$start end=$end).")
            }

            val assetId  = clip.optString("assetId", "")
            val clipType = clip.optString("type", "")
            if (clipType != "text" && assetId.isNotBlank() && !assetIds.contains(assetId)) {
                warnings.add("Clip $clipId references unknown asset $assetId.")
            }
        }

        // Validate transitions
        for (i in 0 until transitions.length()) {
            val t = transitions.optJSONObject(i) ?: continue
            if (t.optLong("durationMicros", 0L) <= 0) {
                warnings.add("Transition ${t.optString("id", "unknown")} has zero or missing durationMicros.")
            }
        }

        return NleGraphValidationResult(
            valid    = errors.isEmpty(),
            warnings = warnings,
            errors   = errors,
            summary  = mapOf(
                "assetCount"      to assets.length(),
                "trackCount"      to tracks.length(),
                "clipCount"       to clips.length(),
                "transitionCount" to transitions.length()
            )
        )
    }
}
