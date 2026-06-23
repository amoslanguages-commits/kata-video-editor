package com.kata.videoeditor.nle

/**
 * 29F: Dual Preview Manager.
 *
 * Owns two independent monitor slots (SOURCE and PROGRAM).
 * Each monitor uses a separate [NlePreviewBridgeEventSink] so events
 * sent back to Flutter always carry the correct [monitorId].
 *
 * The actual GPU/decoder work is still delegated to [NleEngineManager]
 * which holds the single shared compositor.  We track the "last active
 * monitorId" so the engine can tag its outgoing events correctly.
 */
class NleDualPreviewManager(
    private val engineManager: NleEngineManager,
    private val sendEvent: (String, Map<String, Any?>) -> Unit,
) {
    companion object {
        const val SOURCE  = "source"
        const val PROGRAM = "program"
    }

    // Install monitor-aware sinks into the engine manager.
    // The engine will use whichever sink is currently active.
    private val sourceSink  = NlePreviewBridgeEventSink(SOURCE,  sendEvent)
    private val programSink = NlePreviewBridgeEventSink(PROGRAM, sendEvent)

    /** Currently active monitor slot for the next prepare / render call. */
    @Volatile private var activeMonitorId: String = PROGRAM

    // ── Public API (mirrors NleEngineManager true-preview surface) ───────────

    fun prepare(
        monitorId: String,
        projectId: String,
        renderGraphJson: String,
        qualityMode: String,
        preferProxy: Boolean,
        maxPreviewWidth: Int,
        maxPreviewHeight: Int,
    ): Map<String, Any?> {
        return engineManager.prepareTruePreview(
            monitorId       = monitorId,
            projectId       = projectId,
            renderGraphJson = renderGraphJson,
            qualityMode     = qualityMode,
            preferProxy     = preferProxy,
            maxPreviewWidth = maxPreviewWidth,
            maxPreviewHeight= maxPreviewHeight,
        )
    }

    fun renderFrame(
        monitorId: String,
        timelineTimeUs: Long,
    ): Map<String, Any?> {
        return engineManager.renderPreviewFrame(
            monitorId = monitorId,
            timelineTimeUs = timelineTimeUs,
        )
    }

    fun play(
        monitorId: String,
        fromTimelineTimeUs: Long,
    ): Map<String, Any?> {
        return engineManager.startTruePreview(
            monitorId = monitorId,
            fromTimelineTimeUs = fromTimelineTimeUs,
        )
    }

    fun pause(monitorId: String): Map<String, Any?> {
        return engineManager.pauseTruePreview(monitorId)
    }

    fun stop(monitorId: String): Map<String, Any?> {
        return engineManager.stopTruePreview(monitorId)
    }

    fun dispose(monitorId: String): Map<String, Any?> {
        return engineManager.disposeTruePreview(monitorId)
    }

    fun disposeAll(): Map<String, Any?> {
        engineManager.disposeTruePreview(SOURCE)
        engineManager.disposeTruePreview(PROGRAM)
        return mapOf("disposed" to true)
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /**
     * Swap the active event sink in the engine manager before each call so
     * any events the engine emits during that call carry the right monitorId.
     */
    private fun activateMonitor(monitorId: String) {
        activeMonitorId = monitorId
        val sink = if (monitorId == SOURCE) sourceSink else programSink
        engineManager.setPreviewEventSink(sink)
    }
}
