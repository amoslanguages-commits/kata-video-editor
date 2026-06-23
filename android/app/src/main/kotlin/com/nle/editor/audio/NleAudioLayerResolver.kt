package com.nle.editor.audio

import com.nle.editor.rendergraph.NleRenderAsset
import com.nle.editor.rendergraph.NleRenderClip
import com.nle.editor.rendergraph.NleRenderGraph
import com.nle.editor.rendergraph.NleRenderTrack

class NleAudioLayerResolver {

    fun resolveWindow(
        graph: NleRenderGraph,
        windowStartUs: Long,
        windowEndUs: Long,
    ): List<NleResolvedAudioLayer> {
        if (!graph.audioMix.enabled) return emptyList()

        val assetMap = graph.assets.associateBy { it.id }
        val activeAudioTrackIds = graph.audioMix.activeAudioTrackIds.toSet()
        val mutedAudioTrackIds = graph.audioMix.mutedAudioTrackIds.toSet()

        val layers = mutableListOf<NleResolvedAudioLayer>()

        val candidateTracks = graph.tracks
            .filter { track ->
                track.isAudio || trackHasVideoWithAudio(track, assetMap)
            }
            .sortedWith(
                compareBy<NleRenderTrack> { if (it.isAudio) 0 else 1 }
                    .thenBy { it.layerOrder }
                    .thenBy { it.sortOrder }
            )

        for (track in candidateTracks) {
            val isDedicatedAudioTrack = track.isAudio

            if (track.isMuted) continue
            if (mutedAudioTrackIds.contains(track.id)) continue

            if (isDedicatedAudioTrack && activeAudioTrackIds.isNotEmpty()) {
                if (!activeAudioTrackIds.contains(track.id)) continue
            }

            if (!isDedicatedAudioTrack && track.isVisual) {
                // For embedded video audio, visual mute means "do not render/emit".
                if (track.isHidden || track.isMuted) continue
            }

            val clips = track.clips
                .filter { !it.isDisabled }
                .filter { clipProducesAudio(it, assetMap) }
                .filter { clip ->
                    clip.timelineEndUs > windowStartUs &&
                        clip.timelineStartUs < windowEndUs
                }
                .sortedBy { it.timelineStartUs }

            for (clip in clips) {
                val assetId = clip.assetId ?: continue
                val asset = assetMap[assetId] ?: continue

                layers.add(
                    NleResolvedAudioLayer(
                        track = track,
                        clip = clip,
                        asset = asset,
                        timelineStartUs = clip.timelineStartUs,
                        timelineEndUs = clip.timelineEndUs,
                        sourceStartUs = clip.sourceStartUs,
                        sourceEndUs = clip.sourceEndUs,
                        volume = clip.audio.volume.toFloat().coerceIn(0f, 2f),
                        fadeInUs = clip.audio.fadeInUs.coerceAtLeast(0L),
                        fadeOutUs = clip.audio.fadeOutUs.coerceAtLeast(0L),
                        layerIndex = layers.size,
                    )
                )
            }
        }

        return layers
    }

    private fun trackHasVideoWithAudio(
        track: NleRenderTrack,
        assetMap: Map<String, NleRenderAsset>,
    ): Boolean {
        if (!track.isVisual) return false

        return track.clips.any { clip ->
            clip.type == "video" &&
                clip.assetId != null &&
                assetMap[clip.assetId]?.hasAudio == true
        }
    }

    private fun clipProducesAudio(
        clip: NleRenderClip,
        assetMap: Map<String, NleRenderAsset>,
    ): Boolean {
        val type = clip.type.lowercase()

        if (type == "audio") return true

        if (type == "video") {
            val assetId = clip.assetId ?: return false
            return assetMap[assetId]?.hasAudio == true
        }

        return false
    }
}
