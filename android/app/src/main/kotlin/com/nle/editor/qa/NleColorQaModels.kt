package com.nle.editor.qa

enum class NleColorQaSeverity {
    INFO,
    WARNING,
    ERROR,
    RELEASE_BLOCKER
}

enum class NleColorQaArea {
    COLOR_MANAGEMENT,
    GPU_PIPELINE,
    SHADER_COMPILE,
    PREVIEW_EXPORT,
    DEVICE_FALLBACK,
    MEMORY_LEAK,
    HDR_OUTPUT,
    SCOPE_ACCURACY
}

data class NleColorQaIssue(
    val id: String,
    val severity: NleColorQaSeverity,
    val area: NleColorQaArea,
    val title: String,
    val message: String,
    val suggestedFix: String? = null
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "severity" to severity.name.lowercase(),
            "area" to area.name.lowercase(),
            "title" to title,
            "message" to message,
            "suggestedFix" to suggestedFix
        )
    }
}

data class NleColorQaReport(
    val timestamp: Long,
    val passed: Boolean,
    val issues: List<NleColorQaIssue>
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "timestamp" to timestamp,
            "passed" to passed,
            "issues" to issues.map { it.toMap() }
        )
    }
}
