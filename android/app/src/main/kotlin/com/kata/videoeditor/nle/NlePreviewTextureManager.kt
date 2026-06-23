package com.kata.videoeditor.nle

import io.flutter.view.TextureRegistry
import java.util.concurrent.ConcurrentHashMap

class NlePreviewTextureManager(
    private val textureRegistry: TextureRegistry,
    private val eventEmitter: NleNativeEventEmitter,
) {
    private val textures = ConcurrentHashMap<Long, NlePreviewTexture>()

    fun createPreviewTexture(
        projectId: String?,
        width: Int,
        height: Int,
        commandId: String? = null
    ): Map<String, Any?> {
        val entry = textureRegistry.createSurfaceTexture()

        val previewTexture = NlePreviewTexture(
            entry = entry,
            initialWidth = width,
            initialHeight = height
        )

        textures[previewTexture.textureId] = previewTexture

        previewTexture.renderPlaceholderFrame(
            label = "Native Preview Surface",
            playheadMicros = 0L
        )

        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PREVIEW_SURFACE_READY,
                projectId = projectId,
                commandId = commandId,
                payload = previewTexture.toMap()
            )
        )

        return mapOf(
            "success" to true,
            "previewTexture" to previewTexture.toMap()
        )
    }

    fun attachPreviewTexture(
        projectId: String,
        sessionId: String?,
        textureId: Long,
        commandId: String? = null
    ): Map<String, Any?> {
        val texture = textures[textureId]
            ?: throw IllegalStateException(NleNativeErrorCode.PREVIEW_TEXTURE_NOT_FOUND)

        texture.attachToProject(
            projectId = projectId,
            sessionId = sessionId
        )

        texture.renderPlaceholderFrame(
            label = "Attached to Project",
            playheadMicros = 0L
        )

        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PREVIEW_SURFACE_ATTACHED,
                projectId = projectId,
                sessionId = sessionId,
                commandId = commandId,
                payload = texture.toMap()
            )
        )

        return mapOf(
            "success" to true,
            "previewTexture" to texture.toMap()
        )
    }

    fun resizePreviewTexture(
        textureId: Long,
        width: Int,
        height: Int,
        commandId: String? = null
    ): Map<String, Any?> {
        val texture = textures[textureId]
            ?: throw IllegalStateException(NleNativeErrorCode.PREVIEW_TEXTURE_NOT_FOUND)

        texture.resize(
            newWidth = width,
            newHeight = height
        )

        texture.renderPlaceholderFrame(
            label = "Native Preview Resized",
            playheadMicros = 0L
        )

        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PREVIEW_SURFACE_RESIZED,
                projectId = texture.attachedProjectId,
                sessionId = texture.attachedSessionId,
                commandId = commandId,
                payload = texture.toMap()
            )
        )

        return mapOf(
            "success" to true,
            "previewTexture" to texture.toMap()
        )
    }

    fun renderPlaceholderFrame(
        textureId: Long,
        label: String,
        playheadMicros: Long,
        commandId: String? = null
    ): Map<String, Any?> {
        val texture = textures[textureId]
            ?: throw IllegalStateException(NleNativeErrorCode.PREVIEW_TEXTURE_NOT_FOUND)

        texture.renderPlaceholderFrame(
            label = label,
            playheadMicros = playheadMicros
        )

        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PREVIEW_FRAME_RENDERED,
                projectId = texture.attachedProjectId,
                sessionId = texture.attachedSessionId,
                commandId = commandId,
                payload = texture.toMap() + mapOf(
                    "playheadMicros" to playheadMicros
                )
            )
        )

        return mapOf(
            "success" to true,
            "previewTexture" to texture.toMap()
        )
    }

    fun disposePreviewTexture(textureId: Long, commandId: String? = null): Map<String, Any?> {
        val texture = textures.remove(textureId)
            ?: throw IllegalStateException(NleNativeErrorCode.PREVIEW_TEXTURE_NOT_FOUND)

        val projectId = texture.attachedProjectId
        val sessionId = texture.attachedSessionId
        val payload = texture.toMap()

        texture.release()

        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PREVIEW_SURFACE_DISPOSED,
                projectId = projectId,
                sessionId = sessionId,
                commandId = commandId,
                payload = payload
            )
        )

        return mapOf(
            "success" to true,
            "textureId" to textureId
        )
    }

    fun getTexture(textureId: Long): NlePreviewTexture? {
        return textures[textureId]
    }

    fun disposeAll() {
        val ids = textures.keys.toList()

        ids.forEach { textureId ->
            try {
                disposePreviewTexture(textureId)
            } catch (_: Throwable) {
            }
        }

        textures.clear()
    }

    fun renderGpuFrameForProject(
        projectId: String,
        renderGraphJson: String,
        timelineTimeMicros: Long,
        compositorSession: com.kata.videoeditor.nle.gpu.NleCompositorSession,
    ): Int {
        var rendered = 0

        textures.values.forEach { texture ->
            if (texture.attachedProjectId == projectId) {
                val surface = texture.getSurface()

                if (surface != null) {
                    compositorSession.renderPreviewFrame(
                        projectId = projectId,
                        renderGraphJson = renderGraphJson,
                        timelineTimeMicros = timelineTimeMicros,
                        surface = surface,
                        width = texture.width,
                        height = texture.height
                    )

                    rendered++
                }
            }
        }

        return rendered
    }

    fun renderPlaceholderForProject(
        projectId: String,
        label: String,
        playheadMicros: Long,
    ): Int {
        var rendered = 0
        textures.values.forEach { texture ->
            if (texture.attachedProjectId == projectId) {
                texture.renderPlaceholderFrame(
                    label = label,
                    playheadMicros = playheadMicros
                )
                rendered++
            }
        }
        return rendered
    }
}
