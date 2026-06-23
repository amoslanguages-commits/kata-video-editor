package com.nle.editor.compositor

import android.opengl.GLES11Ext
import android.opengl.GLES20

data class NleLayerTexture(
    val textureId: Int,
    val target: Int,
    val width: Int,
    val height: Int,
    val ownsTexture: Boolean = false,
) {
    val isExternalOes: Boolean
        get() = target == GLES11Ext.GL_TEXTURE_EXTERNAL_OES

    fun releaseIfOwned() {
        if (!ownsTexture || textureId <= 0) return

        val ids = intArrayOf(textureId)
        GLES20.glDeleteTextures(1, ids, 0)
    }
}

interface NleLayerTextureProvider {
    fun textureForVideoLayer(layer: com.nle.editor.rendergraph.NleResolvedVisualLayer): NleLayerTexture?
    fun textureForImageLayer(layer: com.nle.editor.rendergraph.NleResolvedVisualLayer): NleLayerTexture?
    fun textureForTextLayer(layer: com.nle.editor.rendergraph.NleResolvedVisualLayer): NleLayerTexture?
}
