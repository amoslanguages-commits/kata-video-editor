package com.nle.editor.audio

import com.nle.editor.rendergraph.NleRenderGraph

class NleMixedPcmStream(
    private val graph: NleRenderGraph,
    private val mixer: NlePcmMixer,
    private val format: NleAudioMixFormat,
    private val chunkFrames: Int = 2048,
) {
    private var nextTimeUs: Long = 0L

    fun hasMore(): Boolean {
        return nextTimeUs < graph.project.durationUs
    }

    fun nextChunk(): NlePcmChunk? {
        if (!hasMore()) return null

        val remainingUs = graph.project.durationUs - nextTimeUs
        val maxFramesForRemaining =
            ((remainingUs.toDouble() / 1_000_000.0) * format.sampleRate).toInt()

        val frames = chunkFrames.coerceAtMost(maxFramesForRemaining.coerceAtLeast(1))

        val chunk = mixer.mixChunk(
            graph = graph,
            startTimeUs = nextTimeUs,
            frameCount = frames,
            format = format,
        )

        nextTimeUs += chunk.durationUs

        return chunk
    }

    fun reset() {
        nextTimeUs = 0L
    }
}
