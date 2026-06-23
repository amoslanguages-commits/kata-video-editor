package com.nle.editor.sync

import android.os.SystemClock

/**
 * Validates preview frame timing against wall-clock expectations.
 *
 * During preview playback, call [recordFrame] for every rendered frame.
 * Call [validate] after preview ends or is stopped.
 */
class NlePreviewSyncValidator {

    data class PreviewFrameRecord(
        val frameIndex: Int,
        val timelineTimeUs: Long,
        val wallClockMs: Long,
        val renderCostMs: Long,
    )

    private val records = mutableListOf<PreviewFrameRecord>()
    private var sessionStartTimelineUs: Long = 0L
    private var sessionStartWallMs: Long = 0L

    fun startSession(fromTimelineUs: Long) {
        sessionStartTimelineUs = fromTimelineUs
        sessionStartWallMs     = SystemClock.elapsedRealtime()
        records.clear()
    }

    fun recordFrame(
        frameIndex: Int,
        timelineTimeUs: Long,
        renderCostMs: Long,
    ) {
        records.add(
            PreviewFrameRecord(
                frameIndex     = frameIndex,
                timelineTimeUs = timelineTimeUs,
                wallClockMs    = SystemClock.elapsedRealtime(),
                renderCostMs   = renderCostMs,
            )
        )
    }

    fun validate(): NlePreviewSyncReport {
        val issues = mutableListOf<NleSyncIssue>()
        var droppedFrames = 0
        var maxWallDriftUs = 0L

        for (record in records) {
            // Expected timeline position based on real time elapsed
            val elapsedMs = record.wallClockMs - sessionStartWallMs
            val expectedTimelineUs = sessionStartTimelineUs + elapsedMs * 1_000L

            val wallDriftUs = kotlin.math.abs(record.timelineTimeUs - expectedTimelineUs)
            if (wallDriftUs > maxWallDriftUs) maxWallDriftUs = wallDriftUs

            if (wallDriftUs > NleSyncThresholds.MAX_FRAME_DRIFT_US * 3) {
                issues.add(
                    NleSyncIssue(
                        id      = "preview.frame.${record.frameIndex}.drift",
                        message = "Preview frame ${record.frameIndex} wall-clock drift ${wallDriftUs}µs.",
                        severity = "warning",
                    )
                )
            }

            if (record.renderCostMs > NleSyncThresholds.MAX_RENDER_COST_MS) {
                droppedFrames++
                issues.add(
                    NleSyncIssue(
                        id      = "preview.frame.${record.frameIndex}.slow",
                        message = "Preview frame ${record.frameIndex} render cost ${record.renderCostMs}ms " +
                                  "exceeded ${NleSyncThresholds.MAX_RENDER_COST_MS}ms.",
                        severity = "warning",
                    )
                )
            }
        }

        return NlePreviewSyncReport(
            totalFrames    = records.size,
            droppedFrames  = droppedFrames,
            maxWallDriftUs = maxWallDriftUs,
            passed         = issues.none { it.severity == "fail" },
            issues         = issues,
        )
    }

    fun clear() = records.clear()
}

data class NlePreviewSyncReport(
    val totalFrames: Int,
    val droppedFrames: Int,
    val maxWallDriftUs: Long,
    val passed: Boolean,
    val issues: List<NleSyncIssue>,
)
