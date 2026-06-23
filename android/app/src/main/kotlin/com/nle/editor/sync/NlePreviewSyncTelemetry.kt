package com.nle.editor.sync

import java.util.UUID

/**
 * Collects timing telemetry during live preview playback and produces a sync report.
 *
 * Inject into [NlePreviewFrameScheduler].
 * Call [startSession] when playback starts.
 * Call [onFrame] for every rendered frame.
 * Call [buildReport] when playback ends or is stopped.
 */
class NlePreviewSyncTelemetry {

    private val previewValidator = NlePreviewSyncValidator()
    private var frameIndex = 0

    fun startSession(fromTimelineUs: Long) {
        previewValidator.startSession(fromTimelineUs)
        frameIndex = 0
    }

    fun onFrame(
        timelineTimeUs: Long,
        renderCostMs: Long,
    ) {
        previewValidator.recordFrame(
            frameIndex     = frameIndex++,
            timelineTimeUs = timelineTimeUs,
            renderCostMs   = renderCostMs,
        )
    }

    fun buildReport(): NleSyncQaReport {
        val previewReport = previewValidator.validate()

        return NleSyncQaReport(
            runId             = UUID.randomUUID().toString(),
            context           = "preview",
            passed            = previewReport.passed,
            issues            = previewReport.issues,
            videoTimingReport = NleVideoTimingReport(
                totalFrames       = previewReport.totalFrames,
                droppedFrameCount = previewReport.droppedFrames,
                maxDriftUs        = previewReport.maxWallDriftUs,
                passed            = previewReport.passed,
                issues            = previewReport.issues,
            ),
            audioTimingReport = null,
            driftReport       = null,
        )
    }

    fun clear() {
        previewValidator.clear()
        frameIndex = 0
    }
}
