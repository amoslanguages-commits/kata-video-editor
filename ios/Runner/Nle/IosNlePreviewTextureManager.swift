import Foundation
import Flutter
import CoreGraphics

final class IosNlePreviewTextureManager {
    private let textureRegistry: FlutterTextureRegistry
    private let eventEmitter: IosNleEventEmitter

    private var textures: [Int64: IosNlePreviewTexture] = [:]

    init(
        textureRegistry: FlutterTextureRegistry,
        eventEmitter: IosNleEventEmitter
    ) {
        self.textureRegistry = textureRegistry
        self.eventEmitter = eventEmitter
    }

    func createPreviewTexture(
        projectId: String?,
        sessionId: String?,
        monitorId: String,
        width: Int,
        height: Int
    ) -> [String: Any?] {
        let texture = IosNlePreviewTexture(width: width, height: height)
        let textureId = textureRegistry.register(texture)

        texture.setTextureId(textureId)
        if let projectId {
            texture.attach(projectId: projectId, sessionId: sessionId)
        }
        textures[textureId] = texture

        eventEmitter.emit(
            IosNleEvent(
                type: "preview_texture_ready",
                projectId: projectId,
                sessionId: sessionId,
                payload: texture.toMap().merging([
                    "monitorId": monitorId
                ]) { current, _ in current }
            )
        )

        return [
            "success": true,
            "previewTexture": texture.toMap(),
            "monitorId": monitorId
        ]
    }

    func createPreviewTexture(
        projectId: String?,
        width: Int,
        height: Int
    ) -> [String: Any?] {
        return createPreviewTexture(
            projectId: projectId,
            sessionId: nil,
            monitorId: "program",
            width: width,
            height: height
        )
    }

    func attachPreviewTexture(
        projectId: String,
        sessionId: String?,
        textureId: Int64
    ) throws -> [String: Any?] {
        guard let texture = textures[textureId] else {
            throw NSError(
                domain: "IosNlePreviewTextureManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.previewTextureNotFound]
            )
        }

        texture.attach(projectId: projectId, sessionId: sessionId)

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.previewSurfaceAttached,
                projectId: projectId,
                sessionId: sessionId,
                payload: texture.toMap()
            )
        )

        return [
            "success": true,
            "previewTexture": texture.toMap()
        ]
    }

    func renderDecodedFrame(
        textureId: Int64,
        image: CGImage,
        projectId: String,
        sessionId: String?,
        monitorId: String,
        timelineMicros: Int64,
        sourceMicros: Int64,
        assetPath: String
    ) throws -> [String: Any?] {
        guard let texture = textures[textureId] else {
            throw NSError(
                domain: "IosNlePreviewTextureManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.previewTextureNotFound]
            )
        }

        try texture.render(image: image)
        textureRegistry.textureFrameAvailable(textureId)

        eventEmitter.emit(
            IosNleEvent(
                type: "preview_frame_rendered",
                projectId: projectId,
                sessionId: sessionId,
                payload: texture.toMap().merging([
                    "monitorId": monitorId,
                    "timelineTimeUs": timelineMicros,
                    "sourceTimeUs": sourceMicros,
                    "assetPath": assetPath
                ]) { current, _ in current }
            )
        )

        return [
            "success": true,
            "previewTexture": texture.toMap(),
            "timelineTimeUs": timelineMicros,
            "sourceTimeUs": sourceMicros,
            "monitorId": monitorId
        ]
    }

    func renderPlaceholder(
        textureId: Int64,
        label: String,
        playheadMicros: Int64
    ) throws -> [String: Any?] {
        throw NSError(
            domain: "IosNlePreviewTextureManager",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Placeholder preview rendering is disabled in full-native mode."]
        )
    }

    func renderPlaceholderForProject(
        projectId: String,
        label: String,
        playheadMicros: Int64
    ) {
        eventEmitter.emit(
            IosNleEvent(
                type: "preview_error",
                projectId: projectId,
                sessionId: nil,
                payload: [
                    "monitorId": "program",
                    "message": "Placeholder preview rendering is disabled in full-native mode."
                ]
            )
        )
    }

    func textureIdForProject(_ projectId: String) -> Int64? {
        return textures.values.first(where: { $0.projectId == projectId })?.textureId
    }

    func disposePreviewTexture(textureId: Int64) throws -> [String: Any?] {
        guard let texture = textures.removeValue(forKey: textureId) else {
            throw NSError(
                domain: "IosNlePreviewTextureManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.previewTextureNotFound]
            )
        }

        textureRegistry.unregisterTexture(textureId)

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.previewSurfaceDisposed,
                projectId: texture.projectId,
                sessionId: texture.sessionId,
                payload: [
                    "textureId": textureId,
                    "platform": "ios"
                ]
            )
        )

        return [
            "success": true,
            "textureId": textureId
        ]
    }

    func disposeAll() {
        let ids = Array(textures.keys)

        ids.forEach { id in
            try? disposePreviewTexture(textureId: id)
        }

        textures.removeAll()
    }
}
