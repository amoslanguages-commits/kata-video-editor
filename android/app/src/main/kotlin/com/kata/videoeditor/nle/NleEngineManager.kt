package com.kata.videoeditor.nle

import android.content.Context
import com.kata.videoeditor.nle.export.NleNativeExportRenderer
import com.kata.videoeditor.nle.proxy.NleNativeProxyRenderer
import com.nle.editor.color.NleDeviceColorCapability
import com.nle.editor.color.NleDeviceColorCapabilityScanner
import com.nle.editor.deviceqa.NleDeviceCapabilityCollector
import com.nle.editor.deviceqa.NleDeviceCapabilityReport
import com.nle.editor.deviceqa.toPayload
import com.nle.editor.preview.NleFlutterPreviewTextureManager
import com.nle.editor.preview.NlePreviewConfig
import com.nle.editor.preview.NlePreviewEventSink
import com.nle.editor.preview.NlePreviewManager
import com.nle.editor.preview.NlePreviewQualityMode
import com.nle.editor.rendergraph.NleRenderGraphParser
import com.nle.editor.scopes.NleScopeManager
import com.nle.editor.scopes.NleScopeSettings
import io.flutter.view.TextureRegistry
import kotlin.math.max

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
    private val scopeManager = NleScopeManager(sendEvent = { type, payload -> eventEmitter.emit(NleNativeEvent(type = type, payload = payload)) })
    private val nativeExportRenderer = NleNativeExportRenderer(eventEmitter)
    private val nativeProxyRenderer = NleNativeProxyRenderer(eventEmitter)
    private val deviceCapabilityCollector by lazy { NleDeviceCapabilityCollector(appContext) }
    private val colorCapabilityScanner by lazy { NleDeviceColorCapabilityScanner(appContext) }

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
        truePreviewManagers.values.forEach { 
            if (it.projectId == projectId) {
                it.updateRenderGraph(renderGraphJson) 
            }
        }
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
        truePreviewManagers.values.forEach { 
            if (it.projectId == projectId) {
                it.updateRenderGraph(renderGraphJson) 
            }
        }
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
        return nativeProxyRenderer.start(
            projectId = projectId,
            jobId = jobId,
            assetId = assetId,
            inputPath = inputPath,
            outputPath = outputPath,
            profileMap = profileMap,
        )
    }

    fun cancelProxyJob(jobId: String, commandId: String?): Map<String, Any?> {
        requireInit()
        return nativeProxyRenderer.cancel(jobId)
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
        val report = deviceCapabilityCollector.collect()
        val colorCapability = colorCapabilityScanner.scan()
        val adaptiveExportProfile = buildAdaptiveExportProfile(report, colorCapability)
        val payload = mapOf(
            "available" to true,
            "profileSchema" to "nle.device_capability_profile",
            "profileVersion" to 1,
            "generatedAtMs" to report.generatedAtMs,
            "deviceCapability" to report.toPayload(),
            "colorCapability" to colorCapability.toPayload(),
            "adaptiveExportProfile" to adaptiveExportProfile,
        )
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.DEVICE_CAPABILITIES,
                payload = payload,
            ),
        )
        return payload
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

    fun configureScopes(payload: Map<String, Any?>): Map<String, Any?> {
        requireInit()
        scopeManager.configure(com.nle.editor.scopes.NleScopeSettings.fromPayload(payload))
        return mapOf("success" to true)
    }

    fun requestScopeFrame(monitorId: String, timestampMicros: Long): Map<String, Any?> {
        requireInit()
        scopeManager.requestFrame(monitorId, timestampMicros)
        return mapOf("success" to true)
    }

    fun startLiveScopes(monitorId: String): Map<String, Any?> {
        requireInit()
        scopeManager.startLive(monitorId)
        return mapOf("success" to true)
    }

    fun stopLiveScopes(): Map<String, Any?> {
        requireInit()
        scopeManager.stopLive()
        return mapOf("success" to true)
    }

    fun setPreviewEventSink(sink: com.nle.editor.preview.NlePreviewEventSink) {
    }

    fun prepareTruePreview(
        monitorId: String,
        projectId: String,
        renderGraphJson: String,
        qualityMode: String,
        preferProxy: Boolean,
        maxPreviewWidth: Int,
        maxPreviewHeight: Int,
    ): Map<String, Any?> {
        requireInit()
        val config = com.nle.editor.preview.NlePreviewConfig(
            projectId = projectId,
            renderGraphJson = renderGraphJson,
            qualityMode = com.nle.editor.preview.NlePreviewQualityMode.valueOf(qualityMode.uppercase()),
            preferProxy = preferProxy,
            maxPreviewWidth = maxPreviewWidth,
            maxPreviewHeight = maxPreviewHeight,
        )
        val manager = truePreviewManagers.getOrPut(monitorId) {
            com.nle.editor.preview.NlePreviewManager(
                textureRegistry = textureRegistry,
                events = com.kata.videoeditor.nle.NlePreviewBridgeEventSink(monitorId) { type, payload ->
                    eventEmitter.emit(com.kata.videoeditor.nle.NleNativeEvent(type = type, payload = payload))
                },
                scopeManager = scopeManager,
                monitorId = monitorId
            )
        }
        manager.prepare(config)
        return mapOf("prepared" to true)
    }

    fun renderPreviewFrame(monitorId: String, timelineTimeUs: Long): Map<String, Any?> {
        requireInit()
        val manager = truePreviewManagers[monitorId] ?: return mapOf("rendered" to false)
        val result = manager.renderFrame(timelineTimeUs)
        return mapOf("rendered" to result.rendered, "timelineTimeUs" to result.timelineTimeUs)
    }

    fun startTruePreview(monitorId: String, fromTimelineTimeUs: Long): Map<String, Any?> {
        requireInit()
        truePreviewManagers[monitorId]?.play(fromTimelineTimeUs)
        return mapOf("playing" to true)
    }

    fun pauseTruePreview(monitorId: String): Map<String, Any?> {
        requireInit()
        truePreviewManagers[monitorId]?.pause()
        return mapOf("playing" to false)
    }

    fun stopTruePreview(monitorId: String): Map<String, Any?> {
        requireInit()
        truePreviewManagers[monitorId]?.stop()
        return mapOf("stopped" to true)
    }

    fun disposeTruePreview(monitorId: String): Map<String, Any?> {
        requireInit()
        truePreviewManagers.remove(monitorId)?.release()
        return mapOf("disposed" to true)
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
        throw IllegalStateException("Native preview placeholder rendering is disabled.")
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
        return mapOf("rendered" to true, "surfacesRendered" to rendered)
    }

    private fun requireInit() {
        if (!initialized) throw IllegalStateException(NleNativeErrorCode.ENGINE_NOT_INITIALIZED)
    }

    private fun buildAdaptiveExportProfile(
        report: NleDeviceCapabilityReport,
        colorCapability: NleDeviceColorCapability,
    ): Map<String, Any?> {
        val recommendation = report.recommendation
        val codec = report.codecReport
        val thermal = report.thermalReport
        val maxLongEdge = max(recommendation.maxExportWidth, recommendation.maxExportHeight)
        val maxResolution = when {
            !codec.hasH264Encoder -> 0
            maxLongEdge >= 3840 && recommendation.allow4kExport -> 2160
            maxLongEdge >= 1920 && codec.supports1080pExport -> 1080
            else -> 720
        }
        val maxFrameRate = recommendation.maxFrameRate.toInt().coerceIn(24, 60)
        val maxVideoBitrate = when (maxResolution) {
            2160 -> if (maxFrameRate > 30) 60_000_000 else 40_000_000
            1080 -> if (maxFrameRate > 30) 20_000_000 else 16_000_000
            720 -> 5_000_000
            else -> 0
        }
        val audioBitrate = if (codec.hasAacEncoder) 192_000 else 0
        val exportBlocked = !codec.hasH264Encoder || !codec.hasAacEncoder || !report.eglReport.eglAvailable || thermal.shouldBlockLongExport
        val preferredPreviewScale = when (recommendation.previewQuality) {
            "quality" -> 1.0
            "balanced" -> 0.75
            "performance" -> 0.5
            else -> 0.75
        }
        val proxyPolicy = when {
            report.deviceTier.name == "LOW_END" -> "required"
            recommendation.requireProxyFor4k -> "required_for_4k"
            else -> "optional"
        }

        return mapOf(
            "maxResolution" to maxResolution,
            "maxFrameRate" to maxFrameRate,
            "maxVideoBitrate" to maxVideoBitrate,
            "audioBitrate" to audioBitrate,
            "preferProxyPreview" to recommendation.preferProxyPreview,
            "proxyPolicy" to proxyPolicy,
            "requireProxyFor4k" to recommendation.requireProxyFor4k,
            "allow4kExport" to recommendation.allow4kExport,
            "exportBlocked" to exportBlocked,
            "blockReason" to buildList {
                if (!codec.hasH264Encoder) add("missing_h264_encoder")
                if (!codec.hasAacEncoder) add("missing_aac_encoder")
                if (!report.eglReport.eglAvailable) add("egl_unavailable")
                if (thermal.shouldBlockLongExport) add("thermal_block")
            },
            "previewQuality" to recommendation.previewQuality,
            "preferredPreviewScale" to preferredPreviewScale,
            "colorPipelineQuality" to colorCapability.recommendedQuality.name.lowercase(),
            "supportsHdrExport" to colorCapability.supportsHdrExport,
            "supportsWideColorPreview" to colorCapability.supportsWideColorPreview,
            "notes" to recommendation.notes,
        )
    }

    private fun NleDeviceColorCapability.toPayload(): Map<String, Any?> = mapOf(
        "supportsGles3" to supportsGles3,
        "supportsHalfFloatRenderTarget" to supportsHalfFloatRenderTarget,
        "supportsFloatRenderTarget" to supportsFloatRenderTarget,
        "supportsWideColorPreview" to supportsWideColorPreview,
        "supportsHdrPreview" to supportsHdrPreview,
        "supportsHdrExport" to supportsHdrExport,
        "maxTextureSize" to maxTextureSize,
        "renderer" to renderer,
        "vendor" to vendor,
        "recommendedQuality" to recommendedQuality.name.lowercase(),
    )
}
