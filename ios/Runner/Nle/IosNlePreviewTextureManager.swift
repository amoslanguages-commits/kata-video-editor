import Foundation
import Flutter

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
        width: Int,
        height: Int
    ) -> [String: Any?] {
        let texture = IosNlePreviewTexture(width: width, height: height)
        let textureId = textureRegistry.register(texture)

        texture.setTextureId(textureId)
        textures[textureId] = texture

        texture.drawPlaceholder(
            label: "iOS Native Preview",
            playheadMicros: 0
        )

        textureRegistry.textureFrameAvailable(textureId)

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.previewSurfaceReady,
                projectId: projectId,
                sessionId: nil,
                payload: texture.toMap()
            )
        )

        return [
            "success": true,
            "previewTexture": texture.toMap()
        ]
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
        texture.drawPlaceholder(
            label: "Attached to iOS Project",
            playheadMicros: 0
        )

        textureRegistry.textureFrameAvailable(textureId)

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

    func renderPlaceholder(
        textureId: Int64,
        label: String,
        playheadMicros: Int64
    ) throws -> [String: Any?] {
        guard let texture = textures[textureId] else {
            throw NSError(
                domain: "IosNlePreviewTextureManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.previewTextureNotFound]
            )
        }

        texture.drawPlaceholder(
            label: label,
            playheadMicros: playheadMicros
        )

        textureRegistry.textureFrameAvailable(textureId)

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.previewFrameRendered,
                projectId: texture.projectId,
                sessionId: texture.sessionId,
                payload: texture.toMap().merging([
                    "playheadMicros": playheadMicros
                ]) { current, _ in current }
            )
        )

        return [
            "success": true,
            "previewTexture": texture.toMap()
        ]
    }

    func renderPlaceholderForProject(
        projectId: String,
        label: String,
        playheadMicros: Int64
    ) {
        textures.values
            .filter { $0.projectId == projectId }
            .forEach { texture in
                texture.drawPlaceholder(
                    label: label,
                    playheadMicros: playheadMicros
                )
                textureRegistry.textureFrameAvailable(texture.textureId)
            }
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
