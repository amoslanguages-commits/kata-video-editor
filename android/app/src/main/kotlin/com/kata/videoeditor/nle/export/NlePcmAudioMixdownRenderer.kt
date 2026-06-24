package com.kata.videoeditor.nle.export

import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.max
import kotlin.math.min

internal data class NleEncodedAacSample(
    val fileOffset: Long,
    val size: Int,
    val presentationTimeUs: Long,
    val flags: Int,
)

internal data class NleEncodedAacMixdown(
    val format: MediaFormat,
    val sampleFilePath: String,
    val samples: List<NleEncodedAacSample>,
    val sampleRate: Int,
    val channels: Int,
    val durationUs: Long,
) {
    fun deleteTempFile() {
        try { File(sampleFilePath).delete() } catch (_: Throwable) {}
    }
}

internal class NlePcmAudioMixdownRenderer {
    companion object {
        private const val MIX_WINDOW_US = 500_000L
    }

    fun mixToAac(
        plannedTracks: List<NlePlannedAudioTrack>,
        durationUs: Long,
        sampleRate: Int,
        channels: Int,
        bitrate: Int,
        token: NleExportCancellationToken,
        progress: (stage: String, progress: Int) -> Unit = { _, _ -> },
    ): NleEncodedAacMixdown? {
        if (plannedTracks.isEmpty()) return null
        val safeSampleRate = sampleRate.coerceIn(8_000, 192_000)
        val safeChannels = channels.coerceIn(1, 2)

        progress("Encoding audio mix", 90)
        return encodeAacStreaming(
            plannedTracks = plannedTracks,
            durationUs = durationUs,
            sampleRate = safeSampleRate,
            channels = safeChannels,
            bitrate = bitrate.coerceIn(64_000, 384_000),
            token = token,
            progress = progress,
        )
    }

    private fun encodeAacStreaming(
        plannedTracks: List<NlePlannedAudioTrack>,
        durationUs: Long,
        sampleRate: Int,
        channels: Int,
        bitrate: Int,
        token: NleExportCancellationToken,
        progress: (stage: String, progress: Int) -> Unit,
    ): NleEncodedAacMixdown {
        val sampleFile = File.createTempFile("nle-audio-mixdown-", ".aac")
        var encoder: MediaCodec? = null
        val samples = mutableListOf<NleEncodedAacSample>()
        var fileOffset = 0L
        var outputFormat: MediaFormat? = null

        try {
            FileOutputStream(sampleFile).use { sampleOutput ->
                val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, channels).apply {
                    setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                    setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
                }
                val activeEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
                encoder = activeEncoder
                activeEncoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                activeEncoder.start()

                val info = MediaCodec.BufferInfo()
                val safeChannels = channels.coerceAtLeast(1)

                // Window state tracking
                var windowStartUs = 0L
                var currentWindowMix: FloatArray? = null
                var currentWindowStartUs = 0L
                var currentWindowFrameCursor = 0
                var currentWindowTotalFrames = 0
                var inputDone = false
                var outputDone = false

                while (!outputDone) {
                    if (token.cancelled) throw NleExportCancelledException()

                    if (!inputDone) {
                        val inputIndex = activeEncoder.dequeueInputBuffer(10_000L)
                        if (inputIndex >= 0) {
                            val inputBuffer = activeEncoder.getInputBuffer(inputIndex)
                                ?: throw IllegalStateException("AAC encoder input buffer was null.")
                            inputBuffer.clear()

                            // Mix a new window if needed
                            if (currentWindowMix == null || currentWindowFrameCursor >= currentWindowTotalFrames) {
                                if (windowStartUs >= durationUs) {
                                    val ptsUs = (windowStartUs * sampleRate) / 1_000_000L
                                    activeEncoder.queueInputBuffer(inputIndex, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                    inputDone = true
                                    continue
                                } else {
                                    val windowEndUs = min(windowStartUs + MIX_WINDOW_US, durationUs)
                                    currentWindowMix = mixWindow(
                                        plannedTracks = plannedTracks,
                                        windowStartUs = windowStartUs,
                                        windowEndUs = windowEndUs,
                                        outputSampleRate = sampleRate,
                                        outputChannels = safeChannels,
                                        token = token,
                                    )
                                    currentWindowStartUs = windowStartUs
                                    currentWindowFrameCursor = 0
                                    currentWindowTotalFrames = currentWindowMix.size / safeChannels
                                    windowStartUs = windowEndUs
                                }
                            }

                            if (!inputDone) {
                                val mix = currentWindowMix ?: continue
                                val maxFramesForBuffer = (inputBuffer.remaining() / (safeChannels * 2)).coerceAtLeast(0)
                                val remainingFrames = currentWindowTotalFrames - currentWindowFrameCursor
                                val framesToWrite = min(remainingFrames, maxFramesForBuffer)

                                if (framesToWrite <= 0) {
                                    // No space; retry on next buffer dequeue
                                    continue
                                }

                                val bytesWritten = writePcm16ToBuffer(
                                    mix = mix,
                                    offsetFrame = currentWindowFrameCursor,
                                    frameCount = framesToWrite,
                                    channels = safeChannels,
                                    buffer = inputBuffer,
                                )
                                val ptsUs = currentWindowStartUs +
                                    (currentWindowFrameCursor * 1_000_000L / sampleRate.coerceAtLeast(1))
                                activeEncoder.queueInputBuffer(inputIndex, 0, bytesWritten, ptsUs, 0)
                                currentWindowFrameCursor += framesToWrite
                            }
                        }
                    }

                    when (val outputIndex = activeEncoder.dequeueOutputBuffer(info, 10_000L)) {
                        MediaCodec.INFO_TRY_AGAIN_LATER -> Unit
                        MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> outputFormat = activeEncoder.outputFormat
                        else -> if (outputIndex >= 0) {
                            val encodedBuffer = activeEncoder.getOutputBuffer(outputIndex)
                                ?: throw IllegalStateException("AAC encoder output buffer was null.")
                            if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 && info.size > 0) {
                                val bytes = ByteArray(info.size)
                                encodedBuffer.position(info.offset)
                                encodedBuffer.limit(info.offset + info.size)
                                encodedBuffer.get(bytes)
                                sampleOutput.write(bytes)
                                samples.add(
                                    NleEncodedAacSample(
                                        fileOffset = fileOffset,
                                        size = info.size,
                                        presentationTimeUs = info.presentationTimeUs,
                                        flags = info.flags,
                                    )
                                )
                                fileOffset += info.size
                            }
                            outputDone = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                            activeEncoder.releaseOutputBuffer(outputIndex, false)
                        }
                    }
                }
            }
        } catch (e: Throwable) {
            try { sampleFile.delete() } catch (_: Throwable) {}
            throw e
        } finally {
            try { encoder?.stop() } catch (_: Throwable) {}
            try { encoder?.release() } catch (_: Throwable) {}
        }

        val format = outputFormat ?: throw IllegalStateException("AAC encoder did not provide an output format.")
        return NleEncodedAacMixdown(
            format = format,
            sampleFilePath = sampleFile.absolutePath,
            samples = samples,
            sampleRate = sampleRate,
            channels = channels,
            durationUs = durationUs,
        )
    }

    private fun mixWindow(
        plannedTracks: List<NlePlannedAudioTrack>,
        windowStartUs: Long,
        windowEndUs: Long,
        outputSampleRate: Int,
        outputChannels: Int,
        token: NleExportCancellationToken,
    ): FloatArray {
        val windowDurationUs = (windowEndUs - windowStartUs).coerceAtLeast(1L)
        val windowFrames = ((windowDurationUs * outputSampleRate) / 1_000_000L + 1L).toInt()
        val windowSamples = windowFrames * outputChannels.coerceAtLeast(1)
        val mix = FloatArray(windowSamples)

        plannedTracks.forEach { planned ->
            if (token.cancelled) throw NleExportCancelledException()
            mixPlannedTrackWindow(
                planned = planned,
                windowStartUs = windowStartUs,
                windowEndUs = windowEndUs,
                mix = mix,
                outputSampleRate = outputSampleRate,
                outputChannels = outputChannels,
                token = token,
            )
        }

        return mix
    }

    private fun mixPlannedTrackWindow(
        planned: NlePlannedAudioTrack,
        windowStartUs: Long,
        windowEndUs: Long,
        mix: FloatArray,
        outputSampleRate: Int,
        outputChannels: Int,
        token: NleExportCancellationToken,
    ) {
        val clip = planned.clip
        val clipTimelineStartUs = clip.timelineStartUs
        val clipTimelineEndUs = clip.timelineEndUs

        // Compute timeline overlap between window and clip
        val overlapTimelineStartUs = max(windowStartUs, clipTimelineStartUs)
        val overlapTimelineEndUs = min(windowEndUs, clipTimelineEndUs)

        if (overlapTimelineEndUs <= overlapTimelineStartUs) return

        val safeSpeed = clip.speed.coerceAtLeast(0.01)

        // Map timeline overlap to source range
        val relativeTimelineStartUs = overlapTimelineStartUs - clipTimelineStartUs
        val relativeTimelineEndUs = overlapTimelineEndUs - clipTimelineStartUs

        val sourceWindowStartUs = (clip.sourceStartUs + (relativeTimelineStartUs * safeSpeed).toLong())
            .coerceIn(clip.sourceStartUs, clip.sourceEndUs)

        val sourceWindowEndUs = (clip.sourceStartUs + (relativeTimelineEndUs * safeSpeed).toLong())
            .coerceIn(clip.sourceStartUs, clip.sourceEndUs)

        if (sourceWindowEndUs <= sourceWindowStartUs) return

        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        try {
            extractor.setDataSource(planned.sourcePath)
            extractor.selectTrack(planned.sourceTrackIndex)
            
            // Seek directly to the relevant source range
            extractor.seekTo(
                sourceWindowStartUs.coerceAtLeast(0L),
                MediaExtractor.SEEK_TO_PREVIOUS_SYNC,
            )

            val inputFormat = extractor.getTrackFormat(planned.sourceTrackIndex)
            val mime = inputFormat.getString(MediaFormat.KEY_MIME)
                ?: throw IllegalStateException("Audio track mime is missing.")
            val activeDecoder = MediaCodec.createDecoderByType(mime)
            decoder = activeDecoder
            activeDecoder.configure(inputFormat, null, null, 0)
            activeDecoder.start()

            val info = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            var outputFormat = activeDecoder.outputFormat
            var sourceSampleRate = outputFormat.intValue(MediaFormat.KEY_SAMPLE_RATE, inputFormat.intValue(MediaFormat.KEY_SAMPLE_RATE, outputSampleRate))
            var sourceChannels = outputFormat.intValue(MediaFormat.KEY_CHANNEL_COUNT, inputFormat.intValue(MediaFormat.KEY_CHANNEL_COUNT, 2)).coerceAtLeast(1)
            var pcmEncoding = outputFormat.intValue(MediaFormat.KEY_PCM_ENCODING, AudioFormat.ENCODING_PCM_16BIT)

            while (!outputDone) {
                if (token.cancelled) throw NleExportCancelledException()

                if (!inputDone) {
                    val inputIndex = activeDecoder.dequeueInputBuffer(10_000L)
                    if (inputIndex >= 0) {
                        val inputBuffer = activeDecoder.getInputBuffer(inputIndex)
                            ?: throw IllegalStateException("Audio decoder input buffer was null.")
                        inputBuffer.clear()

                        val sampleTime = extractor.sampleTime
                        if (sampleTime < 0 || sampleTime > sourceWindowEndUs) {
                            activeDecoder.queueInputBuffer(
                                inputIndex,
                                0,
                                0,
                                0L,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                            )
                            inputDone = true
                        } else {
                            val size = extractor.readSampleData(inputBuffer, 0)
                            if (size < 0) {
                                activeDecoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    0,
                                    0L,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                                )
                                inputDone = true
                            } else {
                                activeDecoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    size,
                                    sampleTime.coerceAtLeast(0L),
                                    extractor.sampleFlags,
                                )
                                extractor.advance()
                            }
                        }
                    }
                }

                when (val outputIndex = activeDecoder.dequeueOutputBuffer(info, 10_000L)) {
                    MediaCodec.INFO_TRY_AGAIN_LATER -> Unit
                    MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        outputFormat = activeDecoder.outputFormat
                        sourceSampleRate = outputFormat.intValue(MediaFormat.KEY_SAMPLE_RATE, sourceSampleRate)
                        sourceChannels = outputFormat.intValue(MediaFormat.KEY_CHANNEL_COUNT, sourceChannels).coerceAtLeast(1)
                        pcmEncoding = outputFormat.intValue(MediaFormat.KEY_PCM_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
                    }
                    else -> if (outputIndex >= 0) {
                        val buffer = activeDecoder.getOutputBuffer(outputIndex)
                        if (buffer != null && info.size > 0) {
                            mixPcmBufferWindow(
                                planned = planned,
                                buffer = buffer,
                                bufferInfo = info,
                                sourceSampleRate = sourceSampleRate,
                                sourceChannels = sourceChannels,
                                pcmEncoding = pcmEncoding,
                                mix = mix,
                                outputSampleRate = outputSampleRate,
                                outputChannels = outputChannels,
                                windowStartUs = windowStartUs,
                                windowEndUs = windowEndUs,
                            )
                        }
                        outputDone = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                        activeDecoder.releaseOutputBuffer(outputIndex, false)
                    }
                }
            }
        } finally {
            try { decoder?.stop() } catch (_: Throwable) {}
            try { decoder?.release() } catch (_: Throwable) {}
            try { extractor.release() } catch (_: Throwable) {}
        }
    }

    private fun mixPcmBufferWindow(
        planned: NlePlannedAudioTrack,
        buffer: ByteBuffer,
        bufferInfo: MediaCodec.BufferInfo,
        sourceSampleRate: Int,
        sourceChannels: Int,
        pcmEncoding: Int,
        mix: FloatArray,
        outputSampleRate: Int,
        outputChannels: Int,
        windowStartUs: Long,
        windowEndUs: Long,
    ) {
        val duplicate = buffer.duplicate().order(ByteOrder.LITTLE_ENDIAN)
        duplicate.position(bufferInfo.offset)
        duplicate.limit(bufferInfo.offset + bufferInfo.size)

        val bytesPerSample = if (pcmEncoding == AudioFormat.ENCODING_PCM_FLOAT) 4 else 2
        val bytesPerFrame = bytesPerSample * sourceChannels.coerceAtLeast(1)
        if (bytesPerFrame <= 0) return
        val frameCount = bufferInfo.size / bytesPerFrame
        val clip = planned.clip
        val clipDurationUs = (clip.timelineEndUs - clip.timelineStartUs).coerceAtLeast(1L)
        val volume = clip.audio.volume.coerceIn(0.0, 4.0).toFloat()

        for (frame in 0 until frameCount) {
            val sourceUs = bufferInfo.presentationTimeUs + frame * 1_000_000L / sourceSampleRate.coerceAtLeast(1)
            if (sourceUs < clip.sourceStartUs) continue
            if (sourceUs > clip.sourceEndUs) break
            val relativeSourceUs = sourceUs - clip.sourceStartUs
            val timelineUs = clip.timelineStartUs + (relativeSourceUs / clip.speed.coerceAtLeast(0.01)).toLong()
            if (timelineUs < clip.timelineStartUs || timelineUs >= clip.timelineEndUs) continue

            if (timelineUs < windowStartUs || timelineUs >= windowEndUs) continue

            val windowRelativeUs = timelineUs - windowStartUs
            val outputFrame = ((windowRelativeUs * outputSampleRate) / 1_000_000L).toInt()
            if (outputFrame < 0 || outputFrame >= (mix.size / outputChannels.coerceAtLeast(1))) continue

            val elapsedUs = timelineUs - clip.timelineStartUs
            val remainingUs = clip.timelineEndUs - timelineUs
            val fadeGain = fadeGain(
                elapsedUs = elapsedUs,
                remainingUs = remainingUs,
                fadeInUs = clip.audio.fadeInUs,
                fadeOutUs = clip.audio.fadeOutUs,
                clipDurationUs = clipDurationUs,
            )
            val gain = volume * fadeGain
            if (gain <= 0f) continue

            for (outChannel in 0 until outputChannels) {
                val srcChannel = if (sourceChannels == 1) 0 else min(outChannel, sourceChannels - 1)
                val sample = readSample(
                    buffer = duplicate,
                    frame = frame,
                    channel = srcChannel,
                    channels = sourceChannels,
                    pcmEncoding = pcmEncoding,
                )
                val index = outputFrame * outputChannels + outChannel
                mix[index] = (mix[index] + sample * gain).coerceIn(-1.25f, 1.25f)
            }
        }
    }

    private fun readSample(
        buffer: ByteBuffer,
        frame: Int,
        channel: Int,
        channels: Int,
        pcmEncoding: Int,
    ): Float {
        return if (pcmEncoding == AudioFormat.ENCODING_PCM_FLOAT) {
            val byteIndex = (frame * channels + channel) * 4
            buffer.getFloat(buffer.position() + byteIndex).coerceIn(-1f, 1f)
        } else {
            val byteIndex = (frame * channels + channel) * 2
            buffer.getShort(buffer.position() + byteIndex) / 32768f
        }
    }

    private fun fadeGain(
        elapsedUs: Long,
        remainingUs: Long,
        fadeInUs: Long,
        fadeOutUs: Long,
        clipDurationUs: Long,
    ): Float {
        var gain = 1f
        if (fadeInUs > 0) {
            val effectiveFade = min(fadeInUs, clipDurationUs)
            gain *= (elapsedUs.toDouble() / effectiveFade.coerceAtLeast(1L).toDouble()).coerceIn(0.0, 1.0).toFloat()
        }
        if (fadeOutUs > 0) {
            val effectiveFade = min(fadeOutUs, clipDurationUs)
            gain *= (remainingUs.toDouble() / effectiveFade.coerceAtLeast(1L).toDouble()).coerceIn(0.0, 1.0).toFloat()
        }
        return gain.coerceIn(0f, 1f)
    }

    private fun writePcm16ToBuffer(
        mix: FloatArray,
        offsetFrame: Int,
        frameCount: Int,
        channels: Int,
        buffer: ByteBuffer,
    ): Int {
        val output = buffer.order(ByteOrder.LITTLE_ENDIAN)
        var written = 0
        for (frame in 0 until frameCount) {
            for (channel in 0 until channels) {
                val value = mix[(offsetFrame + frame) * channels + channel].coerceIn(-1f, 1f)
                output.putShort((value * 32767f).toInt().toShort())
                written += 2
            }
        }
        return written
    }
}

private fun MediaFormat.intValue(key: String, default: Int): Int {
    return if (containsKey(key)) getInteger(key) else default
}
