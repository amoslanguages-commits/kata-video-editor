package com.nle.editor.preview

import android.opengl.GLES11Ext
import android.util.Log
import com.kata.videoeditor.nle.export.NleTrueExportAsset
import com.kata.videoeditor.nle.export.NleVideoDecoderPool
import com.nle.editor.compositor.NleLayerTexture
import com.nle.editor.compositor.NleVideoTextureSource
import com.nle.editor.rendergraph.NleRenderGraph

class NlePreviewVideoTextureSource(
    private val graph: NleRenderGraph,
    private val decoderPool: NleVideoDecoderPool,
    private val preferProxy: Boolean,
) : NleVideoTextureSource {

    private val assetMap = graph.assets.associateBy { it.id }

    override fun textureForVideoFrame(
        assetId: String,
        sourceTimeUs: Long,
    ): NleLayerTexture? {
        val asset = assetMap[assetId] ?: return null

        val path = if (preferProxy) {
            asset.proxyPath ?: asset.originalPath
        } else {
            asset.originalPath ?: asset.proxyPath
        } ?: return null

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
                ownsTexture = false,
            )
        } catch (error: Throwable) {
            Log.w(
                "NlePreview",
                "video texture failed asset=$assetId sourceUs=$sourceTimeUs path=$path reason=${error.message ?: error}"
            )
            null
        }
    }
}
