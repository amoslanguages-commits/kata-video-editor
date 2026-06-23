package com.nle.editor.audio

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import java.nio.ByteBuffer

class NleAacAudioEncoder(
    private val sampleRate: Int,
    private val channelCount: Int,
    private val bitRate: Int = 192_000,
) {
    private val codec: MediaCodec =
        MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)

    private val bufferInfo = MediaCodec.BufferInfo()

    private var started = false
    private var outputFormatEmitted = false

    fun start() {
        val format = MediaFormat.createAudioFormat(
            MediaFormat.MIMETYPE_AUDIO_AAC,
            sampleRate,
            channelCount,
        )

        format.setInteger(
            MediaFormat.KEY_AAC_PROFILE,
            MediaCodecInfo.CodecProfileLevel.AACObjectLC,
        )
        format.setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16 * 1024)

        codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        codec.start()
        started = true
    }

    fun queuePcmChunk(
        chunk: NlePcmChunk,
    ) {
        check(started) { "AAC encoder not started." }

        val pcmBuffer = NlePcm16Writer.floatChunkToPcm16ByteBuffer(chunk)

        while (pcmBuffer.hasRemaining()) {
            val inputIndex = codec.dequeueInputBuffer(10_000)

            if (inputIndex < 0) continue

            val input = codec.getInputBuffer(inputIndex)
                ?: error("AAC encoder input buffer missing.")

            input.clear()

            val size = minOf(input.remaining(), pcmBuffer.remaining())

            val slice = ByteArray(size)
            pcmBuffer.get(slice)

            input.put(slice)

            val frameOffsetBytes =
                pcmBuffer.position() - size

            val bytesPerFrame = channelCount * 2

            val frameOffset = frameOffsetBytes / bytesPerFrame

            val presentationTimeUs = chunk.startTimeUs +
                ((frameOffset.toDouble() / sampleRate.toDouble()) * 1_000_000.0).toLong()

            codec.queueInputBuffer(
                inputIndex,
                0,
                size,
                presentationTimeUs,
                0,
            )
        }
    }

    fun signalEndOfStream() {
        val inputIndex = codec.dequeueInputBuffer(10_000)

        if (inputIndex >= 0) {
            codec.queueInputBuffer(
                inputIndex,
                0,
                0,
                0L,
                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
            )
        }
    }

    fun drain(
        onFormat: (MediaFormat) -> Unit,
        onSample: (ByteBuffer, MediaCodec.BufferInfo) -> Unit,
    ): Boolean {
        check(started) { "AAC encoder not started." }

        var eos = false

        while (true) {
            val outputIndex = codec.dequeueOutputBuffer(bufferInfo, 0)

            when {
                outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    break
                }

                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (!outputFormatEmitted) {
                        outputFormatEmitted = true
                        onFormat(codec.outputFormat)
                    }
                }

                outputIndex >= 0 -> {
                    val output = codec.getOutputBuffer(outputIndex)

                    if (output != null && bufferInfo.size > 0) {
                        output.position(bufferInfo.offset)
                        output.limit(bufferInfo.offset + bufferInfo.size)

                        val copyInfo = MediaCodec.BufferInfo()
                        copyInfo.set(
                            0,
                            bufferInfo.size,
                            bufferInfo.presentationTimeUs,
                            bufferInfo.flags,
                        )

                        onSample(output, copyInfo)
                    }

                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        eos = true
                    }

                    codec.releaseOutputBuffer(outputIndex, false)
                }
            }
        }

        return eos
    }

    fun release() {
        runCatching {
            if (started) {
                codec.stop()
            }
        }

        codec.release()
        started = false
    }
}
