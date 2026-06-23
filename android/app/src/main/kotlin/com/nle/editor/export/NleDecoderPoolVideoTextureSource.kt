package com.nle.editor.export

import android.opengl.GLES11Ext
import com.kata.videoeditor.nle.export.NleTrueExportAsset
import com.kata.videoeditor.nle.export.NleVideoDecoderPool
import com.nle.editor.compositor.NleLayerTexture
import com.nle.editor.compositor.NleVideoTextureSource
import com.nle.editor.rendergraph.NleRenderGraph

class NleDecoderPoolVideoTextureSource(
    private val graph: NleRenderGraph,
    private val decoderPool: NleVideoDecoderPool,
) : NleVideoTextureSource {

    private val assetMap = graph.assets.associateBy { it.id }

    override fun textureForVideoFrame(
        assetId: String,
        sourceTimeUs: Long,
    ): NleLayerTexture? {
        val asset = assetMap[assetId] ?: return null
        val path = asset.proxyPath ?: asset.originalPath ?: return null

        val trueAsset = NleTrueExportAsset(
            id = asset.id,
            path = path,
            width = asset.width,
            height = asset.height,
            durationUs = asset.durationUs,
            hasVideo = asset.hasVideo,
            hasAudio = asset.hasAudio,
        )

        return try {
            val decoder = decoderPool.decoderFor(trueAsset)
            val frame = decoder.decodeFrameAtOrAfter(sourceTimeUs)

            NleLayerTexture(
                textureId = frame.oesTextureId,
                target = GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                width = asset.width,
                height = asset.height,
                ownsTexture = false, // Decoder output surface owns this texture.
            )
        } catch (_: Throwable) {
            null
        }
    }
}
