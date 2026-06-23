package com.kata.videoeditor.nle

import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import com.kata.videoeditor.nle.gpu.NleCompositorSession
import com.kata.videoeditor.nle.audio.NleRenderGraphAudioParser
import com.kata.videoeditor.nle.audio.NleAudioMixExporter
import com.kata.videoeditor.nle.audio.NleMp4AudioVideoMuxer
import com.kata.videoeditor.nle.export.NleExportMode
import com.kata.videoeditor.nle.export.NleTrueDecoderVideoExporter
import com.kata.videoeditor.nle.export.NleTrueExportGraphParser

/**
 * Background worker that coordinates the end-to-end export process (both video
 * rendering and optional audio mixing/encoding/remuxing) and emits structured
 * events via [NleNativeEventEmitter].
 */
class NleExportJob(
    val jobId: String,
    val projectId: String?,
    val renderGraphJson: String,
    val outputPath: String,
    val profile: NleExportProfile,
    val exportMode: NleExportMode,
    private val eventEmitter: NleNativeEventEmitter,
    private val compositorSession: NleCompositorSession
) : Runnable {

    val cancelled = AtomicBoolean(false)

    private val parser   = NleRenderGraphExportParser()
    private val exporter = NleTimelineFrameExporter(compositorSession)

    override fun run() {
        // ── Started ──────────────────────────────────────────────────────────
        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.EXPORT_STARTED,
                projectId = projectId,
                jobId     = jobId,
                payload   = mapOf(
                    "stage"    to "Parsing project",
                    "progress" to 0
                )
            )
        )

        var tempVideoPath: String? = null
        var tempAudioPath: String? = null

        try {
            // ── Parse render graph ────────────────────────────────────────────
            val timeline = parser.parse(renderGraphJson)

            if (cancelled.get()) {
                emitCancelled()
                return
            }

            // Check if audio should be included and if the timeline contains audio
            val audioParser = NleRenderGraphAudioParser()
            val audioTimeline = audioParser.parse(
                projectId = projectId ?: "export",
                renderGraphJson = renderGraphJson,
                fallbackDurationMicros = timeline.totalDurationMicros
            )
            val hasAudio = exportMode != NleExportMode.TRUE_DECODER_V2 && profile.includeAudio && audioTimeline.hasAudio

            if (hasAudio) {
                tempVideoPath = "$outputPath.temp_video.mp4"
                tempAudioPath = "$outputPath.temp_audio.m4a"
            }

            eventEmitter.emit(
                NleNativeEvent(
                    type      = NleNativeEventType.EXPORT_PROGRESS,
                    projectId = projectId,
                    jobId     = jobId,
                    payload   = mapOf(
                        "stage"       to "Rendering video",
                        "progress"    to 1,
                        "totalFrames" to (timeline.totalDurationMicros / (1_000_000L / profile.frameRate)).toInt()
                    )
                )
            )

            // ── Video Render stage ────────────────────────────────────────────
            val videoRenderOutput = tempVideoPath ?: outputPath
            if (exportMode == NleExportMode.TRUE_DECODER_V2) {
                val trueExporter = NleTrueDecoderVideoExporter()
                trueExporter.export(
                    renderGraphJson = renderGraphJson,
                    outputPath = videoRenderOutput,
                    profile    = profile,
                    cancelled  = cancelled,
                    onProgress = { progress ->
                        if (!cancelled.get()) {
                            val displayProgress = if (hasAudio) {
                                (progress * 0.5f).toInt().coerceIn(1, 50)
                            } else {
                                progress
                            }
                            eventEmitter.emit(
                                NleNativeEvent(
                                    type      = NleNativeEventType.EXPORT_PROGRESS,
                                    projectId = projectId,
                                    jobId     = jobId,
                                    payload   = mapOf(
                                        "stage"    to "Rendering video",
                                        "progress" to displayProgress
                                    )
                                )
                            )
                        }
                    }
                )
            } else {
                exporter.export(
                    timeline   = timeline,
                    outputPath = videoRenderOutput,
                    profile    = profile,
                    cancelled  = cancelled,
                    onProgress = { progress ->
                        if (!cancelled.get()) {
                            val displayProgress = if (hasAudio) {
                                (progress * 0.5f).toInt().coerceIn(1, 50)
                            } else {
                                progress
                            }
                            eventEmitter.emit(
                                NleNativeEvent(
                                    type      = NleNativeEventType.EXPORT_PROGRESS,
                                    projectId = projectId,
                                    jobId     = jobId,
                                    payload   = mapOf(
                                        "stage"    to "Rendering video",
                                        "progress" to displayProgress
                                    )
                                )
                            )
                        }
                    }
                )
            }

            if (cancelled.get()) {
                emitCancelled()
                return
            }

            // ── Audio Mix & Remux stage ───────────────────────────────────────
            if (hasAudio && tempVideoPath != null && tempAudioPath != null) {
                val audioMixExporter = NleAudioMixExporter()
                val finalAudioPath = audioMixExporter.exportAudioMix(
                    projectId = projectId ?: "export",
                    renderGraphJson = renderGraphJson,
                    durationMicros = timeline.totalDurationMicros,
                    outputM4aPath = tempAudioPath,
                    profile = profile,
                    cancelled = cancelled,
                    onProgress = { progress, stage ->
                        if (!cancelled.get()) {
                            val displayProgress = (50 + progress * 0.5f).toInt().coerceIn(50, 91)
                            eventEmitter.emit(
                                NleNativeEvent(
                                    type      = NleNativeEventType.EXPORT_PROGRESS,
                                    projectId = projectId,
                                    jobId     = jobId,
                                    payload   = mapOf(
                                        "stage"    to stage,
                                        "progress" to displayProgress
                                    )
                                )
                            )
                        }
                    }
                )

                if (cancelled.get()) {
                    emitCancelled()
                    return
                }

                val muxer = NleMp4AudioVideoMuxer()
                muxer.mux(
                    videoOnlyPath = tempVideoPath,
                    audioM4aPath = finalAudioPath,
                    finalOutputPath = outputPath,
                    cancelled = cancelled,
                    onProgress = { progress, stage ->
                        if (!cancelled.get()) {
                            val displayProgress = (50 + progress * 0.5f).toInt().coerceIn(92, 99)
                            eventEmitter.emit(
                                NleNativeEvent(
                                    type      = NleNativeEventType.EXPORT_PROGRESS,
                                    projectId = projectId,
                                    jobId     = jobId,
                                    payload   = mapOf(
                                        "stage"    to stage,
                                        "progress" to displayProgress
                                    )
                                )
                            )
                        }
                    }
                )
            }

            // ── Result ────────────────────────────────────────────────────────
            if (cancelled.get()) {
                emitCancelled()
                return
            }

            val outFile  = File(outputPath)
            val fileSize = if (outFile.exists()) outFile.length() else 0L

            eventEmitter.emit(
                NleNativeEvent(
                    type      = NleNativeEventType.EXPORT_COMPLETED,
                    projectId = projectId,
                    jobId     = jobId,
                    payload   = mapOf(
                        "stage"    to "Complete",
                        "progress" to 100,
                        "result"   to mapOf(
                            "outputPath" to outputPath,
                            "fileSize"   to fileSize,
                            "width"      to profile.width,
                            "height"     to profile.height,
                            "codec"      to profile.codec
                        )
                    )
                )
            )

        } catch (e: Exception) {
            if (cancelled.get()) {
                emitCancelled()
                return
            }

            val code = codeFromException(e)
            eventEmitter.emitError(
                projectId        = projectId,
                sessionId        = null,
                commandId        = null,
                code             = code,
                message          = "Export failed: ${e.localizedMessage}",
                technicalMessage = e.stackTraceToString()
            )
            eventEmitter.emit(
                NleNativeEvent(
                    type      = NleNativeEventType.EXPORT_FAILED,
                    projectId = projectId,
                    jobId     = jobId,
                    payload   = mapOf(
                        "errorCode"    to code,
                        "errorMessage" to e.localizedMessage
                    )
                )
            )

            // Clean up output file
            try { File(outputPath).takeIf { it.exists() }?.delete() } catch (_: Exception) {}
        } finally {
            // Clean up temporary audio and video files
            try { tempVideoPath?.let { File(it).takeIf { f -> f.exists() }?.delete() } } catch (_: Exception) {}
            try { tempAudioPath?.let { File(it).takeIf { f -> f.exists() }?.delete() } } catch (_: Exception) {}
        }
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private fun emitCancelled() {
        eventEmitter.emit(
            NleNativeEvent(
                type      = NleNativeEventType.EXPORT_CANCELLED,
                projectId = projectId,
                jobId     = jobId,
                payload   = mapOf("stage" to "Cancelled")
            )
        )
        try { File(outputPath).takeIf { it.exists() }?.delete() } catch (_: Exception) {}
    }

    private fun codeFromException(e: Exception): String {
        val msg = e.message ?: ""
        return when {
            msg.contains(NleNativeErrorCode.EXPORT_NO_CLIPS)       -> NleNativeErrorCode.EXPORT_NO_CLIPS
            msg.contains(NleNativeErrorCode.EXPORT_MISSING_ASSET)  -> NleNativeErrorCode.EXPORT_MISSING_ASSET
            msg.contains(NleNativeErrorCode.EXPORT_ENCODER_FAILED) -> NleNativeErrorCode.EXPORT_ENCODER_FAILED
            msg.contains(NleNativeErrorCode.EXPORT_DECODER_FAILED) -> NleNativeErrorCode.EXPORT_DECODER_FAILED
            msg.contains(NleNativeErrorCode.EXPORT_DECODER_TIMEOUT) -> NleNativeErrorCode.EXPORT_DECODER_TIMEOUT
            msg.contains(NleNativeErrorCode.EXPORT_SURFACE_TEXTURE_FAILED) -> NleNativeErrorCode.EXPORT_SURFACE_TEXTURE_FAILED
            msg.contains(NleNativeErrorCode.EXPORT_RENDER_FAILED)  -> NleNativeErrorCode.EXPORT_RENDER_FAILED
            msg.contains(NleNativeErrorCode.EXPORT_MUXER_FAILED)   -> NleNativeErrorCode.EXPORT_MUXER_FAILED
            msg.contains(NleNativeErrorCode.EXPORT_SYNC_WARNING)   -> NleNativeErrorCode.EXPORT_SYNC_WARNING
            msg.contains(NleNativeErrorCode.AUDIO_EXPORT_DECODE_FAILED) -> NleNativeErrorCode.AUDIO_EXPORT_DECODE_FAILED
            msg.contains(NleNativeErrorCode.AUDIO_EXPORT_MIX_FAILED)    -> NleNativeErrorCode.AUDIO_EXPORT_MIX_FAILED
            msg.contains(NleNativeErrorCode.AUDIO_EXPORT_ENCODE_FAILED) -> NleNativeErrorCode.AUDIO_EXPORT_ENCODE_FAILED
            msg.contains(NleNativeErrorCode.AUDIO_EXPORT_MUX_FAILED)    -> NleNativeErrorCode.AUDIO_EXPORT_MUX_FAILED
            else                                                     -> NleNativeErrorCode.EXPORT_FAILED
        }
    }
}
