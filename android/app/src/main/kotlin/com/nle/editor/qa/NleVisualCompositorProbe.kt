package com.nle.editor.qa

import com.nle.editor.rendergraph.NleRenderGraph
import com.nle.editor.rendergraph.NleVisualLayerResolver

data class NleVisualProbeLayer(
    val trackId: String,
    val trackName: String,
    val clipId: String,
    val clipName: String,
    val type: String,
    val layerIndex: Int,
    val sourceTimeUs: Long,
)

data class NleVisualProbeResult(
    val timelineTimeUs: Long,
    val layers: List<NleVisualProbeLayer>,
)

class NleVisualCompositorProbe {

    private val resolver = NleVisualLayerResolver()

    fun probe(
        graph: NleRenderGraph,
        timelineTimeUs: Long,
    ): NleVisualProbeResult {
        val layers = resolver.resolve(
            graph = graph,
            timelineTimeUs = timelineTimeUs,
        ).map { layer ->
            NleVisualProbeLayer(
                trackId = layer.track.id,
                trackName = layer.track.name,
                clipId = layer.clip.id,
                clipName = layer.clip.name,
                type = layer.clip.type,
                layerIndex = layer.layerIndex,
                sourceTimeUs = layer.sourceTimeUs,
            )
        }

        return NleVisualProbeResult(
            timelineTimeUs = timelineTimeUs,
            layers = layers,
        )
    }
}
