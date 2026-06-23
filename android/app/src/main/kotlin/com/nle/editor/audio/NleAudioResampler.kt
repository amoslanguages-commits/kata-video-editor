package com.nle.editor.audio

import kotlin.math.max

object NleAudioResampler {

    fun resample(
        source: NleDecodedAudioAsset,
        targetSampleRate: Int,
        targetChannelCount: Int,
    ): NleDecodedAudioAsset {
        if (source.frameCount <= 0) {
            return NleDecodedAudioAsset(
                assetId = source.assetId,
                sampleRate = targetSampleRate,
                channelCount = targetChannelCount,
                frameCount = 0,
                data = FloatArray(0),
            )
        }

        val durationSeconds = source.frameCount.toDouble() / source.sampleRate.toDouble()
        val targetFrameCount = max(1, (durationSeconds * targetSampleRate).toInt())
        val output = FloatArray(targetFrameCount * targetChannelCount)

        val temp = FloatArray(2)

        for (frame in 0 until targetFrameCount) {
            val timeUs = ((frame.toDouble() / targetSampleRate.toDouble()) * 1_000_000.0).toLong()

            source.sampleAtStereo(
                sourceTimeUs = timeUs,
                out = temp,
            )

            for (ch in 0 until targetChannelCount) {
                output[frame * targetChannelCount + ch] = when {
                    targetChannelCount == 1 -> (temp[0] + temp[1]) * 0.5f
                    ch == 0 -> temp[0]
                    ch == 1 -> temp[1]
                    else -> 0f
                }
            }
        }

        return NleDecodedAudioAsset(
            assetId = source.assetId,
            sampleRate = targetSampleRate,
            channelCount = targetChannelCount,
            frameCount = targetFrameCount,
            data = output,
        )
    }
}
