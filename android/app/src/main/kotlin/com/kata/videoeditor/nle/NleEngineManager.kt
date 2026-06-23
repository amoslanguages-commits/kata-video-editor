package com.kata.videoeditor.nle

import android.content.Context
import io.flutter.view.TextureRegistry
import java.util.concurrent.ConcurrentHashMap
import com.kata.videoeditor.nle.gpu.NleCompositorSession
import com.kata.videoeditor.nle.export.NleExportMode
import com.nle.editor.preview.*
import com.nle.editor.scopes.NleScopeManager
import com.nle.editor.scopes.NleScopeSettings


/**
 * Manages the lifecycle of the native engine and all open project sessions.
 *
 * Thread-safe: [sessions] and [audioEngines] use [ConcurrentHashMap].
 * All public functions may be called from the platform-channel background thread.
 */
class NleEngineManager(
    private val context: Context,
    private val eventEmitter: NleNativeEventEmitter,
    private val textureRegistry: TextureRegistry
) {
    private val parser      = NleRenderGraphParser()
    private val deviceProbe = NleDeviceCapabilityProbe(context)

    private val previewTextureManager = NlePreviewTextureManager(
        textureRegistry = textureRegistry,
        eventEmitter    = eventEmitter
    )

    private val sessions     = ConcurrentHashMap<String, NleEngineSession>()
    private val audioEngines = ConcurrentHashMap<String, NleAudioEngine>()
    private val proxyJobManager  = NleProxyJobManager(eventEmitter)
    private val compositorSession = NleCompositorSession()
    private val exportJobManager = NleExportJobManager(eventEmitter, compositorSession)
    private val truePreviewManagers = ConcurrentHashMap<String, NlePreviewManager>()

    private val scopeManager = NleScopeManager(
        sendEvent = { type, payload ->
            eventEmitter.emit(
                NleNativeEvent(
                    type = type,
                    payload = payload
                )
            )
        }
    )

    @Volatile private var initialized = false

    // ── Lifecycle ────────────────────────────────────────────────────────────

    fun initialize(): Map<String, Any?> {
        initialized = true
        eventEmitter.emit(
            NleNativeEvent(
                type    = NleNativeEventType.ENGINE_READY,
                payload = mapOf(
                    "platform"      to "android",
                    "version"       to "native_engine_v1",
                    "initialized"   to true
                )
            )
        )
        return mapOf(
            "success"       to true,
            "platform"      to "android",
            "engineVersion" to "native_engine_v1"
        )
    }

    fun dispose(): Map<String, Any?> {
        audioEngines.values.forEach { it.release() }
        audioEngines.clear()
        sessions.clear()
        previewTextureManager.disposeAll()
        proxyJobManager.dispose()
        exportJobManager.dispose()
        truePreviewManagers.values.forEach { it.release() }
        truePreviewManagers.clear()
        compositorSession.release()
        scopeManager.stopLive()
        initialized = false
        eventEmitter.emit(
            NleNativeEvent(
                type    = NleNativeEventType.ENGINE_DISPOSED,
                payload = mapOf("disposed" to true)
            )
        )
        return mapOf("success" to true)
    }

    // ── Graph operations ─────────────────────────────────────────────────────

    fun loadRenderGraph(
        projectId: String,
        renderGraphJson: String,
        commandId: String?
    ): Map<String, Any?> {
        requireInit()
        val graph      = parser.parse(renderGraphJson)
        val validation = parser.validate(graph)
        if (!validation.valid) {
            throw IllegalArgumentException(
                "${NleNativeErrorCode.GRAPH_VALIDATION_FAILED}: ${validation.errors.joinToString()}"
            )
        }

        val session = NleEngineSession(projectId, renderGraphJson)
        sessions[projectId] = session

        // Create audio engine for this session
        val audioEngine = createAudioEngineForSession(session)
        audioEngines[projectId] = audioEngine

        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.GRAPH_LOADED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload   = mapOf("validation" to validation.toMap())
            )
        )
        return mapOf(
            "success"    to true,
            "session"    to session.toMap(),
            "validation" to validation.toMap()
        )
    }

    fun updateRenderGraph(
        projectId: String,
        renderGraphJson: String,
        reason: String?,
        commandId: String?
    ): Map<String, Any?> {
        requireInit()
        val session = requireSession(projectId)
        val graph   = parser.parse(renderGraphJson)
        val validation = parser.validate(graph)
        if (!validation.valid) {
            throw IllegalArgumentException(
                "${NleNativeErrorCode.GRAPH_VALIDATION_FAILED}: ${validation.errors.joinToString()}"
            )
        }
        session.updateGraph(renderGraphJson)

        // Update duration in the running audio engine
        audioEngines[projectId]?.setDuration(session.durationMicros)

        truePreviewManagers.values.forEach { manager ->
            if (manager.currentGraph() != null) {
                try {
                    manager.updateRenderGraph(renderGraphJson, preferProxy = true)
                } catch (_: Throwable) {}
            }
        }

        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.GRAPH_UPDATED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload   = mapOf(
                    "reason"     to reason,
                    "validation" to validation.toMap()
                )
            )
        )
        return mapOf(
            "success"    to true,
            "session"    to session.toMap(),
            "validation" to validation.toMap()
        )
    }

    fun validateRenderGraph(renderGraphJson: String): Map<String, Any?> {
        requireInit()
        val validation = parser.validate(parser.parse(renderGraphJson))
        return mapOf(
            "success" to validation.valid,
            "valid"   to validation.valid
        ) + validation.toMap()
    }

    // ── Playback ─────────────────────────────────────────────────────────────

    fun play(projectId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        val session = requireSession(projectId)
        session.play()

        audioEngines[projectId]?.play()

        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.PLAYBACK_STARTED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload   = mapOf("playheadMicros" to session.playheadMicros)
            )
        )
        return mapOf("success" to true, "session" to session.toMap())
    }

    fun pause(projectId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        val session = requireSession(projectId)
        session.pause()

        audioEngines[projectId]?.pause()

        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.PLAYBACK_PAUSED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload   = mapOf("playheadMicros" to session.playheadMicros)
            )
        )
        return mapOf("success" to true, "session" to session.toMap())
    }

    fun seek(projectId: String, positionMicros: Long, commandId: String?): Map<String, Any?> {
        requireInit()
        val session = requireSession(projectId)
        session.seek(positionMicros)

        audioEngines[projectId]?.seek(positionMicros)

        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.PLAYHEAD_CHANGED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload   = mapOf("playheadMicros" to session.playheadMicros)
            )
        )
        return mapOf("success" to true, "session" to session.toMap())
    }

    fun setPlaybackRate(
        projectId: String,
        rate: Float,
        commandId: String?
    ): Map<String, Any?> {
        requireInit()
        val session = requireSession(projectId)
        session.setPlaybackRate(rate)

        audioEngines[projectId]?.setRate(rate)

        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.AUDIO_ENGINE_STATE_CHANGED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload   = mapOf("playbackRate" to rate.toDouble())
            )
        )
        return mapOf("success" to true, "playbackRate" to rate.toDouble(), "session" to session.toMap())
    }

    fun getAudioEngineState(projectId: String): Map<String, Any?> {
        requireInit()
        val session = requireSession(projectId)
        val engine  = audioEngines[projectId]
        return mapOf(
            "success"       to true,
            "session"       to session.toMap(),
            "audioEngine"   to (engine?.toMap() ?: mapOf("available" to false))
        )
    }

    // ── Jobs ─────────────────────────────────────────────────────────────────

    fun startJob(
        projectId: String?,
        jobId: String,
        jobType: String,
        commandId: String?,
        payload: Map<String, Any?>
    ): Map<String, Any?> {
        requireInit()
        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.JOB_STARTED,
                projectId = projectId,
                commandId = commandId,
                jobId     = jobId,
                payload   = mapOf(
                    "jobType"  to jobType,
                    "stage"    to "Received by Android native engine",
                    "progress" to 0,
                    "payload"  to payload
                )
            )
        )
        // V1 placeholder — real decode/encode work added in Steps 16-18.
        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.JOB_PROGRESS,
                projectId = projectId,
                commandId = commandId,
                jobId     = jobId,
                payload   = mapOf("jobType" to jobType, "stage" to "Native placeholder complete", "progress" to 100)
            )
        )
        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.JOB_COMPLETED,
                projectId = projectId,
                commandId = commandId,
                jobId     = jobId,
                payload   = mapOf("jobType" to jobType, "result" to mapOf("placeholder" to true))
            )
        )
        return mapOf("success" to true, "jobId" to jobId, "placeholder" to true)
    }

    fun cancelJob(projectId: String?, jobId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.JOB_CANCELLED,
                projectId = projectId,
                commandId = commandId,
                jobId     = jobId,
                payload   = mapOf("jobId" to jobId)
            )
        )
        return mapOf("success" to true, "jobId" to jobId)
    }

    fun startProxyJob(
        projectId: String?,
        jobId: String,
        assetId: String,
        inputPath: String,
        outputPath: String,
        profileMap: Map<String, Any?>,
        commandId: String?
    ): Map<String, Any?> {
        requireInit()
        val profile = NleProxyProfile.fromPayload(profileMap)
        return proxyJobManager.startProxyJob(
            projectId = projectId,
            jobId = jobId,
            assetId = assetId,
            inputPath = inputPath,
            outputPath = outputPath,
            profile = profile
        )
    }

    fun cancelProxyJob(
        jobId: String,
        commandId: String?
    ): Map<String, Any?> {
        requireInit()
        return proxyJobManager.cancelProxyJob(jobId)
    }

    fun startExportJob(
        projectId: String?,
        jobId: String,
        renderGraphJson: String,
        outputPath: String,
        profileMap: Map<String, Any?>,
        commandId: String?
    ): Map<String, Any?> {
        requireInit()
        val profile = NleExportProfile.fromPayload(profileMap)
        val exportMode = when (profileMap["exportMode"] as? String) {
            "bitmap_v1" -> NleExportMode.BITMAP_PROTOTYPE
            else -> NleExportMode.TRUE_DECODER_V2
        }
        return exportJobManager.startExportJob(
            projectId       = projectId,
            jobId           = jobId,
            renderGraphJson = renderGraphJson,
            outputPath      = outputPath,
            profile         = profile,
            exportMode      = exportMode
        )
    }

    fun cancelExportJob(
        jobId: String,
        commandId: String?
    ): Map<String, Any?> {
        requireInit()
        return exportJobManager.cancelExportJob(jobId)
    }

    // ── Queries ──────────────────────────────────────────────────────────────

    fun getSessionState(projectId: String): Map<String, Any?> {
        requireInit()
        return mapOf("success" to true, "session" to requireSession(projectId).toMap())
    }

    fun probeDeviceCapabilities(): Map<String, Any?> {
        requireInit()
        val result = deviceProbe.probe()
        eventEmitter.emit(
            NleNativeEvent(type = NleNativeEventType.DEVICE_CAPABILITIES, payload = result)
        )
        return mapOf("success" to true, "deviceCapabilities" to result)
    }

    // ── Preview texture helpers ───────────────────────────────────────────────

    fun createPreviewTexture(
        projectId: String?,
        width: Int,
        height: Int,
        commandId: String? = null
    ): Map<String, Any?> {
        requireInit()
        return previewTextureManager.createPreviewTexture(
            projectId = projectId,
            width     = width,
            height    = height,
            commandId = commandId
        )
    }

    fun attachPreviewTexture(
        projectId: String,
        textureId: Long,
        commandId: String? = null
    ): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId]
        return previewTextureManager.attachPreviewTexture(
            projectId = projectId,
            sessionId = session?.sessionId,
            textureId = textureId,
            commandId = commandId
        )
    }

    fun resizePreviewTexture(
        textureId: Long,
        width: Int,
        height: Int,
        commandId: String? = null
    ): Map<String, Any?> {
        requireInit()
        return previewTextureManager.resizePreviewTexture(
            textureId = textureId,
            width     = width,
            height    = height,
            commandId = commandId
        )
    }

    fun renderPreviewPlaceholder(
        textureId: Long,
        label: String,
        playheadMicros: Long,
        commandId: String? = null
    ): Map<String, Any?> {
        requireInit()
        return previewTextureManager.renderPlaceholderFrame(
            textureId      = textureId,
            label          = label,
            playheadMicros = playheadMicros,
            commandId      = commandId
        )
    }

    fun disposePreviewTexture(
        textureId: Long,
        commandId: String? = null
    ): Map<String, Any?> {
        requireInit()
        return previewTextureManager.disposePreviewTexture(
            textureId = textureId,
            commandId = commandId
        )
    }

    fun renderGpuPreviewFrame(
        projectId: String,
        renderGraphJson: String,
        timelineTimeMicros: Long,
        commandId: String? = null
    ): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId]

        // Attempt GPU render onto all surfaces attached to this project
        val rendered = previewTextureManager.renderGpuFrameForProject(
            projectId          = projectId,
            renderGraphJson    = renderGraphJson,
            timelineTimeMicros = timelineTimeMicros,
            compositorSession  = compositorSession
        )

        if (rendered == 0) {
            // No GPU surface ready — fall back to Canvas placeholder
            previewTextureManager.renderPlaceholderForProject(
                projectId      = projectId,
                label          = "GPU Preview",
                playheadMicros = timelineTimeMicros
            )
        }

        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.GPU_PREVIEW_FRAME_RENDERED,
                projectId = projectId,
                sessionId = session?.sessionId,
                commandId = commandId,
                payload   = mapOf(
                    "timelineTimeMicros" to timelineTimeMicros,
                    "surfacesRendered"   to rendered
                )
            )
        )
        return mapOf(
            "success"          to true,
            "surfacesRendered" to rendered
        )
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private fun createAudioEngineForSession(session: NleEngineSession): NleAudioEngine {
        return NleAudioEngine(
            durationMicros  = session.durationMicros,
            onPlayheadTick  = { micros, playing ->
                session.updatePlayhead(micros, playing)
                eventEmitter.emit(
                    NleNativeEvent(
                        type      = NleNativeEventType.PLAYHEAD_CHANGED,
                        projectId = session.projectId,
                        sessionId = session.sessionId,
                        payload   = mapOf(
                            "playheadMicros" to micros,
                            "isPlaying"      to playing
                        )
                    )
                )
            },
            onPlaybackEnded = {
                session.pause()
                eventEmitter.emit(
                    NleNativeEvent(
                        type      = NleNativeEventType.PLAYBACK_ENDED,
                        projectId = session.projectId,
                        sessionId = session.sessionId,
                        payload   = mapOf("playheadMicros" to session.playheadMicros)
                    )
                )
            }
        ).also { engine ->
            val ok = engine.initialize()
            if (!ok) {
                eventEmitter.emitError(
                    projectId        = session.projectId,
                    sessionId        = session.sessionId,
                    commandId        = null,
                    code             = NleNativeErrorCode.AUDIO_ENGINE_INIT_FAILED,
                    message          = "The native audio engine could not start.",
                    technicalMessage = "AudioTrack.initialize() returned false for project ${session.projectId}"
                )
            }
        }
    }

    private fun requireInit() {
        if (!initialized) throw IllegalStateException(NleNativeErrorCode.ENGINE_NOT_INITIALIZED)
    }

    fun prepareTruePreview(
        monitorId: String = "program",
        projectId: String,
        renderGraphJson: String,
        qualityMode: String,
        preferProxy: Boolean,
        maxPreviewWidth: Int,
        maxPreviewHeight: Int
    ): Map<String, Any?> {
        requireInit()
        val qMode = when (qualityMode.lowercase()) {
            "performance" -> NlePreviewQualityMode.PERFORMANCE
            "balanced" -> NlePreviewQualityMode.BALANCED
            "quality" -> NlePreviewQualityMode.QUALITY
            else -> NlePreviewQualityMode.AUTO
        }
        previewManagerFor(monitorId).prepare(
            NlePreviewConfig(
                projectId = projectId,
                renderGraphJson = renderGraphJson,
                qualityMode = qMode,
                preferProxy = preferProxy,
                maxPreviewWidth = maxPreviewWidth,
                maxPreviewHeight = maxPreviewHeight
            )
        )
        return mapOf("success" to true)
    }

    fun renderPreviewFrame(
        monitorId: String = "program",
        timelineTimeUs: Long,
    ): Map<String, Any?> {
        requireInit()
        previewManagerFor(monitorId).renderFrame(timelineTimeUs)
        return mapOf("success" to true)
    }

    fun startTruePreview(
        monitorId: String = "program",
        fromTimelineTimeUs: Long,
    ): Map<String, Any?> {
        requireInit()
        previewManagerFor(monitorId).play(fromTimelineTimeUs)
        return mapOf("success" to true)
    }

    fun pauseTruePreview(monitorId: String = "program"): Map<String, Any?> {
        requireInit()
        previewManagerFor(monitorId).pause()
        return mapOf("success" to true)
    }

    fun stopTruePreview(monitorId: String = "program"): Map<String, Any?> {
        requireInit()
        previewManagerFor(monitorId).stop()
        return mapOf("success" to true)
    }

    fun disposeTruePreview(monitorId: String = "program"): Map<String, Any?> {
        requireInit()
        truePreviewManagers.remove(monitorId)?.release()
        return mapOf("success" to true)
    }

    fun setPreviewEventSink(sink: NlePreviewEventSink) {
        // Kept for binary/source compatibility with older dual-preview routing.
    }

    private fun previewManagerFor(monitorId: String): NlePreviewManager {
        return truePreviewManagers.getOrPut(monitorId) {
            NlePreviewManager(
                textureRegistry = textureRegistry,
                events = NlePreviewBridgeEventSink(monitorId) { type, payload ->
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = type,
                            payload = payload
                        )
                    )
                },
                scopeManager = scopeManager,
                monitorId = monitorId
            )
        }
    }

    // ── Scopes Command Delegation ────────────────────────────────────────────

    fun configureScopes(payload: Map<String, Any?>) {
        val settings = NleScopeSettings.fromPayload(payload)
        scopeManager.configure(settings)
    }

    fun requestScopeFrame(monitorId: String, timestampMicros: Long) {
        scopeManager.requestFrame(monitorId, timestampMicros)
    }

    fun startLiveScopes(monitorId: String) {
        scopeManager.startLive(monitorId)
    }

    fun stopLiveScopes() {
        scopeManager.stopLive()
    }

    private fun requireSession(projectId: String): NleEngineSession =
        sessions[projectId]
            ?: throw IllegalStateException(NleNativeErrorCode.SESSION_NOT_FOUND)

    private class SwitchablePreviewEventSink(
        @Volatile var delegate: NlePreviewEventSink,
    ) : NlePreviewEventSink {
        override fun onPreviewTextureReady(textureId: Long, width: Int, height: Int) {
            delegate.onPreviewTextureReady(textureId, width, height)
        }

        override fun onPreviewFrameRendered(timelineTimeUs: Long) {
            delegate.onPreviewFrameRendered(timelineTimeUs)
        }

        override fun onPreviewDroppedFrame(timelineTimeUs: Long, reason: String) {
            delegate.onPreviewDroppedFrame(timelineTimeUs, reason)
        }

        override fun onPreviewEnded() {
            delegate.onPreviewEnded()
        }

        override fun onPreviewError(message: String) {
            delegate.onPreviewError(message)
        }

        override fun onColorPipelineStats(passCount: Int, format: String, precision: String, usedFallback: Boolean, fallbackReason: String?) {
            delegate.onColorPipelineStats(passCount, format, precision, usedFallback, fallbackReason)
        }
    }
}
