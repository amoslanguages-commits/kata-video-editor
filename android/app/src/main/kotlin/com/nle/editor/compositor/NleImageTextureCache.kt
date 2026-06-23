package com.nle.editor.compositor

import android.graphics.BitmapFactory
import com.nle.editor.rendergraph.NleResolvedVisualLayer

class NleImageTextureCache {

    private val cache = linkedMapOf<String, NleLayerTexture>()

    fun textureForLayer(layer: NleResolvedVisualLayer): NleLayerTexture? {
        val asset = layer.asset ?: return null
        val path = asset.originalPath ?: asset.proxyPath ?: return null

        cache[path]?.let { return it }

        val bitmap = BitmapFactory.decodeFile(path) ?: return null

        val texture = NleTexture2dUtil.createTextureFromBitmap(bitmap)
        bitmap.recycle()

        cache[path] = texture

        return texture
    }

    fun release() {
        cache.values.forEach { it.releaseIfOwned() }
        cache.clear()
    }
}
