package com.nle.editor.audio

import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.roundToInt

object NlePcm16Writer {

    fun floatChunkToPcm16ByteBuffer(
        chunk: NlePcmChunk,
    ): ByteBuffer {
        val buffer = ByteBuffer
            .allocateDirect(chunk.data.size * 2)
            .order(ByteOrder.LITTLE_ENDIAN)

        for (sample in chunk.data) {
            val clamped = NleAudioMath.clampAudio(sample)
            val pcm = (clamped * 32767f).roundToInt()
                .coerceIn(-32768, 32767)
                .toShort()

            buffer.putShort(pcm)
        }

        buffer.flip()

        return buffer
    }
}
