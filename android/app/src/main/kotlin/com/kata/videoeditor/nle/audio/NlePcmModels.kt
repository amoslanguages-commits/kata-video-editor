package com.kata.videoeditor.nle.audio

data class NleDecodedPcm(
    val sampleRate: Int,
    val channelCount: Int,
    val samples: ShortArray,
) {
    val frameCount: Int
        get() = samples.size / channelCount
}

data class NleMixedPcm(
    val sampleRate: Int,
    val channelCount: Int,
    val samples: ShortArray,
) {
    val frameCount: Int
        get() = samples.size / channelCount

    val durationMicros: Long
        get() = ((frameCount.toDouble() / sampleRate.toDouble()) * 1_000_000.0).toLong()
}
