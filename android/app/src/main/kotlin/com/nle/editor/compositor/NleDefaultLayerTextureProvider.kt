package com.nle.editor.compositor

import com.nle.editor.rendergraph.NleResolvedVisualLayer

interface NleVideoTextureSource {
    fun textureForVideoFrame(
        assetId: String,
        sourceTimeUs: Long,
    ): NleLayerTexture?
}

class NleDefaultLayerTextureProvider(
    private val videoTextureSource: NleVideoTextureSource,
    private val outputWidth: Int,
    private val outputHeight: Int,
) : NleLayerTextureProvider {

    private val imageCache = NleImageTextureCache()
    private val textRenderer = NleTextLayerRenderer()

    override fun textureForVideoLayer(
        layer: NleResolvedVisualLayer,
    ): NleLayerTexture? {
        val assetId = layer.clip.assetId ?: return null

        return videoTextureSource.textureForVideoFrame(
            assetId = assetId,
            sourceTimeUs = layer.sourceTimeUs,
        )
    }

    override fun textureForImageLayer(
        layer: NleResolvedVisualLayer,
    ): NleLayerTexture? {
        return imageCache.textureForLayer(layer)
    }

    override fun textureForTextLayer(
        layer: NleResolvedVisualLayer,
    ): NleLayerTexture? {
        return textRenderer.textureForLayer(
            layer = layer,
            outputWidth = outputWidth,
            outputHeight = outputHeight,
        )
    }

    fun release() {
        imageCache.release()
        textRenderer.release()
    }
}
