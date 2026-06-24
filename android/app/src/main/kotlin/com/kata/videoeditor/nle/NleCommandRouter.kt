package com.kata.videoeditor.nle

import com.nle.editor.rendergraph.NleRenderGraphParser
import com.nle.editor.qa.NleRenderGraphQaValidator
import com.nle.editor.qa.NleVisualCompositorProbe
import com.nle.editor.qa.NleAudioMixerProbe
import com.nle.editor.sync.NleAndroidSyncQaRunner
import com.nle.editor.deviceqa.NleDeviceCompatibilityQaRunner
import com.nle.editor.deviceqa.NleDeviceCapabilityCollector
import com.nle.editor.deviceqa.NleMemoryPressureProbe
import com.nle.editor.deviceqa.NleExportRecoveryPolicy
import com.nle.editor.deviceqa.toPayload
import android.content.Context
import com.nle.editor.hdr.NleHdrOutputScanner
import com.nle.editor.hdr.NleHdrOutputParser
import com.nle.editor.hdr.NleHdrOutputSettings
import com.nle.editor.hdr.NleOutputColorMode
import com.nle.editor.hdr.NleHdrTransferFunction
import com.nle.editor.hdr.NleOutputBitDepth
import com.nle.editor.qa.NleColorPassOrderValidator
import com.nle.editor.qa.NleShaderCompileSmokeTester
import com.nle.editor.qa.NleGpuMemoryLeakProbe
import com.nle.editor.qa.NleHdrFallbackQaValidator
import com.nle.editor.qa.NleColorQaReportEmitter

/**
 * Routes every MethodChannel call to the appropriate [NleEngineManager] method.
 *
 * All errors are caught here, converted to a stable error-code, emitted as
 * an [NleNativeEventType.ENGINE_ERROR] event **and** returned as a failure map
 * so the Dart side can react synchronously too.
 */
class NleCommandRouter(
    private val engineManager: NleEngineManager,
    private val eventEmitter: NleNativeEventEmitter,
    private val context: Context,
) {
    private val renderGraphParser = NleRenderGraphParser()
    private val qaValidator = NleRenderGraphQaValidator()
    private val visualProbe = NleVisualCompositorProbe()
    private val audioProbe = NleAudioMixerProbe()
    val syncQaRunner = NleAndroidSyncQaRunner()

    // 29E: device compatibility QA
    private val deviceQaRunner            by lazy { NleDeviceCompatibilityQaRunner(context) }
    private val deviceCapabilityCollector by lazy { NleDeviceCapabilityCollector(context) }
    private val memoryPressureProbe       by lazy { NleMemoryPressureProbe(context) }
    private val exportRecoveryPolicy      = NleExportRecoveryPolicy()

    // 29F: dual preview manager (source + program monitors)
    private val dualPreviewManager by lazy {
        NleDualPreviewManager(
            engineManager = engineManager,
            sendEvent     = { type, payload ->
                eventEmitter.emit(
                    NleNativeEvent(
                        type = type,
                        payload = payload,
                    )
                )
            },
        )
    }

    fun route(method: String, args: Map<String, Any?>): Map<String, Any?> {
        return try {
            val commandId = args["commandId"] as? String

            val result: Any? = when (method) {

                NleNativeCommandType.INITIALIZE ->
                    engineManager.initialize()

                NleNativeCommandType.DISPOSE ->
                    engineManager.dispose()

                NleNativeCommandType.LOAD_RENDER_GRAPH ->
                    engineManager.loadRenderGraph(
                        projectId       = args.requireString("projectId"),
                        renderGraphJson = args.requireString("renderGraphJson"),
                        commandId       = commandId
                    )

                NleNativeCommandType.UPDATE_RENDER_GRAPH ->
                    engineManager.updateRenderGraph(
                        projectId       = args.requireString("projectId"),
                        renderGraphJson = args.requireString("renderGraphJson"),
                        reason          = args["reason"] as? String,
                        commandId       = commandId
                    )

                NleNativeCommandType.VALIDATE_RENDER_GRAPH ->
                    engineManager.validateRenderGraph(
                        args.requireString("renderGraphJson")
                    )

                NleNativeCommandType.PLAY ->
                    engineManager.play(
                        projectId = args.requireString("projectId"),
                        commandId = commandId
                    )

                NleNativeCommandType.PAUSE ->
                    engineManager.pause(
                        projectId = args.requireString("projectId"),
                        commandId = commandId
                    )

                NleNativeCommandType.SEEK -> {
                    val pos = args.requireLong("timelineMicros")
                        ?: args.requireLong("positionMicros")
                        ?: throw IllegalArgumentException(
                            "${NleNativeErrorCode.INVALID_ARGUMENTS}: missing 'timelineMicros'"
                        )
                    engineManager.seek(
                        projectId      = args.requireString("projectId"),
                        positionMicros = pos,
                        commandId      = commandId
                    )
                }

                NleNativeCommandType.START_JOB ->
                    engineManager.startJob(
                        projectId = args["projectId"] as? String,
                        jobId     = args.requireString("jobId"),
                        jobType   = args.requireString("jobType"),
                        commandId = commandId,
                        payload   = args.asStringDynamicMap("payload")
                    )

                NleNativeCommandType.CANCEL_JOB ->
                    engineManager.cancelJob(
                        projectId = args["projectId"] as? String,
                        jobId     = args.requireString("jobId"),
                        commandId = commandId
                    )

                NleNativeCommandType.START_PROXY_JOB ->
                    engineManager.startProxyJob(
                        projectId  = args["projectId"] as? String,
                        jobId      = args.requireString("jobId"),
                        assetId    = args.requireString("assetId"),
                        inputPath  = args.requireString("inputPath"),
                        outputPath = args.requireString("outputPath"),
                        profileMap = args.asStringDynamicMap("profile"),
                        commandId  = commandId
                    )

                NleNativeCommandType.CANCEL_PROXY_JOB ->
                    engineManager.cancelProxyJob(
                        jobId      = args.requireString("jobId"),
                        commandId  = commandId
                    )

                NleNativeCommandType.START_EXPORT_JOB ->
                    engineManager.startExportJob(
                        projectId       = args["projectId"] as? String,
                        jobId           = args.requireString("jobId"),
                        renderGraphJson = args.requireString("renderGraphJson"),
                        outputPath      = args.requireString("outputPath"),
                        profileMap      = args.asStringDynamicMap("profile"),
                        commandId       = commandId
                    )

                NleNativeCommandType.CANCEL_EXPORT_JOB ->
                    engineManager.cancelExportJob(
                        jobId      = args.requireString("jobId"),
                        commandId  = commandId
                    )

                "pause_export_job" -> {
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = "export_paused",
                            jobId = args["jobId"] as? String,
                            commandId = commandId,
                            payload = mapOf("stage" to "Paused")
                        )
                    )
                    mapOf("accepted" to true)
                }

                "resume_export_job" -> {
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = "export_resumed",
                            jobId = args["jobId"] as? String,
                            commandId = commandId,
                            payload = mapOf("stage" to "Resuming")
                        )
                    )
                    mapOf("accepted" to true)
                }

                "open_export_file" ->
                    mapOf("accepted" to true, "outputPath" to (args["outputPath"] as? String))

                "open_export_folder" ->
                    mapOf("accepted" to true, "outputPath" to (args["outputPath"] as? String))

                "check_export_permissions" -> {
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = "export_permission_status",
                            commandId = commandId,
                            payload = mapOf("granted" to true)
                        )
                    )
                    mapOf("accepted" to true, "granted" to true)
                }

                "schedule_export_notification" -> {
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = "export_notification_scheduled",
                            jobId = args["jobId"] as? String,
                            commandId = commandId,
                            payload = mapOf(
                                "title" to (args["title"] as? String ?: "Export"),
                                "body" to (args["body"] as? String ?: "Export is running")
                            )
                        )
                    )
                    mapOf("accepted" to true)
                }

                "recover_export_jobs" -> {
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = "export_recovery",
                            projectId = args["projectId"] as? String,
                            commandId = commandId,
                            payload = mapOf("recoveredJobs" to emptyList<Map<String, Any?>>())
                        )
                    )
                    mapOf("accepted" to true, "recoveredJobs" to emptyList<Map<String, Any?>>())
                }

                "validate_export_graph" -> {
                    val renderGraphJson = args.requireString("renderGraphJson")
                    val graph = renderGraphParser.parse(renderGraphJson)
                    val report = qaValidator.validate(graph)
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = "export_validation",
                            projectId = args["projectId"] as? String,
                            commandId = commandId,
                            payload = mapOf("passed" to report.passed)
                        )
                    )
                    mapOf("passed" to report.passed, "issues" to report.issues.map {
                        mapOf(
                            "id" to it.id,
                            "severity" to it.severity,
                            "message" to it.message,
                        )
                    })
                }

                NleNativeCommandType.GET_SESSION_STATE ->
                    engineManager.getSessionState(args.requireString("projectId"))

                NleNativeCommandType.PROBE_DEVICE_CAPABILITIES ->
                    engineManager.probeDeviceCapabilities()

                NleNativeCommandType.CREATE_PREVIEW_TEXTURE -> {
                    val projectId = args["projectId"] as? String
                    val width = args.requireLong("width")?.toInt() ?: throw IllegalArgumentException("missing width")
                    val height = args.requireLong("height")?.toInt() ?: throw IllegalArgumentException("missing height")
                    engineManager.createPreviewTexture(
                        projectId = projectId,
                        width     = width,
                        height    = height,
                        commandId = commandId
                    )
                }

                NleNativeCommandType.ATTACH_PREVIEW_TEXTURE -> {
                    val projectId = args.requireString("projectId")
                    val textureId = args.requireLong("textureId") ?: throw IllegalArgumentException("missing textureId")
                    engineManager.attachPreviewTexture(
                        projectId = projectId,
                        textureId = textureId,
                        commandId = commandId
                    )
                }

                NleNativeCommandType.RESIZE_PREVIEW_TEXTURE -> {
                    val textureId = args.requireLong("textureId") ?: throw IllegalArgumentException("missing textureId")
                    val width = args.requireLong("width")?.toInt() ?: throw IllegalArgumentException("missing width")
                    val height = args.requireLong("height")?.toInt() ?: throw IllegalArgumentException("missing height")
                    engineManager.resizePreviewTexture(
                        textureId = textureId,
                        width     = width,
                        height    = height,
                        commandId = commandId
                    )
                }

                NleNativeCommandType.RENDER_PREVIEW_PLACEHOLDER -> {
                    val textureId = args.requireLong("textureId") ?: throw IllegalArgumentException("missing textureId")
                    val label = args["label"] as? String ?: "Native Preview"
                    val playheadMicros = args.requireLong("playheadMicros") ?: 0L
                    engineManager.renderPreviewPlaceholder(
                        textureId      = textureId,
                        label          = label,
                        playheadMicros = playheadMicros,
                        commandId      = commandId
                    )
                }

                NleNativeCommandType.DISPOSE_PREVIEW_TEXTURE -> {
                    val textureId = args.requireLong("textureId") ?: throw IllegalArgumentException("missing textureId")
                    engineManager.disposePreviewTexture(
                        textureId = textureId,
                        commandId = commandId
                    )
                }

                NleNativeCommandType.SET_PLAYBACK_RATE -> {
                    val projectId = args.requireString("projectId")
                    val rate = when (val v = args["rate"]) {
                        is Double -> v.toFloat()
                        is Float  -> v
                        is Int    -> v.toFloat()
                        else      -> throw IllegalArgumentException(
                            "${NleNativeErrorCode.INVALID_ARGUMENTS}: missing 'rate'"
                        )
                    }
                    engineManager.setPlaybackRate(
                        projectId = projectId,
                        rate      = rate,
                        commandId = commandId
                    )
                }

                NleNativeCommandType.GET_AUDIO_ENGINE_STATE -> {
                    val projectId = args.requireString("projectId")
                    engineManager.getAudioEngineState(projectId)
                }

                NleNativeCommandType.RENDER_GPU_PREVIEW_FRAME -> {
                    val projectId          = args.requireString("projectId")
                    val renderGraphJson    = args.requireString("renderGraphJson")
                    val timelineTimeMicros = args.requireLong("timelineTimeMicros") ?: 0L
                    engineManager.renderGpuPreviewFrame(
                        projectId          = projectId,
                        renderGraphJson    = renderGraphJson,
                        timelineTimeMicros = timelineTimeMicros,
                        commandId          = commandId
                    )
                }

                NleNativeCommandType.HDR_SCAN_CAPABILITY -> {
                    val scanner = NleHdrOutputScanner(context)
                    val capability = scanner.scanCapability()
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = NleNativeEventType.HDR_DEVICE_CAPABILITY,
                            commandId = commandId,
                            payload = capability.toMap()
                        )
                    )
                    mapOf("success" to true)
                }

                NleNativeCommandType.HDR_VALIDATE_EXPORT -> {
                    val projectId = args.requireString("projectId")
                    val settings = NleHdrOutputParser.parseSettings(args)
                    val scanner = NleHdrOutputScanner(context)
                    val validation = scanner.validateExport(settings)
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = NleNativeEventType.HDR_EXPORT_VALIDATION,
                            projectId = projectId,
                            commandId = commandId,
                            payload = validation.toMap()
                        )
                    )
                    mapOf("success" to true)
                }

                NleNativeCommandType.HDR_CONFIGURE_PREVIEW -> {
                    val projectId = args.requireString("projectId")
                    val settings = NleHdrOutputParser.parseSettings(args)
                    android.util.Log.d("NleCommandRouter", "Configured HDR Preview for $projectId: $settings")
                    mapOf("success" to true)
                }

                NleNativeCommandType.QA_RUN_COLOR_CHECKS -> {
                    val renderGraphJson = args.requireString("renderGraphJson")
                    val graph = renderGraphParser.parse(renderGraphJson)
                    
                    val issues = mutableListOf<com.nle.editor.qa.NleColorQaIssue>()
                    
                    val passOrderValidator = NleColorPassOrderValidator()
                    val passIds = mutableListOf("input_to_scene_linear")
                    for (track in graph.tracks) {
                        for (clip in track.clips) {
                            if (clip.isDisabled) continue
                            if (clip.primaryGrade.enabled) passIds.add("primary_grade")
                            if (clip.colorCurveStack != null && !clip.colorCurveStack.isIdentity) passIds.add("color_curves")
                            if (clip.secondaryGrades != null && clip.secondaryGrades.enabled) {
                                for (l in clip.secondaryGrades.layers) {
                                    if (l.enabled && !l.isIdentity()) passIds.add("secondary_grade_${l.id}")
                                }
                            }
                            if (clip.lutStack != null && clip.lutStack.hasEnabledLuts) {
                                for (l in clip.lutStack.layers) {
                                    if (l.enabled) passIds.add("gpu_lut_${l.id}")
                                }
                            }
                        }
                    }
                    passIds.add("output_display_transform")
                    issues.addAll(passOrderValidator.validate(passIds))

                    val settings = try {
                        NleHdrOutputParser.parseSettings(args)
                    } catch (e: Exception) {
                        NleHdrOutputSettings(
                            colorMode = NleOutputColorMode.rec709Sdr,
                            bitDepth = NleOutputBitDepth.eightBit,
                            transferFunction = NleHdrTransferFunction.sdr
                        )
                    }
                    val fallbackValidator = NleHdrFallbackQaValidator(context)
                    issues.addAll(fallbackValidator.validateFallback(settings))

                    val report = NleColorQaReportEmitter().emit(issues)
                    report.toMap()
                }

                NleNativeCommandType.QA_RUN_SHADER_COMPILE_TEST -> {
                    val name = args.requireString("name")
                    val vertexSource = args.requireString("vertexSource")
                    val fragmentSource = args.requireString("fragmentSource")
                    
                    val tester = NleShaderCompileSmokeTester()
                    val issues = tester.testShader(name, vertexSource, fragmentSource)
                    val report = NleColorQaReportEmitter().emit(issues)
                    report.toMap()
                }

                NleNativeCommandType.QA_RUN_MEMORY_LEAK_PROBE -> {
                    val probe = NleGpuMemoryLeakProbe()
                    val issues = probe.probe()
                    val report = NleColorQaReportEmitter().emit(issues)
                    report.toMap()
                }

                "qa_validate_render_graph" -> {
                    val renderGraphJson = args.requireString("renderGraphJson")
                    val graph = renderGraphParser.parse(renderGraphJson)
                    val report = qaValidator.validate(graph)
                    mapOf(
                        "passed" to report.passed,
                        "issues" to report.issues.map {
                            mapOf(
                                "id" to it.id,
                                "severity" to it.severity,
                                "message" to it.message,
                            )
                        }
                    )
                }

                "qa_probe_visual" -> {
                    val renderGraphJson = args.requireString("renderGraphJson")
                    val timelineTimeUs = args.requireLong("timelineTimeUs")
                        ?: args.requireLong("timelineTimeMicros")
                        ?: throw IllegalArgumentException("missing timelineTimeUs")
                    val graph = renderGraphParser.parse(renderGraphJson)
                    val result = visualProbe.probe(graph, timelineTimeUs)
                    mapOf(
                        "timelineTimeUs" to result.timelineTimeUs,
                        "layers" to result.layers.map {
                            mapOf(
                                "trackId" to it.trackId,
                                "trackName" to it.trackName,
                                "clipId" to it.clipId,
                                "clipName" to it.clipName,
                                "type" to it.type,
                                "layerIndex" to it.layerIndex,
                                "sourceTimeUs" to it.sourceTimeUs,
                            )
                        }
                    )
                }

                "qa_probe_audio" -> {
                    val renderGraphJson = args.requireString("renderGraphJson")
                    val windowStartUs = args.requireLong("windowStartUs")
                        ?: args.requireLong("windowStartMicros")
                        ?: throw IllegalArgumentException("missing windowStartUs")
                    val windowEndUs = args.requireLong("windowEndUs")
                        ?: args.requireLong("windowEndMicros")
                        ?: throw IllegalArgumentException("missing windowEndUs")
                    val graph = renderGraphParser.parse(renderGraphJson)
                    val result = audioProbe.probe(graph, windowStartUs, windowEndUs)
                    mapOf(
                        "windowStartUs" to result.windowStartUs,
                        "windowEndUs" to result.windowEndUs,
                        "activeAudioTrackIds" to result.activeAudioTrackIds,
                        "mutedAudioTrackIds" to result.mutedAudioTrackIds,
                        "hasSoloAudio" to result.hasSoloAudio,
                        "layers" to result.layers.map {
                            mapOf(
                                "trackId" to it.trackId,
                                "trackName" to it.trackName,
                                "clipId" to it.clipId,
                                "clipName" to it.clipName,
                                "assetId" to it.assetId,
                                "volume" to it.volume,
                                "fadeInUs" to it.fadeInUs,
                                "fadeOutUs" to it.fadeOutUs,
                            )
                        }
                    )
                }

                "prepare_true_preview" -> {
                    val monitorId       = args["monitorId"] as? String ?: NleDualPreviewManager.PROGRAM
                    val projectId       = args.requireString("projectId")
                    val renderGraphJson = args.requireString("renderGraphJson")
                    val qualityMode     = args["qualityMode"] as? String ?: "auto"
                    val preferProxy     = args["preferProxy"] as? Boolean ?: true
                    val maxPreviewWidth = (args["maxPreviewWidth"] as? Number)?.toInt() ?: 1280
                    val maxPreviewHeight= (args["maxPreviewHeight"] as? Number)?.toInt() ?: 720
                    dualPreviewManager.prepare(
                        monitorId       = monitorId,
                        projectId       = projectId,
                        renderGraphJson = renderGraphJson,
                        qualityMode     = qualityMode,
                        preferProxy     = preferProxy,
                        maxPreviewWidth = maxPreviewWidth,
                        maxPreviewHeight= maxPreviewHeight,
                    )
                }

                "render_preview_frame" -> {
                    val monitorId      = args["monitorId"] as? String ?: NleDualPreviewManager.PROGRAM
                    val timelineTimeUs = args.requireLong("timelineTimeUs")
                        ?: args.requireLong("timelineTimeMicros")
                        ?: throw IllegalArgumentException("missing timelineTimeUs")
                    dualPreviewManager.renderFrame(monitorId, timelineTimeUs)
                }

                "start_true_preview" -> {
                    val monitorId          = args["monitorId"] as? String ?: NleDualPreviewManager.PROGRAM
                    val fromTimelineTimeUs = args.requireLong("fromTimelineTimeUs")
                        ?: args.requireLong("fromTimelineTimeMicros")
                        ?: 0L
                    dualPreviewManager.play(monitorId, fromTimelineTimeUs)
                }

                "pause_true_preview" -> {
                    val monitorId = args["monitorId"] as? String ?: NleDualPreviewManager.PROGRAM
                    dualPreviewManager.pause(monitorId)
                }

                "stop_true_preview" -> {
                    val monitorId = args["monitorId"] as? String ?: NleDualPreviewManager.PROGRAM
                    dualPreviewManager.stop(monitorId)
                }

                "dispose_true_preview" -> {
                    val monitorId = args["monitorId"] as? String ?: NleDualPreviewManager.PROGRAM
                    dualPreviewManager.dispose(monitorId)
                }

                "dispose_all_previews" ->
                    dualPreviewManager.disposeAll()

                "qa_run_export_sync" -> {
                    val report = syncQaRunner.runExportQa()
                    report.toPayload()
                }

                "qa_run_preview_sync" -> {
                    val report = syncQaRunner.runPreviewQa()
                    report.toPayload()
                }

                "qa_clear_sync_telemetry" -> {
                    syncQaRunner.clearAll()
                    mapOf("cleared" to true)
                }

                "qa_run_device_compatibility" -> {
                    val report = deviceQaRunner.run()
                    report.toPayload()
                }

                "qa_collect_device_capabilities" -> {
                    val report = deviceCapabilityCollector.collect()
                    report.toPayload()
                }

                "qa_run_memory_pressure_probe" -> {
                    val allocateMb = (args["allocateMb"] as? Number)?.toInt() ?: 128
                    val result = memoryPressureProbe.runLightProbe(allocateMb)
                    result.toPayload()
                }

                "qa_export_recovery_suggestion" -> {
                    val failureMessage = args["failureMessage"] as? String ?: ""
                    val capabilities   = deviceCapabilityCollector.collect()
                    val suggestion     = exportRecoveryPolicy.suggest(capabilities, failureMessage)
                    suggestion.toPayload()
                }

                NleNativeCommandType.SCOPES_CONFIGURE -> {
                    val payload = args.asStringDynamicMap("payload")
                    engineManager.configureScopes(payload)
                }

                NleNativeCommandType.SCOPES_REQUEST_FRAME -> {
                    val monitorId = args.requireString("monitorId")
                    val timestampMicros = args.requireLong("timestampMicros") ?: 0L
                    engineManager.requestScopeFrame(monitorId, timestampMicros)
                }

                NleNativeCommandType.SCOPES_START_LIVE -> {
                    val monitorId = args.requireString("monitorId")
                    engineManager.startLiveScopes(monitorId)
                }

                NleNativeCommandType.SCOPES_STOP_LIVE -> {
                    engineManager.stopLiveScopes()
                }

                else -> throw IllegalArgumentException(
                    "${NleNativeErrorCode.UNSUPPORTED_COMMAND}: $method"
                )
            }

            mapOf("success" to true, "method" to method, "result" to result)

        } catch (e: Throwable) {
            android.util.Log.e("NleCommandRouter", "Fatal error during native command: $method", e)
            val code = codeFromThrowable(e)
            eventEmitter.emitError(
                projectId        = args["projectId"] as? String,
                sessionId        = null,
                commandId        = args["commandId"] as? String,
                code             = code,
                message          = friendlyMessage(code),
                technicalMessage = e.message,
                payload          = mapOf("method" to method)
            )
            mapOf(
                "success" to false,
                "method"  to method,
                "error"   to mapOf(
                    "code"             to code,
                    "message"          to friendlyMessage(code),
                    "technicalMessage" to e.message
                )
            )
        }
    }

    private fun codeFromThrowable(e: Throwable): String {
        val msg = e.message ?: ""
        return when {
            msg.contains(NleNativeErrorCode.ENGINE_NOT_INITIALIZED)  -> NleNativeErrorCode.ENGINE_NOT_INITIALIZED
            msg.contains(NleNativeErrorCode.SESSION_NOT_FOUND)       -> NleNativeErrorCode.SESSION_NOT_FOUND
            msg.contains(NleNativeErrorCode.GRAPH_VALIDATION_FAILED) -> NleNativeErrorCode.GRAPH_VALIDATION_FAILED
            msg.contains(NleNativeErrorCode.UNSUPPORTED_COMMAND)     -> NleNativeErrorCode.UNSUPPORTED_COMMAND
            msg.contains(NleNativeErrorCode.PREVIEW_TEXTURE_NOT_FOUND) -> NleNativeErrorCode.PREVIEW_TEXTURE_NOT_FOUND
            msg.contains(NleNativeErrorCode.AUDIO_ENGINE_INIT_FAILED)  -> NleNativeErrorCode.AUDIO_ENGINE_INIT_FAILED
            msg.contains(NleNativeErrorCode.EXPORT_NO_CLIPS)            -> NleNativeErrorCode.EXPORT_NO_CLIPS
            msg.contains(NleNativeErrorCode.EXPORT_MISSING_ASSET)       -> NleNativeErrorCode.EXPORT_MISSING_ASSET
            msg.contains(NleNativeErrorCode.EXPORT_JOB_NOT_FOUND)       -> NleNativeErrorCode.EXPORT_JOB_NOT_FOUND
            msg.contains(NleNativeErrorCode.EXPORT_JOB_ALREADY_RUNNING) -> NleNativeErrorCode.EXPORT_JOB_ALREADY_RUNNING
            e is org.json.JSONException                               -> NleNativeErrorCode.GRAPH_PARSE_FAILED
            e is IllegalArgumentException                             -> NleNativeErrorCode.INVALID_ARGUMENTS
            else                                                      -> NleNativeErrorCode.COMMAND_FAILED
        }
    }

    private fun friendlyMessage(code: String): String = when (code) {
        NleNativeErrorCode.ENGINE_NOT_INITIALIZED  -> "The Android video engine is not ready yet."
        NleNativeErrorCode.SESSION_NOT_FOUND       -> "The project is not loaded in the Android video engine."
        NleNativeErrorCode.GRAPH_PARSE_FAILED      -> "The project instructions could not be read by the Android engine."
        NleNativeErrorCode.GRAPH_VALIDATION_FAILED -> "The project has invalid timeline instructions."
        NleNativeErrorCode.INVALID_ARGUMENTS       -> "The Android engine received an invalid command."
        NleNativeErrorCode.UNSUPPORTED_COMMAND     -> "This command is not supported by the Android engine yet."
        NleNativeErrorCode.PREVIEW_TEXTURE_NOT_FOUND -> "The native preview surface is no longer available."
        NleNativeErrorCode.AUDIO_ENGINE_INIT_FAILED  -> "The native audio engine failed to start."
        NleNativeErrorCode.AUDIO_TRACK_WRITE_FAILED  -> "The native audio engine encountered a write error."
        NleNativeErrorCode.EXPORT_NO_CLIPS            -> "The project has no renderable video clips."
        NleNativeErrorCode.EXPORT_MISSING_ASSET       -> "A media file required for export could not be found."
        NleNativeErrorCode.EXPORT_ENCODER_FAILED      -> "The video encoder encountered an error during export."
        NleNativeErrorCode.EXPORT_FAILED              -> "The export failed."
        NleNativeErrorCode.EXPORT_JOB_NOT_FOUND       -> "The export job was not found."
        NleNativeErrorCode.EXPORT_JOB_ALREADY_RUNNING -> "An export job with that ID is already running."
        else                                       -> "The Android video engine had a problem."
    }

    private fun Map<String, Any?>.requireString(key: String): String {
        return this[key] as? String
            ?: throw IllegalArgumentException("${NleNativeErrorCode.INVALID_ARGUMENTS}: missing '$key'")
    }

    private fun Map<String, Any?>.requireLong(key: String): Long? {
        return when (val v = this[key]) {
            is Long   -> v
            is Int    -> v.toLong()
            is Double -> v.toLong()
            is Float  -> v.toLong()
            else      -> null
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun Map<String, Any?>.asStringDynamicMap(key: String): Map<String, Any?> {
        val value = this[key]
        return when (value) {
            is Map<*, *> -> value.entries.associate { it.key.toString() to it.value }
            else         -> emptyMap()
        }
    }
}
