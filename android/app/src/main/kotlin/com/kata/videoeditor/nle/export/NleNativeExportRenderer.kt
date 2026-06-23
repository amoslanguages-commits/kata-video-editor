package com.kata.videoeditor.nle.export

import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import com.kata.videoeditor.nle.NleNativeEvent
import com.kata.videoeditor.nle.NleNativeEventEmitter
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
    private val runningJobs = ConcurrentHashMap<String, ExportCancellationToken>()

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
        val width = profileMap.intValue("width")
            ?: profileMap.intValue("targetWidth")
            ?: profileMap.intValue("outputWidth")
            ?: 1920
        val height = profileMap.intValue("height")
            ?: profileMap.intValue("resolution")
            ?: profileMap.intValue("targetHeight")
            ?: 1080
        val frameRate = profileMap.intValue("frameRate") ?: 30

        val timeline = parser.parse(
            projectId = safeProjectId,
            renderGraphJson = renderGraphJson,
            outputWidth = width,
            outputHeight = height,
            frameRate = frameRate,
        )

        val token = ExportCancellationToken()
        runningJobs[jobId] = token

        emit(jobId, safeProjectId, "export_started", mapOf("stage" to "Preparing", "progress" to 0))

        thread(name = "nle-native-export-$jobId") {
            try {
                renderPassThroughSingleClip(
                    jobId = jobId,
                    projectId = safeProjectId,
                    timeline = timeline,
                    outputPath = outputPath,
                    token = token,
                )
                runningJobs.remove(jobId)
            } catch (error: Throwable) {
                runningJobs.remove(jobId)
                val message = error.message ?: error.toString()
                emit(jobId, safeProjectId, "export_failed", mapOf("errorMessage" to message, "stage" to "Failed"))
            }
        }

        return mapOf("jobId" to jobId, "accepted" to true, "nativeRenderer" to "android_media_muxer_v1")
    }

    fun cancel(jobId: String): Map<String, Any?> {
        val token = runningJobs.remove(jobId)
        token?.cancelled = true
        emit(jobId, null, "export_cancelled", mapOf("stage" to "Cancelled"))
        return mapOf("jobId" to jobId, "cancelled" to true)
    }

    private fun renderPassThroughSingleClip(
        jobId: String,
        projectId: String,
        timeline: NleTrueExportTimeline,
        outputPath: String,
        token: ExportCancellationToken,
    ) {
        val visualClips = timeline.visualClips.filter { it.clipType == "video" }
        if (visualClips.size != 1 || timeline.visualClips.size != 1) {
            throw UnsupportedOperationException(
                "Native composited export requires the next renderer stage. Current Android native exporter supports exactly one video clip without overlays/text."
            )
        }

        val clip = visualClips.first()
        if (clip.speed != 1.0) {
            throw UnsupportedOperationException("Native pass-through export does not support speed changes yet.")
        }
        if (clip.rotation != 0f || clip.scale != 1f || clip.positionX != 0f || clip.positionY != 0f || clip.opacity != 1f) {
            throw UnsupportedOperationException("Native pass-through export does not support transform/composited clips yet.")
        }

        val asset = timeline.assetsById[clip.assetId]
            ?: throw IllegalStateException("Export asset for clip ${clip.id} was not found.")
        if (!asset.hasVideo) {
            throw IllegalStateException("Export asset ${asset.id} has no video track.")
        }

        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) outputFile.delete()

        emit(jobId, projectId, "export_progress", mapOf("stage" to "Muxing", "progress" to 3))

        val trackFormats = readSupportedTrackFormats(asset.path)
        if (trackFormats.isEmpty()) {
            throw IllegalStateException("No video/audio tracks could be read from ${asset.path}.")
        }

        var muxer: MediaMuxer? = null
        try {
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val muxerTrackMap = linkedMapOf<Int, Int>()
            for ((sourceTrack, format) in trackFormats) {
                muxerTrackMap[sourceTrack] = muxer.addTrack(format)
            }
            muxer.start()

            val totalTracks = muxerTrackMap.size.coerceAtLeast(1)
            var completedTracks = 0
            for ((sourceTrack, muxerTrack) in muxerTrackMap) {
                if (token.cancelled) throw ExportCancelledException()
                copyTrackSamples(
                    assetPath = asset.path,
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

            emit(jobId, projectId, "export_progress", mapOf("stage" to "Finalizing", "progress" to 98))
        } catch (cancelled: ExportCancelledException) {
            outputFile.delete()
            emit(jobId, projectId, "export_cancelled", mapOf("stage" to "Cancelled"))
            return
        } finally {
            try { muxer?.stop() } catch (_: Throwable) {}
            try { muxer?.release() } catch (_: Throwable) {}
        }

        if (!outputFile.exists() || outputFile.length() <= 0L) {
            throw IllegalStateException("Native export completed but output file was not created.")
        }

        emit(
            jobId,
            projectId,
            "export_completed",
            mapOf(
                "stage" to "Complete",
                "progress" to 100,
                "result" to mapOf(
                    "outputPath" to outputPath,
                    "fileSize" to outputFile.length(),
                    "renderer" to "android_media_muxer_v1",
                ),
            ),
        )
    }

    private fun readSupportedTrackFormats(path: String): List<Pair<Int, MediaFormat>> {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(path)
            val result = mutableListOf<Pair<Int, MediaFormat>>()
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("video/") || mime.startsWith("audio/")) {
                    result.add(i to format)
                }
            }
            return result
        } finally {
            try { extractor.release() } catch (_: Throwable) {}
        }
    }

    private fun copyTrackSamples(
        assetPath: String,
        sourceTrack: Int,
        muxer: MediaMuxer,
        muxerTrack: Int,
        clipStartUs: Long,
        clipEndUs: Long,
        jobId: String,
        projectId: String,
        baseProgress: Int,
        progressSpan: Int,
        token: ExportCancellationToken,
    ) {
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
                if (sampleTrack != sourceTrack) {
                    extractor.advance()
                    continue
                }

                val sampleTime = extractor.sampleTime
                if (sampleTime < 0 || sampleTime > clipEndUs) break

                buffer.clear()
                val sampleSize = extractor.readSampleData(buffer, 0)
                if (sampleSize < 0) break

                info.set(
                    0,
                    sampleSize,
                    (sampleTime - clipStartUs).coerceAtLeast(0L),
                    extractor.sampleFlags,
                )
                muxer.writeSampleData(muxerTrack, buffer, info)

                val localProgress = ((sampleTime - clipStartUs).coerceAtLeast(0L) * progressSpan / durationUs).toInt()
                val progress = (baseProgress + localProgress).coerceIn(0, 97)
                if (progress != lastProgress && progress % 5 == 0) {
                    lastProgress = progress
                    emit(jobId, projectId, "export_progress", mapOf("stage" to "Muxing", "progress" to progress))
                }
                extractor.advance()
            }
            if (token.cancelled) throw ExportCancelledException()
        } finally {
            try { extractor.release() } catch (_: Throwable) {}
        }
    }

    private fun emit(jobId: String, projectId: String?, type: String, payload: Map<String, Any?>) {
        eventEmitter.emit(
            NleNativeEvent(
                type = type,
                projectId = projectId,
                jobId = jobId,
                payload = payload,
            )
        )
    }
}

private class ExportCancellationToken {
    @Volatile var cancelled: Boolean = false
}

private class ExportCancelledException : RuntimeException("Export cancelled")

private fun Map<String, Any?>.intValue(key: String): Int? {
    val value = this[key] ?: return null
    return when (value) {
        is Int -> value
        is Long -> value.toInt()
        is Double -> value.toInt()
        is Float -> value.toInt()
        is Number -> value.toInt()
        is String -> value.toIntOrNull()
        else -> null
    }
}
