package com.kata.videoeditor.nle

import android.content.Context
import android.graphics.Color
import com.nle.editor.NleEngineSession
import com.nle.editor.NleNativeEventEmitter
import com.nle.editor.audio.NleAudioEngine
import com.nle.editor.audio.NleAudioEngineState
import com.nle.editor.audio.NleWaveformExtractor
import com.nle.editor.preview.NleFlutterPreviewTextureManager
import com.nle.editor.preview.NlePreviewBridgeEventSink
import com.nle.editor.preview.NlePreviewConfig
import com.nle.editor.preview.NlePreviewEventSink
import com.nle.editor.preview.NlePreviewManager
import com.nle.editor.preview.NlePreviewQualityMode
import com.nle.editor.rendergraph.NleRenderGraphParser
import com.nle.editor.scopes.NleScopeManager
import com.nle.editor.scopes.NleScopeSettings
import io.flutter.view.TextureRegistry

class NleEngineManager(
    private val appContext: Context,
    private val textureRegistry: TextureRegistry,
    private val eventEmitter: NleNativeEventEmitter,
) {
    private var initialized = false
    private val sessions = mutableMapOf<String, NleEngineSession>()
    private val parser = NleRenderGraphParser()
    private val previewTextureManager = NleFlutterPreviewTextureManager(textureRegistry)
    private val compositorSession = com.nle.editor.preview.NleGpuPreviewCompositorSession()
    private val truePreviewManagers = mutableMapOf<String, NlePreviewManager>()
    private val scopeManager = NleScopeManager()

    fun initialize(): Map<String, Any?> {
        initialized = true
        return mapOf("initialized" to true)
    }

    fun dispose(): Map<String, Any?> {
        sessions.values.forEach { it.release() }
        sessions.clear()
        truePreviewManagers.values.forEach { it.release() }
        truePreviewManagers.clear()
        previewTextureManager.releaseAll()
        compositorSession.release()
        initialized = false
        return mapOf("disposed" to true)
    }

    fun loadRenderGraph(
        projectId: String,
        renderGraphJson: String,
        commandId: String?,
    ): Map<String, Any?> {
        requireInit()
        val graph = parser.parse(renderGraphJson)
        val session = sessions.getOrPut(projectId) {
            NleEngineSession(projectId = projectId)
        }
        session.loadGraph(graph)
        session.audioEngine = createAudioEngineForSession(session)
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.GRAPH_LOADED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload = mapOf(
                    "durationMicros" to session.durationMicros,
                    "trackCount" to graph.tracks.size,
                ),
            ),
        )
        return mapOf("sessionId" to session.sessionId, "durationMicros" to session.durationMicros)
    }

    fun updateRenderGraph(
        projectId: String,
        renderGraphJson: String,
        reason: String?,
        commandId: String?,
    ): Map<String, Any?> {
        requireInit()
        val graph = parser.parse(renderGraphJson)
        val session = sessions[projectId]
            ?: throw IllegalStateException(NleNativeErrorCode.SESSION_NOT_FOUND)
        session.loadGraph(graph)
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.GRAPH_UPDATED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload = mapOf("reason" to reason, "durationMicros" to session.durationMicros),
            ),
        )
        return mapOf("updated" to true, "durationMicros" to session.durationMicros)
    }

    fun validateRenderGraph(renderGraphJson: String): Map<String, Any?> {
        requireInit()
        val graph = parser.parse(renderGraphJson)
        return mapOf(
            "valid" to true,
            "durationMicros" to graph.project.durationUs,
            "trackCount" to graph.tracks.size,
        )
    }

    fun play(projectId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId]
            ?: throw IllegalStateException(NleNativeErrorCode.SESSION_NOT_FOUND)
        session.play()
        session.audioEngine?.play(fromMicros = session.playheadMicros)
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PLAYBACK_STARTED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload = mapOf("playheadMicros" to session.playheadMicros),
            ),
        )
        return mapOf("playing" to true)
    }

    fun pause(projectId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId]
            ?: throw IllegalStateException(NleNativeErrorCode.SESSION_NOT_FOUND)
        session.pause()
        session.audioEngine?.pause()
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PLAYBACK_PAUSED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload = mapOf("playheadMicros" to session.playheadMicros),
            ),
        )
        return mapOf("playing" to false)
    }

    fun seek(projectId: String, positionMicros: Long, commandId: String?): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId]
            ?: throw IllegalStateException(NleNativeErrorCode.SESSION_NOT_FOUND)
        val pos = session.seek(positionMicros)
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.SEEK_COMPLETED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload = mapOf("playheadMicros" to pos),
            ),
        )
        return mapOf("playheadMicros" to pos)
    }

    fun startJob(projectId: String?, jobId: String, jobType: String, commandId: String?, payload: Map<String, Any?>): Map<String, Any?> {
        requireInit()
        return mapOf("jobId" to jobId, "jobType" to jobType, "accepted" to true)
    }

    fun cancelJob(projectId: String?, jobId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        return mapOf("jobId" to jobId, "cancelled" to true)
    }

    fun startProxyJob(projectId: String?, jobId: String, assetId: String, inputPath: String, outputPath: String, profileMap: Map<String, Any?>, commandId: String?): Map<String, Any?> {
        requireInit()
        return mapOf("jobId" to jobId, "accepted" to true)
    }

    fun cancelProxyJob(jobId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        return mapOf("jobId" to jobId, "cancelled" to true)
    }

    fun startExportJob(projectId: String?, jobId: String, renderGraphJson: String, outputPath: String, profileMap: Map<String, Any?>, commandId: String?): Map<String, Any?> {
        requireInit()
        return mapOf("jobId" to jobId, "accepted" to true)
    }

    fun cancelExportJob(jobId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        return mapOf("jobId" to jobId, "cancelled" to true)
    }

    fun probeDeviceCapabilities(): Map<String, Any?> {
        requireInit()
        return mapOf("available" to true)
    }

    fun getSessionState(projectId: String): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId]
            ?: return mapOf("loaded" to false)
        return mapOf(
            "loaded" to true,
            "sessionId" to session.sessionId,
            "playheadMicros" to session.playheadMicros,
            "durationMicros" to session.durationMicros,
            "isPlaying" to session.isPlaying,
        )
    }

    fun setPlaybackRate(projectId: String, rate: Float, commandId: String?): Map<String, Any?> {
        requireInit()
        return mapOf("rate" to rate)
    }

    fun getAudioEngineState(projectId: String): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId] ?: return NleAudioEngineState().toMap()
        return (session.audioEngine?.state() ?: NleAudioEngineState()).toMap()
    }

    fun createPreviewTexture(projectId: String?, width: Int, height: Int, commandId: String?): Map<String, Any?> {
        requireInit()
        val texture = previewTextureManager.create(projectId, width, height)
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PREVIEW_TEXTURE_CREATED,
                projectId = projectId,
                commandId = commandId,
                payload = mapOf(
                    "textureId" to texture.id,
                    "width" to width,
                    "height" to height,
                ),
            ),
        )
        return mapOf("textureId" to texture.id, "width" to width, "height" to height)
    }

    fun attachPreviewTexture(projectId: String, textureId: Long, commandId: String?): Map<String, Any?> {
        requireInit()
        previewTextureManager.attach(projectId, textureId)
        return mapOf("attached" to true)
    }

    fun resizePreviewTexture(textureId: Long, width: Int, height: Int, commandId: String?): Map<String, Any?> {
        requireInit()
        previewTextureManager.resize(textureId, width, height)
        return mapOf("resized" to true)
    }

    fun renderPreviewPlaceholder(textureId: Long, label: String, playheadMicros: Long, commandId: String?): Map<String, Any?> {
        requireInit()
        previewTextureManager.renderPlaceholder(textureId, label, playheadMicros)
        return mapOf("rendered" to true)
    }

    fun disposePreviewTexture(textureId: Long, commandId: String?): Map<String, Any?> {
        requireInit()
        previewTextureManager.dispose(textureId)
        return mapOf("disposed" to true)
    }

    fun renderGpuPreviewFrame(projectId: String, renderGraphJson: String, timelineTimeMicros: Long, commandId: String?): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId]
        val rendered = previewTextureManager.renderGpuFrameForProject(
            projectId = projectId,
            renderGraphJson = renderGraphJson,
            timelineTimeMicros = timelineTimeMicros,
            compositorSession = compositorSession,
        )
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.GPU_PREVIEW_FRAME_RENDERED,
                projectId = projectId,
                sessionId = session?.sessionId,
                commandId = commandId,
                payload = mapOf(
                    "timelineTimeMicros" to timelineTimeMicros,
                    "surfacesRendered" to rendered,
                ),
            ),
        )
        return mapOf("success" to (rendered > 0), "surfacesRendered" to rendered)
    }

    private fun createAudioEngineForSession(session: NleEngineSession): NleAudioEngine {
        return NleAudioEngine(
            durationMicros = session.durationMicros,
            onPlayheadTick = { micros, playing ->
                session.updatePlayhead(micros, playing)
                eventEmitter.emit(
                    NleNativeEvent(
                        type = NleNativeEventType.PLAYHEAD_CHANGED,
                        projectId = session.projectId,
                        sessionId = session.sessionId,
                        payload = mapOf("playheadMicros" to micros, "isPlaying" to playing),
                    ),
                )
            },
            onPlaybackEnded = {
                session.pause()
                eventEmitter.emit(
                    NleNativeEvent(
                        type = NleNativeEventType.PLAYBACK_ENDED,
                        projectId = session.projectId,
                        sessionId = session.sessionId,
                        payload = mapOf("playheadMicros" to session.playheadMicros),
                    ),
                )
            },
        ).also { engine ->
            val ok = engine.initialize()
            if (!ok) {
                eventEmitter.emitError(
                    projectId = session.projectId,
                    sessionId = session.sessionId,
                    commandId = null,
                    code = NleNativeErrorCode.AUDIO_ENGINE_INIT_FAILED,
                    message = "The native audio engine could not start.",
                    technicalMessage = "AudioTrack.initialize() returned false for project ${session.projectId}",
                )
            }
        }
    }

    private fun requireInit() {
        if (!initialized) throw IllegalStateException(NleNativeErrorCode.ENGINE_NOT_INITIALIZED)
    }

    fun prepareTruePreview(monitorId: String = "program", projectId: String, renderGraphJson: String, qualityMode: String, preferProxy: Boolean, maxPreviewWidth: Int, maxPreviewHeight: Int): Map<String, Any?> {
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
                maxPreviewHeight = maxPreviewHeight,
            ),
        )
        return mapOf("prepared" to true, "monitorId" to monitorId)
    }

    fun renderPreviewFrame(monitorId: String = "program", timelineTimeUs: Long): Map<String, Any?> {
        requireInit()
        val result = previewManagerFor(monitorId).renderFrame(timelineTimeUs)
        if (!result.rendered) {
            throw IllegalStateException(result.reason ?: "Native preview frame failed.")
        }
        return mapOf("rendered" to true, "timelineTimeUs" to result.timelineTimeUs, "monitorId" to monitorId)
    }

    fun startTruePreview(monitorId: String = "program", fromTimelineTimeUs: Long): Map<String, Any?> {
        requireInit()
        previewManagerFor(monitorId).play(fromTimelineTimeUs)
        return mapOf("playing" to true, "monitorId" to monitorId)
    }

    fun pauseTruePreview(monitorId: String = "program"): Map<String, Any?> {
        requireInit()
        previewManagerFor(monitorId).pause()
        return mapOf("paused" to true, "monitorId" to monitorId)
    }

    fun stopTruePreview(monitorId: String = "program"): Map<String, Any?> {
        requireInit()
        previewManagerFor(monitorId).stop()
        return mapOf("stopped" to true, "monitorId" to monitorId)
    }

    fun disposeTruePreview(monitorId: String = "program"): Map<String, Any?> {
        requireInit()
        truePreviewManagers.remove(monitorId)?.release()
        return mapOf("disposed" to true, "monitorId" to monitorId)
    }

    fun setPreviewEventSink(sink: NlePreviewEventSink) {}

    private fun previewManagerFor(monitorId: String): NlePreviewManager {
        return truePreviewManagers.getOrPut(monitorId) {
            NlePreviewManager(
                textureRegistry = textureRegistry,
                events = NlePreviewBridgeEventSink(monitorId) { type, payload ->
                    eventEmitter.emit(NleNativeEvent(type = type, payload = payload))
                },
                scopeManager = scopeManager,
                monitorId = monitorId,
            )
        }
    }

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
}
