package com.kata.videoeditor.nle.audio

import kotlin.math.roundToInt

class NlePcmResampler {
    fun toTarget(
        input: NleDecodedPcm,
        targetSampleRate: Int,
        targetChannels: Int,
    ): NleDecodedPcm {
        val stereo = toStereo(input)

        if (stereo.sampleRate == targetSampleRate && targetChannels == 2) {
            return stereo
        }

        val sourceFrames = stereo.frameCount
        val targetFrames = ((sourceFrames.toDouble() / stereo.sampleRate.toDouble()) *
            targetSampleRate.toDouble()).roundToInt().coerceAtLeast(0)

        val output = ShortArray(targetFrames * 2)

        for (i in 0 until targetFrames) {
            val srcPosition = i.toDouble() * stereo.sampleRate.toDouble() /
                targetSampleRate.toDouble()

            val srcIndex = srcPosition.toInt().coerceIn(0, sourceFrames - 1)
            val nextIndex = (srcIndex + 1).coerceIn(0, sourceFrames - 1)
            val frac = srcPosition - srcIndex.toDouble()

            val left = lerp(
                stereo.samples[srcIndex * 2].toFloat(),
                stereo.samples[nextIndex * 2].toFloat(),
                frac.toFloat()
            )

            val right = lerp(
                stereo.samples[srcIndex * 2 + 1].toFloat(),
                stereo.samples[nextIndex * 2 + 1].toFloat(),
                frac.toFloat()
            )

            output[i * 2] = left.toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
            output[i * 2 + 1] = right.toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
        }

        return if (targetChannels == 1) {
            toMono(
                NleDecodedPcm(
                    sampleRate = targetSampleRate,
                    channelCount = 2,
                    samples = output
                )
            )
        } else {
            NleDecodedPcm(
                sampleRate = targetSampleRate,
                channelCount = 2,
                samples = output
            )
        }
    }

    private fun toStereo(input: NleDecodedPcm): NleDecodedPcm {
        if (input.channelCount == 2) return input

        val frames = input.frameCount
        val output = ShortArray(frames * 2)

        for (i in 0 until frames) {
            val sample = input.samples[i]
            output[i * 2] = sample
            output[i * 2 + 1] = sample
        }

        return NleDecodedPcm(
            sampleRate = input.sampleRate,
            channelCount = 2,
            samples = output
        )
    }

    private fun toMono(input: NleDecodedPcm): NleDecodedPcm {
        if (input.channelCount == 1) return input

        val frames = input.frameCount
        val output = ShortArray(frames)

        for (i in 0 until frames) {
            val left = input.samples[i * 2].toInt()
            val right = input.samples[i * 2 + 1].toInt()
            output[i] = ((left + right) / 2).toShort()
        }

        return NleDecodedPcm(
            sampleRate = input.sampleRate,
            channelCount = 1,
            samples = output
        )
    }

    private fun lerp(
        a: Float,
        b: Float,
        t: Float,
    ): Float {
        return a + (b - a) * t
    }
}
