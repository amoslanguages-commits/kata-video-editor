package com.kata.videoeditor.nle.audio

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.nio.ByteOrder
import kotlin.math.min

class NleAudioDecoder {
    fun decodeClip(
        clip: NleAudioClip,
    ): NleDecodedPcm {
        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null

        val outputSamples = ArrayList<Short>(44100)

        try {
            extractor.setDataSource(clip.inputPath)

            val trackIndex = findAudioTrack(extractor)

            if (trackIndex < 0) {
                throw IllegalArgumentException("No audio track found.")
            }

            extractor.selectTrack(trackIndex)

            val inputFormat = extractor.getTrackFormat(trackIndex)
            val mime = inputFormat.getString(MediaFormat.KEY_MIME)
                ?: throw IllegalArgumentException("Missing audio mime.")

            val sourceSampleRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            val sourceChannelCount = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

            decoder = MediaCodec.createDecoderByType(mime)
            decoder.configure(inputFormat, null, null, 0)
            decoder.start()

            extractor.seekTo(
                clip.sourceInMicros.coerceAtLeast(0L),
                MediaExtractor.SEEK_TO_PREVIOUS_SYNC
            )

            val bufferInfo = MediaCodec.BufferInfo()

            var inputDone = false
            var outputDone = false

            while (!outputDone) {
                if (!inputDone) {
                    val inputIndex = decoder.dequeueInputBuffer(10_000)

                    if (inputIndex >= 0) {
                        val inputBuffer = decoder.getInputBuffer(inputIndex)

                        if (inputBuffer == null) {
                            decoder.queueInputBuffer(
                                inputIndex,
                                0,
                                0,
                                0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            inputDone = true
                        } else {
                            val sampleTime = extractor.sampleTime

                            if (sampleTime < 0 || sampleTime > clip.sourceOutMicros) {
                                decoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    0,
                                    0,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM
                                )
                                inputDone = true
                            } else {
                                val sampleSize = extractor.readSampleData(inputBuffer, 0)

                                if (sampleSize < 0) {
                                    decoder.queueInputBuffer(
                                        inputIndex,
                                        0,
                                        0,
                                        0,
                                        MediaCodec.BUFFER_FLAG_END_OF_STREAM
                                    )
                                    inputDone = true
                                } else {
                                    decoder.queueInputBuffer(
                                        inputIndex,
                                        0,
                                        sampleSize,
                                        sampleTime,
                                        0
                                    )
                                    extractor.advance()
                                }
                            }
                        }
                    }
                }

                val outputIndex = decoder.dequeueOutputBuffer(bufferInfo, 10_000)

                when {
                    outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        // keep polling
                    }

                    outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        // V1 keeps initial source format.
                        // Some decoders can change output format; production should update this.
                    }

                    outputIndex >= 0 -> {
                        val outputBuffer = decoder.getOutputBuffer(outputIndex)

                        if (outputBuffer != null && bufferInfo.size > 0) {
                            val pts = bufferInfo.presentationTimeUs

                            if (pts >= clip.sourceInMicros && pts <= clip.sourceOutMicros) {
                                outputBuffer.position(bufferInfo.offset)
                                outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                                outputBuffer.order(ByteOrder.LITTLE_ENDIAN)

                                val shortBuffer = outputBuffer.asShortBuffer()
                                val shortCount = shortBuffer.remaining()

                                val temp = ShortArray(shortCount)
                                shortBuffer.get(temp)

                                outputSamples.ensureCapacity(outputSamples.size + shortCount)
                                temp.forEach { outputSamples.add(it) }
                            }
                        }

                        val end =
                            bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0

                        decoder.releaseOutputBuffer(outputIndex, false)

                        if (end) {
                            outputDone = true
                        }
                    }
                }
            }

            return NleDecodedPcm(
                sampleRate = sourceSampleRate,
                channelCount = sourceChannelCount.coerceIn(1, 2),
                samples = outputSamples.toShortArray()
            )
        } catch (e: Throwable) {
            throw RuntimeException(
                "${com.kata.videoeditor.nle.NleNativeErrorCode.AUDIO_EXPORT_DECODE_FAILED}: ${e.message}",
                e
            )
        } finally {
            try {
                decoder?.stop()
            } catch (_: Throwable) {
            }

            try {
                decoder?.release()
            } catch (_: Throwable) {
            }

            try {
                extractor.release()
            } catch (_: Throwable) {
            }
        }
    }

    private fun findAudioTrack(extractor: MediaExtractor): Int {
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: continue

            if (mime.startsWith("audio/")) {
                return i
            }
        }

        return -1
    }
}
