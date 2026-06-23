package com.nle.editor.preview

import com.kata.videoeditor.nle.export.NleTrueExportAsset
import com.kata.videoeditor.nle.export.NleVideoDecoderPool
import com.nle.editor.rendergraph.NleRenderGraph

class NlePreviewDecoderPreparer {

    fun prepare(
        graph: NleRenderGraph,
        decoderPool: NleVideoDecoderPool,
        preferProxy: Boolean,
    ) {
        val videoAssetIds = graph.tracks
            .asSequence()
            .filter { it.isVisual }
            .filter { !it.isHidden && !it.isMuted }
            .flatMap { it.clips.asSequence() }
            .filter { !it.isDisabled }
            .filter { it.type == "video" }
            .mapNotNull { it.assetId }
            .toSet()

        val assetMap = graph.assets.associateBy { it.id }

        for (assetId in videoAssetIds) {
            val asset = assetMap[assetId] ?: continue

            val path = if (preferProxy) {
                asset.proxyPath ?: asset.originalPath
            } else {
                asset.originalPath ?: asset.proxyPath
            }

            if (path.isNullOrBlank()) continue

            val trueAsset = NleTrueExportAsset(
                id = asset.id,
                path = path,
                width = asset.width,
                height = asset.height,
                durationUs = asset.durationUs,
                hasVideo = asset.hasVideo,
                hasAudio = asset.hasAudio,
            )

            try {
                decoderPool.decoderFor(trueAsset)
            } catch (_: Throwable) {
                // Best-effort preparation
            }
        }
    }
}
