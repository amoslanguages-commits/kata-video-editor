package com.nle.editor.audio

import kotlin.math.max
import kotlin.math.min

object NleAudioMath {

    fun timelineUsToFrame(
        timeUs: Long,
        sampleRate: Int,
    ): Long {
        return ((timeUs.toDouble() / 1_000_000.0) * sampleRate).toLong()
    }

    fun frameToTimelineUs(
        frame: Long,
        sampleRate: Int,
    ): Long {
        return ((frame.toDouble() / sampleRate.toDouble()) * 1_000_000.0).toLong()
    }

    fun gainForLayerAtTimelineTime(
        layer: NleResolvedAudioLayer,
        timelineTimeUs: Long,
    ): Float {
        val localUs = timelineTimeUs - layer.timelineStartUs
        val clipDurationUs = max(1L, layer.timelineEndUs - layer.timelineStartUs)

        var gain = layer.volume

        if (layer.fadeInUs > 0L && localUs < layer.fadeInUs) {
            gain *= (localUs.toFloat() / layer.fadeInUs.toFloat()).coerceIn(0f, 1f)
        }

        if (layer.fadeOutUs > 0L) {
            val fadeOutStart = clipDurationUs - layer.fadeOutUs

            if (localUs > fadeOutStart) {
                val remaining = clipDurationUs - localUs
                gain *= (remaining.toFloat() / layer.fadeOutUs.toFloat()).coerceIn(0f, 1f)
            }
        }

        return gain.coerceIn(0f, 2f)
    }

    fun softClip(value: Float): Float {
        return when {
            value > 1f -> 1f - (1f / (value + 1f))
            value < -1f -> -1f + (1f / (-value + 1f))
            else -> value
        }
    }

    fun clampAudio(value: Float): Float {
        return min(1f, max(-1f, value))
    }
}
