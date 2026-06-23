package com.kata.videoeditor.nle.audio

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import com.kata.videoeditor.nle.NleExportProfile
import com.kata.videoeditor.nle.NleNativeErrorCode
import java.io.File
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicBoolean

class NleAacEncoder {
    fun encodeToM4a(
        pcm: NleMixedPcm,
        outputPath: String,
        profile: NleExportProfile,
        cancelled: AtomicBoolean,
        onProgress: (Int, String) -> Unit,
    ): String {
        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()

        if (outputFile.exists()) {
            outputFile.delete()
        }

        var encoder: MediaCodec? = null
        var muxer: MediaMuxer? = null

        var muxerStarted = false
        var audioTrackIndex = -1

        val bufferInfo = MediaCodec.BufferInfo()

        try {
            val format = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_AAC,
                pcm.sampleRate,
                pcm.channelCount
            )

            format.setInteger(
                MediaFormat.KEY_AAC_PROFILE,
                MediaCodecInfo.CodecProfileLevel.AACObjectLC
            )
            format.setInteger(MediaFormat.KEY_BIT_RATE, profile.audioBitrate)
            format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16 * 1024)

            encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            encoder.start()

            muxer = MediaMuxer(
                outputPath,
                MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
            )

            var inputSampleOffset = 0
            var inputDone = false
            var outputDone = false

            val samplesPerInputChunk = 1024 * pcm.channelCount

            while (!outputDone) {
                if (cancelled.get()) {
                    throw InterruptedException(NleNativeErrorCode.EXPORT_CANCELLED)
                }

                if (!inputDone) {
                    val inputIndex = encoder.dequeueInputBuffer(10_000)

                    if (inputIndex >= 0) {
                        val inputBuffer = encoder.getInputBuffer(inputIndex)

                        if (inputBuffer == null) {
                            encoder.queueInputBuffer(
                                inputIndex,
                                0,
                                0,
                                0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            inputDone = true
                        } else {
                            inputBuffer.clear()
                            inputBuffer.order(ByteOrder.LITTLE_ENDIAN)

                            val remainingSamples = pcm.samples.size - inputSampleOffset
                            val samplesThisChunk =
                                minOf(samplesPerInputChunk, remainingSamples).coerceAtLeast(0)

                            if (samplesThisChunk <= 0) {
                                encoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    0,
                                    presentationTimeUsForSample(
                                        inputSampleOffset,
                                        pcm.sampleRate,
                                        pcm.channelCount
                                    ),
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM
                                )
                                inputDone = true
                            } else {
                                for (i in 0 until samplesThisChunk) {
                                    inputBuffer.putShort(pcm.samples[inputSampleOffset + i])
                                }

                                val ptsUs = presentationTimeUsForSample(
                                    inputSampleOffset,
                                    pcm.sampleRate,
                                    pcm.channelCount
                                )

                                encoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    samplesThisChunk * 2,
                                    ptsUs,
                                    0
                                )

                                inputSampleOffset += samplesThisChunk

                                val progress = 55 + ((inputSampleOffset.toDouble() /
                                    pcm.samples.size.toDouble()) * 25.0).toInt()

                                onProgress(progress.coerceIn(55, 80), "Encoding AAC audio")
                            }
                        }
                    }
                }

                val outputIndex = encoder.dequeueOutputBuffer(bufferInfo, 10_000)

                when {
                    outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        // continue
                    }

                    outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        if (muxerStarted) {
                            throw IllegalStateException("Audio format changed twice.")
                        }

                        val outputFormat = encoder.outputFormat
                        audioTrackIndex = muxer.addTrack(outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }

                    outputIndex >= 0 -> {
                        val encodedData = encoder.getOutputBuffer(outputIndex)
                            ?: throw IllegalStateException("AAC output buffer was null.")

                        if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                            bufferInfo.size = 0
                        }

                        if (bufferInfo.size > 0) {
                            if (!muxerStarted) {
                                throw IllegalStateException("Muxer has not started.")
                            }

                            encodedData.position(bufferInfo.offset)
                            encodedData.limit(bufferInfo.offset + bufferInfo.size)

                            muxer.writeSampleData(
                                audioTrackIndex,
                                encodedData,
                                bufferInfo
                            )
                        }

                        val end =
                            bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0

                        encoder.releaseOutputBuffer(outputIndex, false)

                        if (end) {
                            outputDone = true
                        }
                    }
                }
            }

            onProgress(82, "AAC audio ready")

            if (!outputFile.exists() || outputFile.length() <= 0L) {
                throw IllegalStateException(NleNativeErrorCode.AUDIO_EXPORT_ENCODE_FAILED)
            }

            return outputPath
        } catch (e: InterruptedException) {
            outputFile.delete()
            throw e
        } catch (e: Throwable) {
            outputFile.delete()
            throw RuntimeException(
                "${NleNativeErrorCode.AUDIO_EXPORT_ENCODE_FAILED}: ${e.message}",
                e
            )
        } finally {
            try {
                encoder?.stop()
            } catch (_: Throwable) {
            }

            try {
                encoder?.release()
            } catch (_: Throwable) {
            }

            try {
                if (muxerStarted) {
                    muxer?.stop()
                }
            } catch (_: Throwable) {
            }

            try {
                muxer?.release()
            } catch (_: Throwable) {
            }
        }
    }

    private fun presentationTimeUsForSample(
        sampleOffset: Int,
        sampleRate: Int,
        channelCount: Int,
    ): Long {
        val frameOffset = sampleOffset / channelCount
        return ((frameOffset.toDouble() / sampleRate.toDouble()) * 1_000_000.0).toLong()
    }
}
