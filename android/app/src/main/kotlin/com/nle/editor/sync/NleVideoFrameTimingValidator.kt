package com.nle.editor.sync

/**
 * Validates per-frame video presentation timing.
 *
 * Call [record] for every rendered / encoded frame.
 * Call [validate] at the end of export or preview to get a [NleVideoTimingReport].
 */
class NleVideoFrameTimingValidator {

    data class FrameRecord(
        val frameIndex: Int,
        val timelineTimeUs: Long,
        val presentationTimeUs: Long,
        val renderCostMs: Long,
    )

    private val records = mutableListOf<FrameRecord>()

    fun record(
        frameIndex: Int,
        timelineTimeUs: Long,
        presentationTimeUs: Long,
        renderCostMs: Long,
    ) {
        records.add(
            FrameRecord(
                frameIndex        = frameIndex,
                timelineTimeUs    = timelineTimeUs,
                presentationTimeUs = presentationTimeUs,
                renderCostMs      = renderCostMs,
            )
        )
    }

    fun validate(): NleVideoTimingReport {
        val issues = mutableListOf<NleSyncIssue>()
        var droppedFrameCount = 0
        var maxDriftUs = 0L

        for (record in records) {
            val driftUs = kotlin.math.abs(record.presentationTimeUs - record.timelineTimeUs)
            if (driftUs > maxDriftUs) maxDriftUs = driftUs

            if (driftUs > NleSyncThresholds.MAX_FRAME_DRIFT_US) {
                issues.add(
                    NleSyncIssue(
                        id      = "video.frame.${record.frameIndex}.drift",
                        message = "Frame ${record.frameIndex} drift ${driftUs}µs exceeds threshold " +
                                  "${NleSyncThresholds.MAX_FRAME_DRIFT_US}µs.",
                    )
                )
            }

            if (record.renderCostMs > NleSyncThresholds.MAX_RENDER_COST_MS) {
                droppedFrameCount++
                issues.add(
                    NleSyncIssue(
                        id      = "video.frame.${record.frameIndex}.slow",
                        message = "Frame ${record.frameIndex} render cost ${record.renderCostMs}ms " +
                                  "exceeds ${NleSyncThresholds.MAX_RENDER_COST_MS}ms.",
                    )
                )
            }
        }

        return NleVideoTimingReport(
            totalFrames       = records.size,
            droppedFrameCount = droppedFrameCount,
            maxDriftUs        = maxDriftUs,
            passed            = issues.none { it.severity == "fail" },
            issues            = issues,
        )
    }

    fun clear() = records.clear()
}

data class NleVideoTimingReport(
    val totalFrames: Int,
    val droppedFrameCount: Int,
    val maxDriftUs: Long,
    val passed: Boolean,
    val issues: List<NleSyncIssue>,
)
