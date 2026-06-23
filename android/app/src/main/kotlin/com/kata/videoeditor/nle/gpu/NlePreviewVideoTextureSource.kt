package com.kata.videoeditor.nle.gpu

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import com.nle.editor.compositor.NleLayerTexture
import com.nle.editor.compositor.NleTexture2dUtil
import com.nle.editor.compositor.NleVideoTextureSource
import com.nle.editor.rendergraph.NleRenderAsset
import com.nle.editor.rendergraph.NleRenderGraph

class NlePreviewVideoTextureSource : NleVideoTextureSource {
    private var assetMap: Map<String, NleRenderAsset> = emptyMap()

    fun updateGraph(graph: NleRenderGraph) {
        assetMap = graph.assets.associateBy { it.id }
    }

    override fun textureForVideoFrame(
        assetId: String,
        sourceTimeUs: Long,
    ): NleLayerTexture? {
        val asset = assetMap[assetId] ?: return null
        val path = asset.proxyPath ?: asset.originalPath ?: return null

        val bitmap = extractBitmap(path, sourceTimeUs) ?: return null
        val texture = NleTexture2dUtil.createTextureFromBitmap(bitmap, ownsTexture = true)
        bitmap.recycle()
        return texture
    }

    private fun extractBitmap(inputPath: String, timeMicros: Long): Bitmap? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(inputPath)
            if (Build.VERSION.SDK_INT >= 27) {
                retriever.getScaledFrameAtTime(
                    timeMicros,
                    MediaMetadataRetriever.OPTION_CLOSEST,
                    1920, 1080
                )
            } else {
                retriever.getFrameAtTime(
                    timeMicros,
                    MediaMetadataRetriever.OPTION_CLOSEST
                )
            }
        } catch (_: Throwable) {
            null
        } finally {
            try { retriever.release() } catch (_: Throwable) { }
        }
    }
}
