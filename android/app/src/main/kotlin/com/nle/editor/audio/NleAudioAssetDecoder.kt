package com.nle.editor.audio

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.max

class NleAudioAssetDecoder {

    fun decodeAsset(
        assetId: String,
        filePath: String,
        targetSampleRate: Int = 48000,
        targetChannels: Int = 2,
    ): NleDecodedAudioAsset {
        val extractor = MediaExtractor()

        try {
            extractor.setDataSource(filePath)

            val trackIndex = selectAudioTrack(extractor)

            if (trackIndex < 0) {
                return NleDecodedAudioAsset(
                    assetId = assetId,
                    sampleRate = targetSampleRate,
                    channelCount = targetChannels,
                    frameCount = 0,
                    data = FloatArray(0),
                )
            }

            extractor.selectTrack(trackIndex)

            val inputFormat = extractor.getTrackFormat(trackIndex)
            val mime = inputFormat.getString(MediaFormat.KEY_MIME)
                ?: error("Audio mime missing for $filePath")

            val codec = MediaCodec.createDecoderByType(mime)

            codec.configure(
                inputFormat,
                null,
                null,
                0,
            )

            codec.start()

            val decoded = decodeCodecToFloatPcm(
                extractor = extractor,
                codec = codec,
                assetId = assetId,
                fallbackSampleRate = inputFormat.getIntegerOrDefault(
                    MediaFormat.KEY_SAMPLE_RATE,
                    targetSampleRate,
                ),
                fallbackChannels = inputFormat.getIntegerOrDefault(
                    MediaFormat.KEY_CHANNEL_COUNT,
                    targetChannels,
                ),
            )

            codec.stop()
            codec.release()

            if (decoded.sampleRate == targetSampleRate &&
                decoded.channelCount == targetChannels
            ) {
                return decoded
            }

            return NleAudioResampler.resample(
                source = decoded,
                targetSampleRate = targetSampleRate,
                targetChannelCount = targetChannels,
            )
        } finally {
            extractor.release()
        }
    }

    private fun decodeCodecToFloatPcm(
        extractor: MediaExtractor,
        codec: MediaCodec,
        assetId: String,
        fallbackSampleRate: Int,
        fallbackChannels: Int,
    ): NleDecodedAudioAsset {
        val bufferInfo = MediaCodec.BufferInfo()
        val chunks = ArrayList<FloatArray>()

        var sampleRate = fallbackSampleRate
        var channelCount = fallbackChannels
        var sawInputEos = false
        var sawOutputEos = false

        while (!sawOutputEos) {
            if (!sawInputEos) {
                val inputIndex = codec.dequeueInputBuffer(10_000)

                if (inputIndex >= 0) {
                    val inputBuffer = codec.getInputBuffer(inputIndex)

                    val sampleSize = if (inputBuffer != null) {
                        extractor.readSampleData(inputBuffer, 0)
                    } else {
                        -1
                    }

                    if (sampleSize < 0) {
                        codec.queueInputBuffer(
                            inputIndex,
                            0,
                            0,
                            0L,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                        )
                        sawInputEos = true
                    } else {
                        val presentationTimeUs = extractor.sampleTime

                        codec.queueInputBuffer(
                            inputIndex,
                            0,
                            sampleSize,
                            presentationTimeUs,
                            0,
                        )

                        extractor.advance()
                    }
                }
            }

            val outputIndex = codec.dequeueOutputBuffer(bufferInfo, 10_000)

            when {
                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val outputFormat = codec.outputFormat

                    sampleRate = outputFormat.getIntegerOrDefault(
                        MediaFormat.KEY_SAMPLE_RATE,
                        sampleRate,
                    )

                    channelCount = outputFormat.getIntegerOrDefault(
                        MediaFormat.KEY_CHANNEL_COUNT,
                        channelCount,
                    )
                }

                outputIndex >= 0 -> {
                    val outputBuffer = codec.getOutputBuffer(outputIndex)

                    if (outputBuffer != null && bufferInfo.size > 0) {
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)

                        chunks.add(
                            pcm16ByteBufferToFloatArray(
                                buffer = outputBuffer,
                                channelCount = channelCount,
                            )
                        )
                    }

                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        sawOutputEos = true
                    }

                    codec.releaseOutputBuffer(outputIndex, false)
                }
            }
        }

        val totalSamples = chunks.sumOf { it.size }
        val merged = FloatArray(totalSamples)
        var offset = 0

        for (chunk in chunks) {
            System.arraycopy(chunk, 0, merged, offset, chunk.size)
            offset += chunk.size
        }

        val frameCount = if (channelCount <= 0) {
            0
        } else {
            merged.size / channelCount
        }

        return NleDecodedAudioAsset(
            assetId = assetId,
            sampleRate = sampleRate,
            channelCount = max(1, channelCount),
            frameCount = frameCount,
            data = merged,
        )
    }

    private fun pcm16ByteBufferToFloatArray(
        buffer: ByteBuffer,
        channelCount: Int,
    ): FloatArray {
        val ordered = buffer.order(ByteOrder.LITTLE_ENDIAN)
        val sampleCount = ordered.remaining() / 2
        val output = FloatArray(sampleCount)

        for (i in 0 until sampleCount) {
            val sample = ordered.short
            output[i] = sample / 32768f
        }

        return output
    }

    private fun selectAudioTrack(extractor: MediaExtractor): Int {
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

private fun MediaFormat.getIntegerOrDefault(
    key: String,
    defaultValue: Int,
): Int {
    return if (containsKey(key)) {
        getInteger(key)
    } else {
        defaultValue
    }
}
