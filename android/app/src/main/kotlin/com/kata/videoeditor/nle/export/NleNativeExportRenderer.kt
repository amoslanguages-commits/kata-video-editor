package com.kata.videoeditor.nle.export

import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import com.kata.videoeditor.nle.NleNativeEvent
import com.kata.videoeditor.nle.NleNativeEventEmitter
import org.json.JSONObject
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentHashMap
import kotlin.concurrent.thread
import kotlin.math.max
import kotlin.math.min

class NleNativeExportRenderer(
    private val eventEmitter: NleNativeEventEmitter,
) {
    private val parser = NleTrueExportGraphParser()
    private val runningJobs = ConcurrentHashMap<String, NleExportCancellationToken>()

    fun start(
        projectId: String?,
        jobId: String,
        renderGraphJson: String,
        outputPath: String,
        profileMap: Map<String, Any?>,
    ): Map<String, Any?> {
        if (runningJobs.containsKey(jobId)) {
            throw IllegalStateException("Export job $jobId is already running.")
        }

        val safeProjectId = projectId ?: ""
        val width = profileMap.exportInt("width")
            ?: profileMap.exportInt("targetWidth")
            ?: profileMap.exportInt("outputWidth")
            ?: 1920
        val height = profileMap.exportInt("height")
            ?: profileMap.exportInt("resolution")
            ?: profileMap.exportInt("targetHeight")
            ?: 1080
        val frameRate = profileMap.exportInt("frameRate") ?: 30
        val preferProxyForExport = profileMap.exportBool("preferProxy")
            ?: profileMap.exportBool("useProxy")
            ?: profileMap.exportBool("useProxyForExport")
            ?: renderGraphJson.contains("\"useOriginalForExport\":false")

        val timeline = parser.parse(
            projectId = safeProjectId,
            renderGraphJson = renderGraphJson,
            outputWidth = width,
            outputHeight = height,
            frameRate = frameRate,
            preferProxy = preferProxyForExport,
        )

        val needsAudioMixdown = requiresAudioMixdown(renderGraphJson)
        val token = NleExportCancellationToken()
        runningJobs[jobId] = token

        emitExportState(
            jobId = jobId,
            projectId = safeProjectId,
            eventType = "export_accepted",
            previousState = "created",
            exportState = "accepted",
            stage = "Accepted",
            progress = 0,
            terminal = false,
            extraPayload = mapOf("requiresAudioMixdown" to needsAudioMixdown),
        )

        emitExportState(
            jobId = jobId,
            projectId = safeProjectId,
            eventType = "export_started",
            previousState = "accepted",
            exportState = "preparing",
            stage = "Preparing",
            progress = 0,
            terminal = false,
            extraPayload = mapOf("requiresAudioMixdown" to needsAudioMixdown),
        )

        thread(name = "nle-native-export-$jobId") {
            try {
                val rendererName = if (requiresCompositedExport(timeline) || needsAudioMixdown) {
                    NleCompositedExportRenderer { type, payload ->
                        if (type == "export_progress") {
                            val stage = payload["stage"] as? String ?: "Unknown"
                            val progress = (payload["progress"] as? Number)?.toInt() ?: 0
                            val newExportState = exportStateForStage(stage, progress)
                            emitExportState(
                                jobId = jobId,
                                projectId = safeProjectId,
                                eventType = type,
                                previousState = "preparing",
                                exportState = newExportState,
                                stage = stage,
                                progress = progress,
                                terminal = false,
                            )
                        } else {
                            emit(jobId, safeProjectId, type, payload)
                        }
                    }.render(
                        jobId = jobId,
                        renderGraphJson = renderGraphJson,
                        outputPath = outputPath,
                        profileMap = profileMap,
                        token = token,
                    )
                    "android_media_codec_compositor_v1"
                } else {
                    renderPassThroughSingleClip(jobId = jobId, projectId = safeProjectId, timeline = timeline, outputPath = outputPath, token = token)
                    "android_media_muxer_v1"
                }
                runningJobs.remove(jobId)
                val outputFile = File(outputPath)
                emitExportState(
                    jobId = jobId,
                    projectId = safeProjectId,
                    eventType = "export_completed",
                    previousState = "finalizing",
                    exportState = "completed",
                    stage = "Complete",
                    progress = 100,
                    terminal = true,
                    extraPayload = mapOf(
                        "result" to mapOf(
                            "outputPath" to outputPath,
                            "fileSize" to outputFile.length(),
                            "renderer" to rendererName,
                            "preferProxy" to preferProxyForExport,
                            "requiresAudioMixdown" to needsAudioMixdown,
                        ),
                    ),
                )
            } catch (cancelled: NleExportCancelledException) {
                runningJobs.remove(jobId)
                File(outputPath).delete()
                val errorPayload = exportErrorPayload(
                    code = "export_cancelled",
                    severity = "info",
                    userMessage = "Export was cancelled.",
                    technicalMessage = "User cancelled the export operation.",
                    recoverySuggestion = "Try exporting again.",
                    retryable = true,
                )
                emitExportState(
                    jobId = jobId,
                    projectId = safeProjectId,
                    eventType = "export_cancelled",
                    previousState = "cancel_requested",
                    exportState = "cancelled",
                    stage = "Cancelled",
                    progress = 0,
                    terminal = true,
                    extraPayload = mapOf("error" to errorPayload),
                )
            } catch (error: Throwable) {
                runningJobs.remove(jobId)
                val errorPayload = exportErrorFor(error)
                emitExportState(
                    jobId = jobId,
                    projectId = safeProjectId,
                    eventType = "export_failed",
                    previousState = "rendering",
                    exportState = "failed",
                    stage = "Failed",
                    progress = 0,
                    terminal = true,
                    extraPayload = mapOf(
                        "error" to errorPayload,
                        "errorMessage" to (errorPayload["userMessage"] as? String ?: "Unknown error"),
                    ),
                )
            }
        }

        return mapOf("jobId" to jobId, "accepted" to true, "exportState" to "preparing", "nativeRenderer" to "android_native_export_v2", "preferProxy" to preferProxyForExport, "requiresAudioMixdown" to needsAudioMixdown)
    }

    fun cancel(jobId: String): Map<String, Any?> {
        val token = runningJobs.remove(jobId)
        return if (token != null) {
            token.cancelled = true
            mapOf("jobId" to jobId, "cancelRequested" to true, "exportState" to "cancel_requested")
        } else {
            val errorPayload = exportErrorPayload(
                code = "export_job_not_found",
                severity = "fatal",
                userMessage = "Export job not found.",
                technicalMessage = "The specified export job ID does not exist or has already completed.",
                recoverySuggestion = "Verify the job ID and try again.",
                retryable = false,
            )
            mapOf(
                "jobId" to jobId,
                "cancelRequested" to false,
                "exportState" to "failed",
                "error" to errorPayload,
            )
        }
    }

    private fun requiresCompositedExport(timeline: NleTrueExportTimeline): Boolean {
        if (timeline.visualClips.size != 1) return true
        val clip = timeline.visualClips.first()
        if (clip.clipType != "video") return true
        if (clip.speed != 1.0) return true
        if (clip.rotation != 0f || clip.scale != 1f || clip.positionX != 0f || clip.positionY != 0f || clip.opacity != 1f) return true
        if (clip.brightness != 0f || clip.contrast != 1f || clip.saturation != 1f) return true
        return false
    }

    private fun requiresAudioMixdown(renderGraphJson: String): Boolean {
        return try {
            val root = JSONObject(renderGraphJson)
            root.optJSONObject("exportHints")?.optBoolean("requiresAudioMixdown", false) == true
        } catch (_: Throwable) {
            renderGraphJson.contains("\"requiresAudioMixdown\":true")
        }
    }

    private fun renderPassThroughSingleClip(jobId: String, projectId: String, timeline: NleTrueExportTimeline, outputPath: String, token: NleExportCancellationToken) {
        val visualClips = timeline.visualClips.filter { it.clipType == "video" }
        if (visualClips.size != 1 || timeline.visualClips.size != 1) throw IllegalStateException("Pass-through export requires exactly one video clip.")
        val clip = visualClips.first()
        val asset = timeline.assetsById[clip.assetId] ?: throw IllegalStateException("Export asset for clip ${clip.id} was not found.")
        if (!asset.hasVideo) throw IllegalStateException("Export asset ${asset.id} has no video track.")

        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) outputFile.delete()

        emitExportState(
            jobId = jobId,
            projectId = projectId,
            eventType = "export_progress",
            previousState = "preparing",
            exportState = "muxing",
            stage = "Muxing",
            progress = 3,
            terminal = false,
        )

        val assetPath = asset.decoderPath
        val trackFormats = readSupportedTrackFormats(assetPath)
        if (trackFormats.isEmpty()) throw IllegalStateException("No video/audio tracks could be read from $assetPath.")

        var muxer: MediaMuxer? = null
        try {
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val muxerTrackMap = linkedMapOf<Int, Int>()
            for ((sourceTrack, format) in trackFormats) muxerTrackMap[sourceTrack] = muxer.addTrack(format)
            muxer.start()
            val totalTracks = muxerTrackMap.size.coerceAtLeast(1)
            var completedTracks = 0
            for ((sourceTrack, muxerTrack) in muxerTrackMap) {
                if (token.cancelled) throw NleExportCancelledException()
                copyTrackSamples(
                    assetPath = assetPath,
                    sourceTrack = sourceTrack,
                    muxer = muxer,
                    muxerTrack = muxerTrack,
                    clipStartUs = clip.sourceStartUs,
                    clipEndUs = min(clip.sourceEndUs, asset.durationUs.takeIf { it > 0 } ?: clip.sourceEndUs),
                    jobId = jobId,
                    projectId = projectId,
                    baseProgress = 5 + completedTracks * (90 / totalTracks),
                    progressSpan = 90 / totalTracks,
                    token = token,
                )
                completedTracks += 1
            }
            emitExportState(
                jobId = jobId,
                projectId = projectId,
                eventType = "export_progress",
                previousState = "muxing",
                exportState = "finalizing",
                stage = "Finalizing",
                progress = 98,
                terminal = false,
            )
        } finally {
            try { muxer?.stop() } catch (_: Throwable) {}
            try { muxer?.release() } catch (_: Throwable) {}
        }
        if (!outputFile.exists() || outputFile.length() <= 0L) throw IllegalStateException("Native export completed but output file was not created.")
    }

    private fun readSupportedTrackFormats(path: String): List<Pair<Int, MediaFormat>> {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(path)
            val result = mutableListOf<Pair<Int, MediaFormat>>()
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("video/") || mime.startsWith("audio/")) result.add(i to format)
            }
            return result
        } finally {
            try { extractor.release() } catch (_: Throwable) {}
        }
    }

    private fun copyTrackSamples(assetPath: String, sourceTrack: Int, muxer: MediaMuxer, muxerTrack: Int, clipStartUs: Long, clipEndUs: Long, jobId: String, projectId: String, baseProgress: Int, progressSpan: Int, token: NleExportCancellationToken) {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(assetPath)
            extractor.selectTrack(sourceTrack)
            extractor.seekTo(clipStartUs.coerceAtLeast(0L), MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            val buffer = ByteBuffer.allocateDirect(2 * 1024 * 1024)
            val info = android.media.MediaCodec.BufferInfo()
            var lastProgress = -1
            val durationUs = max(1L, clipEndUs - clipStartUs)
            while (!token.cancelled) {
                val sampleTrack = extractor.sampleTrackIndex
                if (sampleTrack < 0) break
                if (sampleTrack != sourceTrack) { extractor.advance(); continue }
                val sampleTime = extractor.sampleTime
                if (sampleTime < 0 || sampleTime > clipEndUs) break
                buffer.clear()
                val sampleSize = extractor.readSampleData(buffer, 0)
                if (sampleSize < 0) break
                info.set(0, sampleSize, (sampleTime - clipStartUs).coerceAtLeast(0L), extractor.sampleFlags)
                muxer.writeSampleData(muxerTrack, buffer, info)
                val localProgress = ((sampleTime - clipStartUs).coerceAtLeast(0L) * progressSpan / durationUs).toInt()
                val progress = (baseProgress + localProgress).coerceIn(0, 97)
                if (progress != lastProgress && progress % 5 == 0) {
                    lastProgress = progress
                    emitExportState(
                        jobId = jobId,
                        projectId = projectId,
                        eventType = "export_progress",
                        previousState = "muxing",
                        exportState = "muxing",
                        stage = "Muxing",
                        progress = progress,
                        terminal = false,
                    )
                }
                extractor.advance()
            }
            if (token.cancelled) throw NleExportCancelledException()
        } finally {
            try { extractor.release() } catch (_: Throwable) {}
        }
    }

    private fun emitExportState(
        jobId: String,
        projectId: String,
        eventType: String,
        previousState: String,
        exportState: String,
        stage: String,
        progress: Int,
        terminal: Boolean,
        extraPayload: Map<String, Any?> = emptyMap(),
    ) {
        val payload = mutableMapOf<String, Any?>(
            "jobId" to jobId,
            "projectId" to projectId,
            "previousState" to previousState,
            "exportState" to exportState,
            "state" to exportState,
            "stage" to stage,
            "progress" to progress,
            "terminal" to terminal,
        )
        payload.putAll(extraPayload)
        emit(jobId, projectId, eventType, payload)
    }

    private fun exportStateForStage(stage: String, progress: Int): String {
        return when {
            stage.equals("Preparing", ignoreCase = true) -> "preparing"
            stage.equals("Preflighting", ignoreCase = true) -> "preflighting"
            stage.equals("Queued", ignoreCase = true) -> "queued"
            stage.equals("Rendering", ignoreCase = true) -> "rendering"
            stage.equals("Muxing", ignoreCase = true) -> "muxing"
            stage.equals("Finalizing", ignoreCase = true) -> "finalizing"
            stage.equals("Complete", ignoreCase = true) -> "completed"
            stage.equals("Cancelled", ignoreCase = true) -> "cancelled"
            stage.equals("Failed", ignoreCase = true) -> "failed"
            else -> "rendering"
        }
    }

    private fun exportErrorFor(error: Throwable): Map<String, Any?> {
        val message = error.message ?: error.toString()
        val userMessage = when {
            error is IllegalStateException -> message
            error is NleExportCancelledException -> "Export was cancelled."
            else -> "An unexpected error occurred during export."
        }
        return exportErrorPayload(
            code = error.javaClass.simpleName,
            severity = "fatal",
            userMessage = userMessage,
            technicalMessage = message,
            recoverySuggestion = "Check the export settings and try again.",
            retryable = true,
        )
    }

    private fun exportErrorPayload(
        code: String,
        severity: String,
        userMessage: String,
        technicalMessage: String = userMessage,
        recoverySuggestion: String = "",
        retryable: Boolean = true,
    ): Map<String, Any?> {
        return mapOf(
            "code" to code,
            "severity" to severity,
            "userMessage" to userMessage,
            "message" to userMessage,
            "technicalMessage" to technicalMessage,
            "recoverySuggestion" to recoverySuggestion,
            "retryable" to retryable,
        )
    }

    private fun emit(jobId: String, projectId: String?, type: String, payload: Map<String, Any?>) {
        eventEmitter.emit(NleNativeEvent(type = type, projectId = projectId, jobId = jobId, payload = payload))
    }
}
