package com.kata.videoeditor.nle.proxy

import android.media.MediaCodec
import android.media.MediaCodecInfo
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

class NleNativeProxyRenderer(
    private val eventEmitter: NleNativeEventEmitter,
) {
    private val runningJobs = ConcurrentHashMap<String, ProxyCancellationToken>()

    fun start(
        projectId: String?,
        jobId: String,
        assetId: String,
        inputPath: String,
        outputPath: String,
        profileMap: Map<String, Any?>,
    ): Map<String, Any?> {
        if (runningJobs.containsKey(jobId)) {
            throw IllegalStateException("Proxy job $jobId is already running.")
        }
        val token = ProxyCancellationToken()
        runningJobs[jobId] = token

        val targetHeight = profileMap.intValue("height")
            ?: profileMap.intValue("targetHeight")
            ?: profileMap.intValue("proxyHeight")
            ?: 720
        val targetWidth = profileMap.intValue("width")
            ?: profileMap.intValue("targetWidth")
            ?: profileMap.intValue("proxyWidth")
            ?: 1280
        val frameRate = profileMap.intValue("frameRate") ?: 30
        val bitrate = profileMap.intValue("bitrate")
            ?: profileMap.intValue("videoBitrate")
            ?: defaultProxyBitrate(targetWidth, targetHeight, frameRate)

        emit(jobId, projectId, "proxy_started", mapOf("assetId" to assetId, "stage" to "Preparing", "progress" to 0))

        thread(name = "nle-proxy-$jobId") {
            try {
                transcodeVideoProxy(
                    jobId = jobId,
                    projectId = projectId,
                    assetId = assetId,
                    inputPath = inputPath,
                    outputPath = outputPath,
                    width = targetWidth,
                    height = targetHeight,
                    frameRate = frameRate,
                    bitrate = bitrate,
                    token = token,
                )
                runningJobs.remove(jobId)
                val file = File(outputPath)
                emit(
                    jobId,
                    projectId,
                    "proxy_completed",
                    mapOf(
                        "assetId" to assetId,
                        "proxyPath" to outputPath,
                        "outputPath" to outputPath,
                        "proxyWidth" to targetWidth,
                        "proxyHeight" to targetHeight,
                        "proxyCodec" to "h264/aac-mp4",
                        "fileSize" to file.length(),
                    ),
                )
            } catch (cancelled: ProxyCancelledException) {
                runningJobs.remove(jobId)
                File(outputPath).delete()
                emit(jobId, projectId, "proxy_cancelled", mapOf("assetId" to assetId, "stage" to "Cancelled"))
            } catch (error: Throwable) {
                runningJobs.remove(jobId)
                File(outputPath).delete()
                emit(
                    jobId,
                    projectId,
                    "proxy_failed",
                    mapOf(
                        "assetId" to assetId,
                        "errorMessage" to (error.message ?: error.toString()),
                        "stage" to "Failed",
                    ),
                )
            }
        }

        return mapOf("jobId" to jobId, "assetId" to assetId, "accepted" to true, "nativeRenderer" to "android_media_codec_proxy_v1")
    }

    fun cancel(jobId: String): Map<String, Any?> {
        val token = runningJobs.remove(jobId)
        token?.cancelled = true
        return mapOf("jobId" to jobId, "cancelled" to true)
    }

    private fun transcodeVideoProxy(
        jobId: String,
        projectId: String?,
        assetId: String,
        inputPath: String,
        outputPath: String,
        width: Int,
        height: Int,
        frameRate: Int,
        bitrate: Int,
        token: ProxyCancellationToken,
    ) {
        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) outputFile.delete()

        val videoTrack = firstTrack(inputPath, "video/")
            ?: throw IllegalStateException("Source asset has no video track for proxy generation.")
        val audioTrack = firstTrack(inputPath, "audio/")
        val sourceDurationUs = videoTrack.format.longValue(MediaFormat.KEY_DURATION).coerceAtLeast(1L)

        var extractor: MediaExtractor? = null
        var decoder: MediaCodec? = null
        var encoder: MediaCodec? = null
        var muxer: MediaMuxer? = null
        var muxerStarted = false
        var videoMuxerTrack = -1
        var audioMuxerTrack = -1

        try {
            val activeExtractor = MediaExtractor()
            extractor = activeExtractor
            activeExtractor.setDataSource(inputPath)
            activeExtractor.selectTrack(videoTrack.index)

            val encodeFormat = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
                setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
                setInteger(MediaFormat.KEY_FRAME_RATE, frameRate.coerceAtLeast(1))
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            }
            val activeEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
            encoder = activeEncoder
            activeEncoder.configure(encodeFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            val encoderInputSurface = activeEncoder.createInputSurface()
            activeEncoder.start()

            val mime = videoTrack.format.getString(MediaFormat.KEY_MIME)
                ?: throw IllegalStateException("Video track mime type is missing.")
            val activeDecoder = MediaCodec.createDecoderByType(mime)
            decoder = activeDecoder
            activeDecoder.configure(videoTrack.format, encoderInputSurface, null, 0)
            activeDecoder.start()

            val activeMuxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            muxer = activeMuxer

            val decoderInfo = MediaCodec.BufferInfo()
            var inputDone = false
            var decoderDone = false
            var encoderDone = false
            var lastProgress = -1

            while (!encoderDone) {
                if (token.cancelled) throw ProxyCancelledException()

                if (!inputDone) {
                    val inputBufferIndex = activeDecoder.dequeueInputBuffer(10_000L)
                    if (inputBufferIndex >= 0) {
                        val inputBuffer = activeDecoder.getInputBuffer(inputBufferIndex)
                            ?: throw IllegalStateException("Decoder input buffer was null.")
                        inputBuffer.clear()
                        val sampleSize = activeExtractor.readSampleData(inputBuffer, 0)
                        if (sampleSize < 0) {
                            activeDecoder.queueInputBuffer(inputBufferIndex, 0, 0, 0L, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            activeDecoder.queueInputBuffer(
                                inputBufferIndex,
                                0,
                                sampleSize,
                                activeExtractor.sampleTime.coerceAtLeast(0L),
                                activeExtractor.sampleFlags,
                            )
                            activeExtractor.advance()
                        }
                    }
                }

                if (!decoderDone) {
                    val decoderOutputIndex = activeDecoder.dequeueOutputBuffer(decoderInfo, 10_000L)
                    when {
                        decoderOutputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> Unit
                        decoderOutputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> Unit
                        decoderOutputIndex >= 0 -> {
                            val eos = decoderInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                            activeDecoder.releaseOutputBuffer(decoderOutputIndex, decoderInfo.size > 0)
                            if (decoderInfo.presentationTimeUs > 0) {
                                val progress = ((decoderInfo.presentationTimeUs * 85L) / sourceDurationUs).toInt().coerceIn(1, 85)
                                if (progress != lastProgress && progress % 5 == 0) {
                                    lastProgress = progress
                                    emit(jobId, projectId, "proxy_progress", mapOf("assetId" to assetId, "stage" to "Transcoding", "progress" to progress))
                                }
                            }
                            if (eos) {
                                decoderDone = true
                                activeEncoder.signalEndOfInputStream()
                            }
                        }
                    }
                }

                drainEncoder(
                    encoder = activeEncoder,
                    muxer = activeMuxer,
                    audioTrack = audioTrack,
                    muxerStarted = muxerStarted,
                    videoTrackIndex = videoMuxerTrack,
                    audioTrackIndex = audioMuxerTrack,
                ).also { state ->
                    muxerStarted = state.muxerStarted
                    videoMuxerTrack = state.videoTrackIndex
                    audioMuxerTrack = state.audioTrackIndex
                    encoderDone = state.encoderDone
                }
            }

            if (audioTrack != null) {
                if (!muxerStarted || audioMuxerTrack < 0) {
                    throw IllegalStateException("Muxer audio track was not ready for proxy audio copy.")
                }
                emit(jobId, projectId, "proxy_progress", mapOf("assetId" to assetId, "stage" to "Muxing audio", "progress" to 90))
                copyAudioTrack(inputPath, audioTrack.index, activeMuxer, audioMuxerTrack, token)
            }
            emit(jobId, projectId, "proxy_progress", mapOf("assetId" to assetId, "stage" to "Finalizing", "progress" to 98))
        } finally {
            try { decoder?.stop() } catch (_: Throwable) {}
            try { decoder?.release() } catch (_: Throwable) {}
            try { encoder?.stop() } catch (_: Throwable) {}
            try { encoder?.release() } catch (_: Throwable) {}
            try { muxer?.stop() } catch (_: Throwable) {}
            try { muxer?.release() } catch (_: Throwable) {}
            try { extractor?.release() } catch (_: Throwable) {}
        }

        if (!outputFile.exists() || outputFile.length() <= 0L) {
            throw IllegalStateException("Proxy renderer completed but no output file was produced.")
        }
    }

    private fun drainEncoder(
        encoder: MediaCodec,
        muxer: MediaMuxer,
        audioTrack: TrackInfo?,
        muxerStarted: Boolean,
        videoTrackIndex: Int,
        audioTrackIndex: Int,
    ): EncoderDrainState {
        val info = MediaCodec.BufferInfo()
        var started = muxerStarted
        var videoIndex = videoTrackIndex
        var audioIndex = audioTrackIndex
        var done = false

        while (true) {
            val index = encoder.dequeueOutputBuffer(info, 0L)
            when {
                index == MediaCodec.INFO_TRY_AGAIN_LATER -> return EncoderDrainState(started, videoIndex, audioIndex, done)
                index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (started) throw IllegalStateException("Proxy encoder output format changed after muxer start.")
                    videoIndex = muxer.addTrack(encoder.outputFormat)
                    if (audioTrack != null) audioIndex = muxer.addTrack(audioTrack.format)
                    muxer.start()
                    started = true
                }
                index >= 0 -> {
                    val encoded = encoder.getOutputBuffer(index)
                        ?: throw IllegalStateException("Proxy encoder output buffer was null.")
                    if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        info.size = 0
                    }
                    if (info.size > 0) {
                        if (!started || videoIndex < 0) throw IllegalStateException("Proxy muxer not started before encoded frame.")
                        encoded.position(info.offset)
                        encoded.limit(info.offset + info.size)
                        muxer.writeSampleData(videoIndex, encoded, info)
                    }
                    done = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                    encoder.releaseOutputBuffer(index, false)
                    if (done) return EncoderDrainState(started, videoIndex, audioIndex, true)
                }
            }
        }
    }

    private fun copyAudioTrack(
        inputPath: String,
        sourceTrack: Int,
        muxer: MediaMuxer,
        muxerTrack: Int,
        token: ProxyCancellationToken,
    ) {
        val extractor = MediaExtractor()
        val buffer = ByteBuffer.allocateDirect(2 * 1024 * 1024)
        val info = MediaCodec.BufferInfo()
        try {
            extractor.setDataSource(inputPath)
            extractor.selectTrack(sourceTrack)
            while (!token.cancelled) {
                val sampleTrack = extractor.sampleTrackIndex
                if (sampleTrack < 0) break
                if (sampleTrack != sourceTrack) {
                    extractor.advance()
                    continue
                }
                val sampleSize = extractor.readSampleData(buffer, 0)
                if (sampleSize < 0) break
                info.set(0, sampleSize, extractor.sampleTime.coerceAtLeast(0L), extractor.sampleFlags)
                muxer.writeSampleData(muxerTrack, buffer, info)
                buffer.clear()
                extractor.advance()
            }
        } finally {
            try { extractor.release() } catch (_: Throwable) {}
        }
        if (token.cancelled) throw ProxyCancelledException()
    }

    private fun firstTrack(path: String, mimePrefix: String): TrackInfo? {
        val extractor = MediaExtractor()
        return try {
            extractor.setDataSource(path)
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith(mimePrefix)) return TrackInfo(i, format)
            }
            null
        } finally {
            try { extractor.release() } catch (_: Throwable) {}
        }
    }

    private fun defaultProxyBitrate(width: Int, height: Int, frameRate: Int): Int {
        return (width.toLong() * height.toLong() * frameRate.toLong() / 6L)
            .coerceIn(1_000_000L, 12_000_000L)
            .toInt()
    }

    private fun emit(jobId: String, projectId: String?, type: String, payload: Map<String, Any?>) {
        eventEmitter.emit(NleNativeEvent(type = type, projectId = projectId, jobId = jobId, payload = payload))
    }
}

private data class TrackInfo(val index: Int, val format: MediaFormat)
private data class EncoderDrainState(
    val muxerStarted: Boolean,
    val videoTrackIndex: Int,
    val audioTrackIndex: Int,
    val encoderDone: Boolean,
)
private class ProxyCancellationToken { @Volatile var cancelled: Boolean = false }
private class ProxyCancelledException : RuntimeException("Proxy cancelled")

private fun MediaFormat.longValue(key: String): Long {
    return if (containsKey(key)) getLong(key) else 0L
}

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
