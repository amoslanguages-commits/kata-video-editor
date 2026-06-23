package com.nle.editor.sync

import java.util.UUID

/**
 * Collects timing telemetry during export and runs a full sync QA report.
 *
 * Inject into [NleExportMuxerCoordinator] to record video and audio sample
 * timestamps as they are written to the muxer.
 */
class NleExportSyncTelemetry {

    private val videoValidator = NleVideoFrameTimingValidator()
    private val audioValidator = NleAudioSampleTimingValidator()
    private val driftDetector  = NleAudioVideoDriftDetector()

    private var videoFrameIndex = 0
    private var audioSampleIndex = 0
    private var lastAudioPtsUs = 0L

    // ── Record hooks ─────────────────────────────────────────────────────────

    fun onVideoFrame(
        timelineTimeUs: Long,
        presentationTimeUs: Long,
        renderCostMs: Long,
    ) {
        videoValidator.record(
            frameIndex         = videoFrameIndex++,
            timelineTimeUs     = timelineTimeUs,
            presentationTimeUs = presentationTimeUs,
            renderCostMs       = renderCostMs,
        )
    }

    fun onAudioSample(
        presentationTimeUs: Long,
        durationUs: Long,
    ) {
        audioValidator.record(
            sampleIndex        = audioSampleIndex++,
            presentationTimeUs = presentationTimeUs,
            durationUs         = durationUs,
        )
        lastAudioPtsUs = presentationTimeUs
    }

    fun onDriftSample(
        videoPtsUs: Long,
        audioPtsUs: Long,
    ) {
        driftDetector.recordSample(
            index      = videoFrameIndex,
            videoPtsUs = videoPtsUs,
            audioPtsUs = audioPtsUs,
        )
    }

    // ── Report ────────────────────────────────────────────────────────────────

    fun buildReport(): NleSyncQaReport {
        val videoReport = videoValidator.validate()
        val audioReport = audioValidator.validate()
        val driftReport = driftDetector.validate()

        val allIssues = videoReport.issues + audioReport.issues + driftReport.issues

        return NleSyncQaReport(
            runId             = UUID.randomUUID().toString(),
            context           = "export",
            passed            = videoReport.passed && audioReport.passed && driftReport.passed,
            issues            = allIssues,
            videoTimingReport = videoReport,
            audioTimingReport = audioReport,
            driftReport       = driftReport,
        )
    }

    fun clear() {
        videoValidator.clear()
        audioValidator.clear()
        driftDetector.clear()
        videoFrameIndex  = 0
        audioSampleIndex = 0
        lastAudioPtsUs   = 0L
    }
}
