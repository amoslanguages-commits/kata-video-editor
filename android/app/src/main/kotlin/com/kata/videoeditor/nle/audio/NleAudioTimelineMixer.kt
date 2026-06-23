package com.kata.videoeditor.nle.audio

import com.kata.videoeditor.nle.NleExportProfile
import com.kata.videoeditor.nle.NleNativeErrorCode
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.roundToInt

class NleAudioTimelineMixer {
    private val decoder = NleAudioDecoder()
    private val resampler = NlePcmResampler()

    fun mix(
        timeline: NleAudioTimeline,
        profile: NleExportProfile,
        cancelled: AtomicBoolean,
        onProgress: (Int, String) -> Unit,
    ): NleMixedPcm {
        try {
            val sampleRate = profile.audioSampleRate
            val channels = profile.audioChannels

            val frameCount = ((timeline.durationMicros.toDouble() / 1_000_000.0) *
                sampleRate.toDouble()).roundToInt().coerceAtLeast(1)

            val mix = FloatArray(frameCount * channels)

            if (!timeline.hasAudio) {
                return NleMixedPcm(
                    sampleRate = sampleRate,
                    channelCount = channels,
                    samples = ShortArray(frameCount * channels)
                )
            }

            timeline.clips.forEachIndexed { index, clip ->
                if (cancelled.get()) {
                    throw InterruptedException(NleNativeErrorCode.EXPORT_CANCELLED)
                }

                onProgress(
                    (5 + (index.toDouble() / timeline.clips.size.toDouble()) * 40.0).roundToInt(),
                    "Decoding audio ${index + 1}/${timeline.clips.size}"
                )

                val decoded = decoder.decodeClip(clip)

                val normalized = resampler.toTarget(
                    input = decoded,
                    targetSampleRate = sampleRate,
                    targetChannels = channels
                )

                mixClip(
                    mix = mix,
                    outputFrameCount = frameCount,
                    channels = channels,
                    sampleRate = sampleRate,
                    clip = clip,
                    source = normalized
                )
            }

            onProgress(50, "Finalizing audio mix")

            val output = ShortArray(mix.size)

            for (i in mix.indices) {
                val clipped = mix[i].coerceIn(-1f, 1f)
                output[i] = (clipped * Short.MAX_VALUE).toInt()
                    .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                    .toShort()
            }

            return NleMixedPcm(
                sampleRate = sampleRate,
                channelCount = channels,
                samples = output
            )
        } catch (e: InterruptedException) {
            throw e
        } catch (e: Throwable) {
            throw RuntimeException(
                "${NleNativeErrorCode.AUDIO_EXPORT_MIX_FAILED}: ${e.message}",
                e
            )
        }
    }

    private fun mixClip(
        mix: FloatArray,
        outputFrameCount: Int,
        channels: Int,
        sampleRate: Int,
        clip: NleAudioClip,
        source: NleDecodedPcm,
    ) {
        val targetStartFrame = ((clip.timelineStartMicros.toDouble() / 1_000_000.0) *
            sampleRate.toDouble()).roundToInt().coerceAtLeast(0)

        val maxClipFrames = ((clip.durationMicros.toDouble() / 1_000_000.0) *
            sampleRate.toDouble()).roundToInt().coerceAtLeast(0)

        val framesToMix = minOf(
            maxClipFrames,
            source.frameCount,
            outputFrameCount - targetStartFrame
        ).coerceAtLeast(0)

        for (frame in 0 until framesToMix) {
            val timelineFrame = targetStartFrame + frame
            val timelineMicros =
                ((timelineFrame.toDouble() / sampleRate.toDouble()) * 1_000_000.0).toLong()

            val gain = clip.gainAtTimelineTime(timelineMicros)

            for (ch in 0 until channels) {
                val sourceIndex = frame * channels + ch
                val targetIndex = timelineFrame * channels + ch

                if (sourceIndex >= source.samples.size || targetIndex >= mix.size) continue

                mix[targetIndex] += (source.samples[sourceIndex].toFloat() / Short.MAX_VALUE.toFloat()) * gain
            }
        }
    }
}
