package com.nle.editor.audio

import com.nle.editor.rendergraph.NleRenderAsset
import com.nle.editor.rendergraph.NleRenderClip
import com.nle.editor.rendergraph.NleRenderTrack

data class NleResolvedAudioLayer(
    val track: NleRenderTrack,
    val clip: NleRenderClip,
    val asset: NleRenderAsset,
    val timelineStartUs: Long,
    val timelineEndUs: Long,
    val sourceStartUs: Long,
    val sourceEndUs: Long,
    val volume: Float,
    val fadeInUs: Long,
    val fadeOutUs: Long,
    val layerIndex: Int,
)

data class NleAudioMixFormat(
    val sampleRate: Int = 48000,
    val channelCount: Int = 2,
) {
    val bytesPerSample: Int = 2
    val bytesPerFrame: Int = channelCount * bytesPerSample
}

data class NlePcmChunk(
    val startTimeUs: Long,
    val sampleRate: Int,
    val channelCount: Int,
    val frames: Int,
    val data: FloatArray,
) {
    val durationUs: Long
        get() = ((frames.toDouble() / sampleRate.toDouble()) * 1_000_000.0).toLong()
}
