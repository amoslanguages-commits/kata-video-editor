package com.kata.videoeditor.nle

import android.content.Context
import com.kata.videoeditor.nle.export.NleNativeExportRenderer
import com.nle.editor.preview.NleFlutterPreviewTextureManager
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
    private val nativeExportRenderer = NleNativeExportRenderer(eventEmitter)

    fun initialize(): Map<String, Any?> {
        initialized = true
        return mapOf("initialized" to true)
    }

    fun dispose(): Map<String, Any?> {
        sessions.clear()
        truePreviewManagers.values.forEach { it.release() }
        truePreviewManagers.clear()
        previewTextureManager.releaseAll()
        compositorSession.release()
        initialized = false
        return mapOf("disposed" to true)
    }

    fun loadRenderGraph(projectId: String, renderGraphJson: String, commandId: String?): Map<String, Any?> {
        requireInit()
        val graph = parser.parse(renderGraphJson)
        val session = sessions.getOrPut(projectId) {
            NleEngineSession(projectId = projectId, initialRenderGraphJson = renderGraphJson)
        }
        session.updateGraph(renderGraphJson)
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.GRAPH_LOADED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload = mapOf("durationMicros" to session.durationMicros, "trackCount" to graph.tracks.size),
            ),
        )
        return mapOf("sessionId" to session.sessionId, "durationMicros" to session.durationMicros)
    }

    fun updateRenderGraph(projectId: String, renderGraphJson: String, reason: String?, commandId: String?): Map<String, Any?> {
        requireInit()
        val graph = parser.parse(renderGraphJson)
        val session = sessions[projectId]
            ?: throw IllegalStateException(NleNativeErrorCode.SESSION_NOT_FOUND)
        session.updateGraph(renderGraphJson)
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.GRAPH_UPDATED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload = mapOf("reason" to reason, "durationMicros" to session.durationMicros, "trackCount" to graph.tracks.size),
            ),
        )
        return mapOf("updated" to true, "durationMicros" to session.durationMicros)
    }

    fun validateRenderGraph(renderGraphJson: String): Map<String, Any?> {
        requireInit()
        val graph = parser.parse(renderGraphJson)
        return mapOf("valid" to true, "durationMicros" to graph.project.durationUs, "trackCount" to graph.tracks.size)
    }

    fun play(projectId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId]
            ?: throw IllegalStateException(NleNativeErrorCode.SESSION_NOT_FOUND)
        session.play()
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
        session.seek(positionMicros)
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.SEEK_COMPLETED,
                projectId = projectId,
                sessionId = session.sessionId,
                commandId = commandId,
                payload = mapOf("playheadMicros" to session.playheadMicros),
            ),
        )
        return mapOf("playheadMicros" to session.playheadMicros)
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
        return nativeExportRenderer.start(
            projectId = projectId,
            jobId = jobId,
            renderGraphJson = renderGraphJson,
            outputPath = outputPath,
            profileMap = profileMap,
        )
    }

    fun cancelExportJob(jobId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        return nativeExportRenderer.cancel(jobId)
    }

    fun probeDeviceCapabilities(): Map<String, Any?> {
        requireInit()
        return mapOf("available" to true)
    }

    fun getSessionState(projectId: String): Map<String, Any?> {
        requireInit()
        return sessions[projectId]?.toMap() ?: mapOf("loaded" to false)
    }

    fun setPlaybackRate(projectId: String, rate: Float, commandId: String?): Map<String, Any?> {
        requireInit()
        val session = sessions[projectId]
            ?: throw IllegalStateException(NleNativeErrorCode.SESSION_NOT_FOUND)
        session.setPlaybackRate(rate)
        return mapOf("rate" to session.playbackRate)
    }

    fun getAudioEngineState(projectId: String): Map<String, Any?> {
        requireInit()
        return mapOf("initialized" to false, "projectId" to projectId)
    }

    fun createPreviewTexture(projectId: String?, width: Int, height: Int, commandId: String?): Map<String, Any?> {
        requireInit()
        val texture = previewTextureManager.create(projectId, width, height)
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PREVIEW_TEXTURE_CREATED,
                projectId = projectId,
                commandId = commandId,
                payload = mapOf("textureId" to texture.id, "width" to width, "height" to height),
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
        throw IllegalStateException("Placeholder preview rendering is disabled in full-native mode.")
    }

    fun disposePreviewTexture(textureId: Long, commandId: String?): Map<String, Any?> {
        requireInit()
        previewTextureManager.dispose(textureId)
        return mapOf("disposed" to true)
    }

    fun renderGpuPreviewFrame(projectId: String, renderGraphJson: String, timelineTimeMicros: Long, commandId: String?): Map<String, Any?> {
        requireInit()
        val rendered = previewTextureManager.renderGpuFrameForProject(
            projectId = projectId,
            renderGraphJson = renderGraphJson,
            timelineTimeMicros = timelineTimeMicros,
            compositorSession = compositorSession,
        )
        if (rendered == 0) {
            throw IllegalStateException("No native GPU preview surface rendered a frame.")
        }
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.GPU_PREVIEW_FRAME_RENDERED,
                projectId = projectId,
                sessionId = sessions[projectId]?.sessionId,
                commandId = commandId,
                payload = mapOf("timelineTimeMicros" to timelineTimeMicros, "surfacesRendered" to rendered),
            ),
        )
        return mapOf("surfacesRendered" to rendered)
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
        val manager = previewManagerFor(monitorId)
        val graph = manager.currentGraph()
            ?: throw IllegalStateException("Native preview graph is not prepared.")
        if (graph.project.durationUs <= 0L) {
            throw IllegalStateException("Native preview graph has empty duration.")
        }
        manager.play(fromTimelineTimeUs)
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
