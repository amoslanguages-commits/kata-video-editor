package com.kata.videoeditor.nle.export

import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.min

internal data class NleEncodedAacSample(
    val data: ByteArray,
    val presentationTimeUs: Long,
    val flags: Int,
)

internal data class NleEncodedAacMixdown(
    val format: MediaFormat,
    val samples: List<NleEncodedAacSample>,
    val sampleRate: Int,
    val channels: Int,
    val durationUs: Long,
)

internal class NlePcmAudioMixdownRenderer {
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
        val totalFrames = ((durationUs.coerceAtLeast(1L) * safeSampleRate) / 1_000_000L + 1L).coerceAtLeast(1L)
        val totalSamples = totalFrames * safeChannels
        val maxSamples = 96_000_000L
        if (totalSamples > maxSamples) {
            throw IllegalStateException("Audio mixdown is too large for in-memory export: ${totalFrames} frames, $safeChannels channels.")
        }

        val mix = FloatArray(totalSamples.toInt())
        progress("Mixing audio", 86)
        plannedTracks.forEachIndexed { index, planned ->
            if (token.cancelled) throw NleExportCancelledException()
            mixPlannedTrack(
                planned = planned,
                mix = mix,
                outputSampleRate = safeSampleRate,
                outputChannels = safeChannels,
                totalFrames = totalFrames.toInt(),
                token = token,
            )
            val clipProgress = 86 + ((index + 1) * 3 / plannedTracks.size).coerceAtMost(3)
            progress("Mixing audio", clipProgress)
        }

        progress("Encoding audio mix", 90)
        return encodeAac(
            mix = mix,
            durationUs = durationUs,
            sampleRate = safeSampleRate,
            channels = safeChannels,
            bitrate = bitrate.coerceIn(64_000, 384_000),
            token = token,
        )
    }

    private fun mixPlannedTrack(
        planned: NlePlannedAudioTrack,
        mix: FloatArray,
        outputSampleRate: Int,
        outputChannels: Int,
        totalFrames: Int,
        token: NleExportCancellationToken,
    ) {
        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        try {
            extractor.setDataSource(planned.sourcePath)
            extractor.selectTrack(planned.sourceTrackIndex)
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
                        val size = extractor.readSampleData(inputBuffer, 0)
                        if (size < 0) {
                            activeDecoder.queueInputBuffer(inputIndex, 0, 0, 0L, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            activeDecoder.queueInputBuffer(
                                inputIndex,
                                0,
                                size,
                                extractor.sampleTime.coerceAtLeast(0L),
                                extractor.sampleFlags,
                            )
                            extractor.advance()
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
                            mixPcmBuffer(
                                planned = planned,
                                buffer = buffer,
                                bufferInfo = info,
                                sourceSampleRate = sourceSampleRate,
                                sourceChannels = sourceChannels,
                                pcmEncoding = pcmEncoding,
                                mix = mix,
                                outputSampleRate = outputSampleRate,
                                outputChannels = outputChannels,
                                totalFrames = totalFrames,
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

    private fun mixPcmBuffer(
        planned: NlePlannedAudioTrack,
        buffer: ByteBuffer,
        bufferInfo: MediaCodec.BufferInfo,
        sourceSampleRate: Int,
        sourceChannels: Int,
        pcmEncoding: Int,
        mix: FloatArray,
        outputSampleRate: Int,
        outputChannels: Int,
        totalFrames: Int,
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
            val outputFrame = ((timelineUs * outputSampleRate) / 1_000_000L).toInt()
            if (outputFrame !in 0 until totalFrames) continue

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

    private fun encodeAac(
        mix: FloatArray,
        durationUs: Long,
        sampleRate: Int,
        channels: Int,
        bitrate: Int,
        token: NleExportCancellationToken,
    ): NleEncodedAacMixdown {
        var encoder: MediaCodec? = null
        val samples = mutableListOf<NleEncodedAacSample>()
        var outputFormat: MediaFormat? = null
        try {
            val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, channels).apply {
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            }
            val activeEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            encoder = activeEncoder
            activeEncoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            activeEncoder.start()

            val info = MediaCodec.BufferInfo()
            val frameChunk = 1024
            val totalFrames = mix.size / channels.coerceAtLeast(1)
            var frameCursor = 0
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
                        val maxFramesForBuffer = (inputBuffer.remaining() / (channels.coerceAtLeast(1) * 2)).coerceAtLeast(0)
                        val framesToWrite = min(min(frameChunk, totalFrames - frameCursor), maxFramesForBuffer)
                        if (framesToWrite <= 0) {
                            val ptsUs = (frameCursor * 1_000_000L) / sampleRate.coerceAtLeast(1)
                            activeEncoder.queueInputBuffer(inputIndex, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            val bytesWritten = writePcm16ToBuffer(
                                mix = mix,
                                offsetFrame = frameCursor,
                                frameCount = framesToWrite,
                                channels = channels,
                                buffer = inputBuffer,
                            )
                            val ptsUs = (frameCursor * 1_000_000L) / sampleRate.coerceAtLeast(1)
                            activeEncoder.queueInputBuffer(inputIndex, 0, bytesWritten, ptsUs, 0)
                            frameCursor += framesToWrite
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
                            samples.add(NleEncodedAacSample(bytes, info.presentationTimeUs, info.flags))
                        }
                        outputDone = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                        activeEncoder.releaseOutputBuffer(outputIndex, false)
                    }
                }
            }
        } finally {
            try { encoder?.stop() } catch (_: Throwable) {}
            try { encoder?.release() } catch (_: Throwable) {}
        }

        val format = outputFormat ?: throw IllegalStateException("AAC encoder did not provide an output format.")
        return NleEncodedAacMixdown(
            format = format,
            samples = samples,
            sampleRate = sampleRate,
            channels = channels,
            durationUs = durationUs,
        )
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
