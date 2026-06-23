package com.nle.editor.sync

/**
 * Top-level sync QA runner for 29D.
 *
 * Delegates to [NleExportSyncTelemetry] or [NlePreviewSyncTelemetry]
 * and returns a standardized [NleSyncQaReport].
 */
class NleAndroidSyncQaRunner {

    val exportTelemetry  = NleExportSyncTelemetry()
    val previewTelemetry = NlePreviewSyncTelemetry()

    /** Run and return the export sync QA report. */
    fun runExportQa(): NleSyncQaReport {
        return exportTelemetry.buildReport()
    }

    /** Run and return the preview sync QA report. */
    fun runPreviewQa(): NleSyncQaReport {
        return previewTelemetry.buildReport()
    }

    /** Clear all telemetry (call before a new export or preview session). */
    fun clearAll() {
        exportTelemetry.clear()
        previewTelemetry.clear()
    }
}
