package com.nle.editor.sync

/**
 * Common sync issue model used by all 29D validators.
 */
data class NleSyncIssue(
    val id: String,
    val message: String,
    val severity: String = "fail",
) {
    fun toPayload(): Map<String, Any?> = mapOf(
        "id"       to id,
        "message"  to message,
        "severity" to severity,
    )
}

/**
 * Summary report combining all sync QA validators.
 */
data class NleSyncQaReport(
    val runId: String,
    val context: String,               // "export" | "preview"
    val passed: Boolean,
    val issues: List<NleSyncIssue>,
    val videoTimingReport: NleVideoTimingReport?,
    val audioTimingReport: NleAudioTimingReport?,
    val driftReport: NleDriftReport?,
) {
    fun toPayload(): Map<String, Any?> = mapOf(
        "runId"   to runId,
        "context" to context,
        "passed"  to passed,
        "issueCount" to issues.size,
        "issues"  to issues.map { it.toPayload() },
        "videoTiming" to videoTimingReport?.let {
            mapOf(
                "totalFrames"       to it.totalFrames,
                "droppedFrameCount" to it.droppedFrameCount,
                "maxDriftUs"        to it.maxDriftUs,
                "passed"            to it.passed,
            )
        },
        "audioTiming" to audioTimingReport?.let {
            mapOf(
                "totalSamples"   to it.totalSamples,
                "gapCount"       to it.gapCount,
                "maxGapUs"       to it.maxGapUs,
                "passed"         to it.passed,
            )
        },
        "drift" to driftReport?.let {
            mapOf(
                "cumulativeDriftUs" to it.cumulativeDriftUs,
                "sampleCount"       to it.sampleCount,
                "passed"            to it.passed,
            )
        },
    )
}
