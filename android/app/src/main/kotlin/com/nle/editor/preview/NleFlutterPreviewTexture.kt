package com.nle.editor.preview

import android.graphics.SurfaceTexture
import android.view.Surface
import io.flutter.view.TextureRegistry

class NleFlutterPreviewTexture(
    private val textureRegistry: TextureRegistry,
) {
    private var entry: TextureRegistry.SurfaceTextureEntry? = null
    private var surfaceTexture: SurfaceTexture? = null
    private var surface: Surface? = null

    val textureId: Long
        get() = entry?.id() ?: -1L

    fun createOrResize(
        width: Int,
        height: Int,
    ): Surface {
        if (entry == null) {
            entry = textureRegistry.createSurfaceTexture()
            surfaceTexture = entry?.surfaceTexture()
            surface = Surface(surfaceTexture)
        }

        surfaceTexture?.setDefaultBufferSize(width, height)

        return surface ?: error("Preview surface was not created.")
    }

    fun currentSurface(): Surface {
        return surface ?: error("Preview surface was not created.")
    }

    fun release() {
        surface?.release()
        surface = null

        entry?.release()
        entry = null

        surfaceTexture = null
    }
}
