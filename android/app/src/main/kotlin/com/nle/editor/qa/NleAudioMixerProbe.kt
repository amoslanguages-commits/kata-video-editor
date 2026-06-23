package com.nle.editor.qa

import com.nle.editor.audio.NleAudioLayerResolver
import com.nle.editor.rendergraph.NleRenderGraph

data class NleAudioProbeLayer(
    val trackId: String,
    val trackName: String,
    val clipId: String,
    val clipName: String,
    val assetId: String,
    val volume: Float,
    val fadeInUs: Long,
    val fadeOutUs: Long,
)

data class NleAudioProbeResult(
    val windowStartUs: Long,
    val windowEndUs: Long,
    val activeAudioTrackIds: List<String>,
    val mutedAudioTrackIds: List<String>,
    val hasSoloAudio: Boolean,
    val layers: List<NleAudioProbeLayer>,
)

class NleAudioMixerProbe {

    private val resolver = NleAudioLayerResolver()

    fun probe(
        graph: NleRenderGraph,
        windowStartUs: Long,
        windowEndUs: Long,
    ): NleAudioProbeResult {
        val layers = resolver.resolveWindow(
            graph = graph,
            windowStartUs = windowStartUs,
            windowEndUs = windowEndUs,
        ).map { layer ->
            NleAudioProbeLayer(
                trackId = layer.track.id,
                trackName = layer.track.name,
                clipId = layer.clip.id,
                clipName = layer.clip.name,
                assetId = layer.asset.id,
                volume = layer.volume,
                fadeInUs = layer.fadeInUs,
                fadeOutUs = layer.fadeOutUs,
            )
        }

        return NleAudioProbeResult(
            windowStartUs = windowStartUs,
            windowEndUs = windowEndUs,
            activeAudioTrackIds = graph.audioMix.activeAudioTrackIds,
            mutedAudioTrackIds = graph.audioMix.mutedAudioTrackIds,
            hasSoloAudio = graph.audioMix.hasSoloAudio,
            layers = layers,
        )
    }
}
