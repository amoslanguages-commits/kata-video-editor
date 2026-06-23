package com.nle.editor.audio

import com.nle.editor.rendergraph.NleRenderGraph

class NlePreviewAudioMixer(
    private val sourceCache: NleAudioSourceCache = NleAudioSourceCache(),
) {
    private var currentGraph: NleRenderGraph? = null
    private var mixer: NlePcmMixer? = null
    private var format = NleAudioMixFormat()

    fun updateGraph(
        graph: NleRenderGraph,
        useProxyForPreview: Boolean,
    ) {
        currentGraph = graph

        format = NleAudioMixFormat(
            sampleRate = graph.audioMix.sampleRate.coerceAtLeast(8000),
            channelCount = graph.audioMix.channels.coerceIn(1, 2),
        )

        sourceCache.clear()

        sourceCache.prepare(
            graph = graph,
            useOriginalForExport = !useProxyForPreview,
            targetSampleRate = format.sampleRate,
            targetChannels = format.channelCount,
        )

        mixer = NlePcmMixer(sourceCache)
    }

    fun mixPreviewChunk(
        startTimeUs: Long,
        frameCount: Int,
    ): NlePcmChunk? {
        val graph = currentGraph ?: return null
        val activeMixer = mixer ?: return null

        return activeMixer.mixChunk(
            graph = graph,
            startTimeUs = startTimeUs,
            frameCount = frameCount,
            format = format,
        )
    }

    fun release() {
        sourceCache.clear()
        currentGraph = null
        mixer = null
    }
}
