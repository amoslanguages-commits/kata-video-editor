package com.nle.editor.audio

import com.nle.editor.rendergraph.NleRenderGraph

class NleAudioSourceCache(
    private val decoder: NleAudioAssetDecoder = NleAudioAssetDecoder(),
) {
    private val cache = linkedMapOf<String, NleDecodedAudioAsset>()

    fun prepare(
        graph: NleRenderGraph,
        useOriginalForExport: Boolean,
        targetSampleRate: Int,
        targetChannels: Int,
    ) {
        val usedAudioAssetIds = graph.tracks
            .asSequence()
            .flatMap { it.clips.asSequence() }
            .filter { !it.isDisabled }
            .filter { clip ->
                clip.type == "audio" || clip.type == "video"
            }
            .mapNotNull { it.assetId }
            .toSet()

        val assetMap = graph.assets.associateBy { it.id }

        for (assetId in usedAudioAssetIds) {
            if (cache.containsKey(assetId)) continue

            val asset = assetMap[assetId] ?: continue

            if (!asset.hasAudio) continue

            val path = if (useOriginalForExport) {
                asset.originalPath ?: asset.proxyPath
            } else {
                asset.proxyPath ?: asset.originalPath
            } ?: continue

            cache[assetId] = decoder.decodeAsset(
                assetId = assetId,
                filePath = path,
                targetSampleRate = targetSampleRate,
                targetChannels = targetChannels,
            )
        }
    }

    fun get(assetId: String): NleDecodedAudioAsset? {
        return cache[assetId]
    }

    fun clear() {
        cache.clear()
    }
}
