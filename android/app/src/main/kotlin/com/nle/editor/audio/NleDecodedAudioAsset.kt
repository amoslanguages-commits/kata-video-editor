package com.nle.editor.audio

data class NleDecodedAudioAsset(
    val assetId: String,
    val sampleRate: Int,
    val channelCount: Int,
    val frameCount: Int,
    val data: FloatArray,
) {
    fun sampleAt(
        sourceTimeUs: Long,
        outputChannel: Int,
    ): Float {
        if (frameCount <= 0) return 0f

        val exactFrame = (sourceTimeUs.toDouble() / 1_000_000.0) * sampleRate.toDouble()
        val frame0 = exactFrame.toInt().coerceIn(0, frameCount - 1)
        val frame1 = (frame0 + 1).coerceIn(0, frameCount - 1)
        val t = (exactFrame - frame0.toDouble()).toFloat()

        val channel = outputChannel.coerceIn(0, channelCount - 1)

        val s0 = data[frame0 * channelCount + channel]
        val s1 = data[frame1 * channelCount + channel]

        return s0 + (s1 - s0) * t
    }

    fun sampleAtStereo(
        sourceTimeUs: Long,
        out: FloatArray,
    ) {
        when (channelCount) {
            1 -> {
                val mono = sampleAt(sourceTimeUs, 0)
                out[0] = mono
                out[1] = mono
            }

            else -> {
                out[0] = sampleAt(sourceTimeUs, 0)
                out[1] = sampleAt(sourceTimeUs, 1)
            }
        }
    }
}
