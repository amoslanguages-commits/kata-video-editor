package com.nle.editor.preview

import io.flutter.view.TextureRegistry

class NleFlutterPreviewTexture(
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
    private val textures = mutableMapOf<Long, NleFlutterPreviewTexture>()

    fun create(projectId: String?, width: Int, height: Int): NleFlutterPreviewTexture {
        val entry = textureRegistry.createSurfaceTexture()
        val texture = NleFlutterPreviewTexture(
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
        // Full-native mode: this legacy GPU-preview path must not draw placeholders.
        // Real decoded preview is handled through NlePreviewManager / NleTrueDecoderPreviewRenderer.
        return 0
    }
}

class NleGpuPreviewCompositorSession {
    fun release() {}
}
