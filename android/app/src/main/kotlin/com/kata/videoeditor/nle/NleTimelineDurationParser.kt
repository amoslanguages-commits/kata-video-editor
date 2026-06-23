package com.kata.videoeditor.nle

import org.json.JSONObject

/**
 * Extracts the total timeline duration from a render-graph JSON object.
 *
 * Strategy (in priority order):
 *  1. `project.durationMicros`   – explicit override set by the editor
 *  2. Max of all clip `timelineEndMicros` values
 *  3. 0L if the graph has no clips
 */
object NleTimelineDurationParser {

    fun parse(renderGraph: JSONObject): Long {
        // 1. Explicit project duration
        val project = renderGraph.optJSONObject("project")
        if (project != null) {
            val explicit = project.optLong("durationMicros", 0L)
            if (explicit > 0L) return explicit
        }

        // 2. Derive from clips
        val clips = renderGraph.optJSONArray("clips") ?: return 0L
        var maxEnd = 0L
        for (i in 0 until clips.length()) {
            val clip = clips.optJSONObject(i) ?: continue
            val end = clip.optLong("timelineEndMicros", 0L)
            if (end > maxEnd) maxEnd = end
        }
        return maxEnd
    }
}
