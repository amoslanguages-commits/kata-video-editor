import Foundation
import Flutter
import AVFoundation

final class IosNleEngineManager {
    private let eventEmitter: IosNleEventEmitter
    private let validator = IosNleRenderGraphValidator()
    private let mediaProbe = IosNleMediaProbe()

    private let previewTextureManager: IosNlePreviewTextureManager

    private var initialized = false
    private var sessions: [String: IosNleEngineSession] = [:]

    init(
        textureRegistry: FlutterTextureRegistry,
        eventEmitter: IosNleEventEmitter
    ) {
        self.eventEmitter = eventEmitter
        self.previewTextureManager = IosNlePreviewTextureManager(
            textureRegistry: textureRegistry,
            eventEmitter: eventEmitter
        )
    }

    func initialize() -> [String: Any?] {
        initialized = true

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.engineReady,
                projectId: nil,
                sessionId: nil,
                payload: [
                    "platform": "ios",
                    "version": "ios_native_engine_v1",
                    "previewTexture": "flutter_texture_pixel_buffer_v1",
                    "avFoundation": true,
                    "metal": "foundation_pending",
                    "initialized": true
                ]
            )
        )

        return [
            "success": true,
            "platform": "ios",
            "engineVersion": "ios_native_engine_v1"
        ]
    }

    func dispose() -> [String: Any?] {
        sessions.removeAll()
        previewTextureManager.disposeAll()
        initialized = false

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.engineDisposed,
                projectId: nil,
                sessionId: nil,
                payload: [
                    "disposed": true,
                    "platform": "ios"
                ]
            )
        )

        return ["success": true]
    }

    func requireInitialized() throws {
        if !initialized {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.engineNotInitialized]
            )
        }
    }

    func loadRenderGraph(
        projectId: String,
        renderGraphJson: String
    ) throws -> [String: Any?] {
        try requireInitialized()

        let session = try IosNleEngineSession(
            projectId: projectId,
            renderGraphJson: renderGraphJson
        )

        let validation = validator.validate(session.renderGraph)

        if !validation.valid {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.graphValidationFailed]
            )
        }

        sessions[projectId] = session

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.graphLoaded,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: [
                    "durationMicros": session.durationMicros,
                    "validation": validation.toMap()
                ]
            )
        )

        return [
            "success": true,
            "session": session.toMap(),
            "validation": validation.toMap()
        ]
    }

    func updateRenderGraph(
        projectId: String,
        renderGraphJson: String,
        reason: String?
    ) throws -> [String: Any?] {
        try requireInitialized()

        guard let session = sessions[projectId] else {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound]
            )
        }

        try session.updateGraph(renderGraphJson)

        let validation = validator.validate(session.renderGraph)

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.graphUpdated,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: [
                    "reason": reason ?? "update",
                    "durationMicros": session.durationMicros,
                    "validation": validation.toMap()
                ]
            )
        )

        return [
            "success": true,
            "session": session.toMap(),
            "validation": validation.toMap()
        ]
    }

    func validateRenderGraph(renderGraphJson: String) throws -> [String: Any?] {
        try requireInitialized()

        let data = Data(renderGraphJson.utf8)
        let object = try JSONSerialization.jsonObject(with: data)

        guard let graph = object as? [String: Any] else {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.graphParseFailed]
            )
        }

        let validation = validator.validate(graph)

        return [
            "success": validation.valid,
            "valid": validation.valid,
            "warnings": validation.warnings,
            "errors": validation.errors,
            "summary": validation.summary
        ]
    }

    func play(projectId: String) throws -> [String: Any?] {
        try requireInitialized()

        guard let session = sessions[projectId] else {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound]
            )
        }

        session.play()

        previewTextureManager.renderPlaceholderForProject(
            projectId: projectId,
            label: "iOS Native Playback",
            playheadMicros: session.playheadMicros
        )

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.playbackStarted,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: [
                    "playheadMicros": session.playheadMicros,
                    "durationMicros": session.durationMicros
                ]
            )
        )

        return [
            "success": true,
            "session": session.toMap()
        ]
    }

    func pause(projectId: String) throws -> [String: Any?] {
        try requireInitialized()

        guard let session = sessions[projectId] else {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 6,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound]
            )
        }

        session.pause()

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.playbackPaused,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: [
                    "playheadMicros": session.playheadMicros,
                    "durationMicros": session.durationMicros
                ]
            )
        )

        return [
            "success": true,
            "session": session.toMap()
        ]
    }

    func seek(
        projectId: String,
        positionMicros: Int64
    ) throws -> [String: Any?] {
        try requireInitialized()

        guard let session = sessions[projectId] else {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 7,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound]
            )
        }

        session.seek(positionMicros)

        previewTextureManager.renderPlaceholderForProject(
            projectId: projectId,
            label: "iOS Native Preview",
            playheadMicros: session.playheadMicros
        )

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.playheadChanged,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: [
                    "playheadMicros": session.playheadMicros,
                    "durationMicros": session.durationMicros,
                    "source": "ios_seek"
                ]
            )
        )

        return [
            "success": true,
            "session": session.toMap()
        ]
    }

    func setPlaybackRate(
        projectId: String,
        rate: Double
    ) throws -> [String: Any?] {
        try requireInitialized()

        guard let session = sessions[projectId] else {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 8,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound]
            )
        }

        session.setPlaybackRate(rate)

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.playbackRateChanged,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: [
                    "playbackRate": session.playbackRate
                ]
            )
        )

        return [
            "success": true,
            "session": session.toMap()
        ]
    }

    func getSessionState(projectId: String) throws -> [String: Any?] {
        try requireInitialized()

        guard let session = sessions[projectId] else {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 9,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound]
            )
        }

        return [
            "success": true,
            "session": session.toMap()
        ]
    }

    func probeDeviceCapabilities() throws -> [String: Any?] {
        try requireInitialized()

        let result: [String: Any?] = [
            "platform": "ios",
            "codec": [
                "h264Decode": true,
                "h264Encode": true,
                "hevcDecode": true,
                "hevcEncode": true,
                "aacDecode": true,
                "aacEncode": true
            ],
            "preview": [
                "texture": "flutter_texture_pixel_buffer_v1",
                "metal": "planned"
            ],
            "limits": [
                "safePreviewHeight": 1080,
                "recommendedProxyHeight": 720,
                "allow4kExport": true
            ]
        ]

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.deviceCapabilities,
                projectId: nil,
                sessionId: nil,
                payload: result
            )
        )

        return [
            "success": true,
            "deviceCapabilities": result
        ]
    }

    func probeMedia(path: String) async throws -> [String: Any?] {
        try requireInitialized()

        let result = try await mediaProbe.probe(path: path)

        return [
            "success": true,
            "media": result
        ]
    }

    func createPreviewTexture(
        projectId: String?,
        width: Int,
        height: Int
    ) throws -> [String: Any?] {
        try requireInitialized()

        return previewTextureManager.createPreviewTexture(
            projectId: projectId,
            width: width,
            height: height
        )
    }

    func attachPreviewTexture(
        projectId: String,
        textureId: Int64
    ) throws -> [String: Any?] {
        try requireInitialized()

        let session = sessions[projectId]

        return try previewTextureManager.attachPreviewTexture(
            projectId: projectId,
            sessionId: session?.sessionId,
            textureId: textureId
        )
    }

    func renderPreviewPlaceholder(
        textureId: Int64,
        label: String,
        playheadMicros: Int64
    ) throws -> [String: Any?] {
        try requireInitialized()

        return try previewTextureManager.renderPlaceholder(
            textureId: textureId,
            label: label,
            playheadMicros: playheadMicros
        )
    }

    func renderGpuPreviewFrame(
        projectId: String,
        timelineTimeMicros: Int64
    ) throws -> [String: Any?] {
        try requireInitialized()

        guard let session = sessions[projectId] else {
            throw NSError(
                domain: "IosNleEngineManager",
                code: 10,
                userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound]
            )
        }

        session.seek(timelineTimeMicros)

        previewTextureManager.renderPlaceholderForProject(
            projectId: projectId,
            label: "iOS Metal Preview Placeholder",
            playheadMicros: session.playheadMicros
        )

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.gpuPreviewFrameRendered,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: [
                    "playheadMicros": session.playheadMicros,
                    "metal": false,
                    "placeholder": true
                ]
            )
        )

        return [
            "success": true,
            "projectId": projectId,
            "playheadMicros": session.playheadMicros,
            "placeholder": true
        ]
    }

    func disposePreviewTexture(textureId: Int64) throws -> [String: Any?] {
        try requireInitialized()
        return try previewTextureManager.disposePreviewTexture(textureId: textureId)
    }

    func startProxyJob(args: [String: Any?]) throws -> [String: Any?] {
        try requireInitialized()

        let projectId = args["projectId"] as? String
        let jobId = args.stringRequired("jobId")
        let assetId = args.stringRequired("assetId")
        let inputPath = args.stringRequired("inputPath")
        let outputPath = args.stringRequired("outputPath")

        IosNleProxyJobFoundation().start(
            projectId: projectId,
            jobId: jobId,
            assetId: assetId,
            inputPath: inputPath,
            outputPath: outputPath,
            eventEmitter: eventEmitter
        )

        return [
            "success": true,
            "jobId": jobId,
            "placeholder": true
        ]
    }

    func cancelProxyJob(jobId: String) throws -> [String: Any?] {
        try requireInitialized()

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.proxyCancelled,
                projectId: nil,
                sessionId: nil,
                jobId: jobId,
                payload: [
                    "jobId": jobId,
                    "platform": "ios"
                ]
            )
        )

        return [
            "success": true,
            "jobId": jobId
        ]
    }

    func startExportJob(args: [String: Any?]) throws -> [String: Any?] {
        try requireInitialized()

        let projectId = args.stringRequired("projectId")
        let jobId = args.stringRequired("jobId")
        let renderGraphJson = args.stringRequired("renderGraphJson")
        let outputPath = args.stringRequired("outputPath")

        IosNleExportJobFoundation().start(
            projectId: projectId,
            jobId: jobId,
            renderGraphJson: renderGraphJson,
            outputPath: outputPath,
            eventEmitter: eventEmitter
        )

        return [
            "success": true,
            "jobId": jobId
        ]
    }

    func cancelExportJob(jobId: String) throws -> [String: Any?] {
        try requireInitialized()

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.exportCancelled,
                projectId: nil,
                sessionId: nil,
                jobId: jobId,
                payload: [
                    "jobId": jobId,
                    "platform": "ios"
                ]
            )
        )

        return [
            "success": true,
            "jobId": jobId
        ]
    }
}

private extension Dictionary where Key == String, Value == Any? {
    func stringRequired(_ key: String) throws -> String {
        if let value = self[key] as? String, !value.isEmpty {
            return value
        }

        throw NSError(
            domain: "IosNleArguments",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "\(IosNleErrorCode.invalidArguments): missing string \(key)"]
        )
    }
}
