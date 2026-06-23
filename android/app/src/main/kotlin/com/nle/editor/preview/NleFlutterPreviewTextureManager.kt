package com.nle.editor.preview

import android.view.Surface
import io.flutter.view.TextureRegistry

class NleFlutterPreviewTexture(
    private val textureRegistry: TextureRegistry,
) {
    private var entry: TextureRegistry.SurfaceTextureEntry? = null
    private var surface: Surface? = null

    val textureId: Long
        get() = entry?.id() ?: -1L

    fun createOrResize(width: Int, height: Int) {
        val safeWidth = width.coerceAtLeast(16)
        val safeHeight = height.coerceAtLeast(16)
        if (entry == null) {
            entry = textureRegistry.createSurfaceTexture()
        }
        entry?.surfaceTexture()?.setDefaultBufferSize(safeWidth, safeHeight)
        surface?.release()
        surface = Surface(entry?.surfaceTexture())
    }

    fun currentSurface(): Surface {
        return surface ?: throw IllegalStateException("Flutter preview surface has not been created.")
    }

    fun release() {
        surface?.release()
        surface = null
        entry?.release()
        entry = null
    }
}

class NleManagedFlutterPreviewTexture(
    val id: Long,
    var projectId: String?,
    var width: Int,
    var height: Int,
    private val entry: TextureRegistry.SurfaceTextureEntry,
) {
    fun resize(width: Int, height: Int) {
        this.width = width.coerceAtLeast(16)
        this.height = height.coerceAtLeast(16)
        entry.surfaceTexture().setDefaultBufferSize(this.width, this.height)
    }

    fun release() {
        entry.release()
    }
}

class NleFlutterPreviewTextureManager(
    private val textureRegistry: TextureRegistry,
) {
    private val textures = mutableMapOf<Long, NleManagedFlutterPreviewTexture>()

    fun create(projectId: String?, width: Int, height: Int): NleManagedFlutterPreviewTexture {
        val entry = textureRegistry.createSurfaceTexture()
        val texture = NleManagedFlutterPreviewTexture(
            id = entry.id(),
            projectId = projectId,
            width = width.coerceAtLeast(16),
            height = height.coerceAtLeast(16),
            entry = entry,
        )
        entry.surfaceTexture().setDefaultBufferSize(texture.width, texture.height)
        textures[texture.id] = texture
        return texture
    }

    fun attach(projectId: String, textureId: Long) {
        val texture = textures[textureId]
            ?: throw IllegalStateException("Preview texture $textureId was not found.")
        texture.projectId = projectId
    }

    fun resize(textureId: Long, width: Int, height: Int) {
        val texture = textures[textureId]
            ?: throw IllegalStateException("Preview texture $textureId was not found.")
        texture.resize(width, height)
    }

    fun dispose(textureId: Long) {
        textures.remove(textureId)?.release()
    }

    fun releaseAll() {
        val ids = textures.keys.toList()
        ids.forEach { dispose(it) }
        textures.clear()
    }

    fun renderGpuFrameForProject(
        projectId: String,
        renderGraphJson: String,
        timelineTimeMicros: Long,
        compositorSession: NleGpuPreviewCompositorSession,
    ): Int {
        return 0
    }
}

class NleGpuPreviewCompositorSession {
    fun release() {}
}
