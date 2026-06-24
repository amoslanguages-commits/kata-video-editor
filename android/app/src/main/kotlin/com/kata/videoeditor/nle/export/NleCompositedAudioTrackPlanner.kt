package com.kata.videoeditor.nle.export

import android.media.MediaExtractor
import android.media.MediaFormat
import com.nle.editor.rendergraph.NleRenderGraph
import com.nle.editor.rendergraph.NleRenderAsset
import com.nle.editor.rendergraph.NleRenderClip
import com.nle.editor.rendergraph.NleRenderTrack

internal data class NlePlannedAudioTrack(
    val clip: NleRenderClip,
    val sourcePath: String,
    val sourceTrackIndex: Int,
    val format: MediaFormat,
)

internal class NleCompositedAudioTrackPlanner {
    fun plan(graph: NleRenderGraph, preferProxy: Boolean): List<NlePlannedAudioTrack> {
        val audioTracks = graph.tracks.filter { track ->
            !track.isMuted && !track.isHidden && (track.isAudio || track.type == "audio" || track.trackType == "audio")
        }
        if (audioTracks.isEmpty()) return emptyList()
        val assetsById = graph.assets.associateBy { it.id }
        val planned = mutableListOf<NlePlannedAudioTrack>()

        for (track in orderedAudioTracks(audioTracks)) {
            for (clip in track.clips.sortedBy { it.timelineStartUs }) {
                if (clip.isDisabled) continue
                val assetId = clip.assetId ?: continue
                val asset = assetsById[assetId] ?: continue
                if (!asset.hasAudio) continue
                val chosenPath = resolveAssetPath(asset, preferProxy) ?: continue
                val audioTrack = firstAudioTrack(chosenPath) ?: continue
                planned.add(
                    NlePlannedAudioTrack(
                        clip = clip,
                        sourcePath = chosenPath,
                        sourceTrackIndex = audioTrack.first,
                        format = audioTrack.second,
                    )
                )
            }
        }
        return planned
    }

    private fun resolveAssetPath(asset: NleRenderAsset, preferProxy: Boolean): String? {
        if (preferProxy) {
            asset.proxyPath?.takeIf { it.isNotBlank() }?.let { return it }
            if (asset.usedProxy) asset.resolvedPath?.takeIf { it.isNotBlank() }?.let { return it }
            asset.projectPath?.takeIf { it.isNotBlank() }?.let { return it }
            asset.originalPath?.takeIf { it.isNotBlank() }?.let { return it }
            return asset.resolvedPath?.takeIf { it.isNotBlank() }
        }

        asset.resolvedPath?.takeIf { it.isNotBlank() }?.let { return it }
        asset.projectPath?.takeIf { it.isNotBlank() }?.let { return it }
        asset.originalPath?.takeIf { it.isNotBlank() }?.let { return it }
        return asset.proxyPath?.takeIf { it.isNotBlank() }
    }

    private fun orderedAudioTracks(tracks: List<NleRenderTrack>): List<NleRenderTrack> {
        val solo = tracks.filter { it.isSolo }
        return (solo.ifEmpty { tracks }).sortedBy { it.sortOrder }
    }

    private fun firstAudioTrack(path: String): Pair<Int, MediaFormat>? {
        val extractor = MediaExtractor()
        return try {
            extractor.setDataSource(path)
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("audio/")) return i to format
            }
            null
        } finally {
            try { extractor.release() } catch (_: Throwable) {}
        }
    }
}
