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
    private var truePreviewRenderers: [String: IosNleAvFoundationPreviewRenderer] = [:]
    private var truePreviewTextureIds: [String: Int64] = [:]
    private var truePreviewProjectIds: [String: String] = [:]
    private var playbackTimers: [String: DispatchSourceTimer] = [:]

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
                    "metal": "not_enabled",
                    "initialized": true
                ]
            )
        )
        return ["success": true, "platform": "ios", "engineVersion": "ios_native_engine_v1"]
    }

    func dispose() -> [String: Any?] {
        playbackTimers.values.forEach { $0.cancel() }
        playbackTimers.removeAll()
        truePreviewRenderers.removeAll()
        truePreviewTextureIds.removeAll()
        truePreviewProjectIds.removeAll()
        sessions.removeAll()
        previewTextureManager.disposeAll()
        initialized = false
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.engineDisposed,
                projectId: nil,
                sessionId: nil,
                payload: ["disposed": true, "platform": "ios"]
            )
        )
        return ["success": true]
    }

    func requireInitialized() throws {
        if !initialized {
            throw NSError(domain: "IosNleEngineManager", code: 1, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.engineNotInitialized])
        }
    }

    func loadRenderGraph(projectId: String, renderGraphJson: String) throws -> [String: Any?] {
        try requireInitialized()
        let session = try IosNleEngineSession(projectId: projectId, renderGraphJson: renderGraphJson)
        let validation = validator.validate(session.renderGraph)
        if !validation.valid {
            throw NSError(domain: "IosNleEngineManager", code: 2, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.graphValidationFailed])
        }
        sessions[projectId] = session
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.graphLoaded,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: ["durationMicros": session.durationMicros, "validation": validation.toMap()]
            )
        )
        return ["success": true, "session": session.toMap(), "validation": validation.toMap()]
    }

    func updateRenderGraph(projectId: String, renderGraphJson: String, reason: String?) throws -> [String: Any?] {
        try requireInitialized()
        guard let session = sessions[projectId] else {
            throw NSError(domain: "IosNleEngineManager", code: 3, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound])
        }
        try session.updateGraph(renderGraphJson)
        truePreviewRenderers = truePreviewRenderers.mapValues { _ in IosNleAvFoundationPreviewRenderer(renderGraph: session.renderGraph, preferProxy: true) }
        let validation = validator.validate(session.renderGraph)
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.graphUpdated,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: ["reason": reason ?? "update", "durationMicros": session.durationMicros, "validation": validation.toMap()]
            )
        )
        return ["success": true, "session": session.toMap(), "validation": validation.toMap()]
    }

    func validateRenderGraph(renderGraphJson: String) throws -> [String: Any?] {
        try requireInitialized()
        let data = Data(renderGraphJson.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let graph = object as? [String: Any] else {
            throw NSError(domain: "IosNleEngineManager", code: 4, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.graphParseFailed])
        }
        let validation = validator.validate(graph)
        return ["success": validation.valid, "valid": validation.valid, "warnings": validation.warnings, "errors": validation.errors, "summary": validation.summary]
    }

    func play(projectId: String) throws -> [String: Any?] {
        try requireInitialized()
        guard let session = sessions[projectId] else {
            throw NSError(domain: "IosNleEngineManager", code: 5, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound])
        }
        session.play()
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.playbackStarted,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: ["playheadMicros": session.playheadMicros, "durationMicros": session.durationMicros]
            )
        )
        return ["success": true, "session": session.toMap()]
    }

    func pause(projectId: String) throws -> [String: Any?] {
        try requireInitialized()
        guard let session = sessions[projectId] else {
            throw NSError(domain: "IosNleEngineManager", code: 6, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound])
        }
        session.pause()
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.playbackPaused,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: ["playheadMicros": session.playheadMicros, "durationMicros": session.durationMicros]
            )
        )
        return ["success": true, "session": session.toMap()]
    }

    func seek(projectId: String, positionMicros: Int64) throws -> [String: Any?] {
        try requireInitialized()
        guard let session = sessions[projectId] else {
            throw NSError(domain: "IosNleEngineManager", code: 7, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound])
        }
        session.seek(positionMicros)
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.playheadChanged,
                projectId: projectId,
                sessionId: session.sessionId,
                payload: ["playheadMicros": session.playheadMicros, "durationMicros": session.durationMicros, "source": "ios_seek"]
            )
        )
        return ["success": true, "session": session.toMap()]
    }

    func setPlaybackRate(projectId: String, rate: Double) throws -> [String: Any?] {
        try requireInitialized()
        guard let session = sessions[projectId] else {
            throw NSError(domain: "IosNleEngineManager", code: 8, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound])
        }
        session.setPlaybackRate(rate)
        eventEmitter.emit(
            IosNleEvent(type: IosNleEventType.playbackRateChanged, projectId: projectId, sessionId: session.sessionId, payload: ["playbackRate": session.playbackRate])
        )
        return ["success": true, "session": session.toMap()]
    }

    func getSessionState(projectId: String) throws -> [String: Any?] {
        try requireInitialized()
        guard let session = sessions[projectId] else {
            throw NSError(domain: "IosNleEngineManager", code: 9, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound])
        }
        return ["success": true, "session": session.toMap()]
    }

    func probeDeviceCapabilities() throws -> [String: Any?] {
        try requireInitialized()
        let result: [String: Any?] = [
            "platform": "ios",
            "codec": ["h264Decode": true, "h264Encode": true, "hevcDecode": true, "hevcEncode": true, "aacDecode": true, "aacEncode": true],
            "preview": ["texture": "flutter_texture_pixel_buffer_v1", "avFoundation": true, "metal": false],
            "limits": ["safePreviewHeight": 1080, "recommendedProxyHeight": 720, "allow4kExport": true]
        ]
        eventEmitter.emit(IosNleEvent(type: IosNleEventType.deviceCapabilities, projectId: nil, sessionId: nil, payload: result))
        return ["success": true, "deviceCapabilities": result]
    }

    func probeMedia(path: String) async throws -> [String: Any?] {
        try requireInitialized()
        return ["success": true, "media": try await mediaProbe.probe(path: path)]
    }

    func createPreviewTexture(projectId: String?, width: Int, height: Int) throws -> [String: Any?] {
        try requireInitialized()
        return previewTextureManager.createPreviewTexture(projectId: projectId, width: width, height: height)
    }

    func attachPreviewTexture(projectId: String, textureId: Int64) throws -> [String: Any?] {
        try requireInitialized()
        return try previewTextureManager.attachPreviewTexture(projectId: projectId, sessionId: sessions[projectId]?.sessionId, textureId: textureId)
    }

    func renderPreviewPlaceholder(textureId: Int64, label: String, playheadMicros: Int64) throws -> [String: Any?] {
        try requireInitialized()
        throw NSError(domain: "IosNleEngineManager", code: 20, userInfo: [NSLocalizedDescriptionKey: "Placeholder preview rendering is disabled in full-native mode."])
    }

    func renderGpuPreviewFrame(projectId: String, timelineTimeMicros: Int64) throws -> [String: Any?] {
        try requireInitialized()
        guard let textureId = previewTextureManager.textureIdForProject(projectId) else {
            throw NSError(domain: "IosNleEngineManager", code: 21, userInfo: [NSLocalizedDescriptionKey: "No iOS preview texture is attached for this project."])
        }
        return try renderFrame(projectId: projectId, monitorId: "program", textureId: textureId, timelineMicros: timelineTimeMicros)
    }

    func disposePreviewTexture(textureId: Int64) throws -> [String: Any?] {
        try requireInitialized()
        return try previewTextureManager.disposePreviewTexture(textureId: textureId)
    }

    func prepareTruePreview(projectId: String, monitorId: String, renderGraphJson: String, preferProxy: Bool, maxPreviewWidth: Int, maxPreviewHeight: Int) throws -> [String: Any?] {
        try requireInitialized()
        let session = try IosNleEngineSession(projectId: projectId, renderGraphJson: renderGraphJson)
        let validation = validator.validate(session.renderGraph)
        if !validation.valid {
            throw NSError(domain: "IosNleEngineManager", code: 22, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.graphValidationFailed])
        }
        sessions[projectId] = session
        let renderer = IosNleAvFoundationPreviewRenderer(renderGraph: session.renderGraph, preferProxy: preferProxy)
        truePreviewRenderers[monitorId] = renderer
        truePreviewProjectIds[monitorId] = projectId
        let textureResult = previewTextureManager.createPreviewTexture(projectId: projectId, sessionId: session.sessionId, monitorId: monitorId, width: maxPreviewWidth, height: maxPreviewHeight)
        guard let previewTexture = textureResult["previewTexture"] as? [String: Any?],
              let textureIdNumber = previewTexture["textureId"] as? NSNumber else {
            throw NSError(domain: "IosNleEngineManager", code: 23, userInfo: [NSLocalizedDescriptionKey: "Failed to create iOS preview texture."])
        }
        let textureId = textureIdNumber.int64Value
        truePreviewTextureIds[monitorId] = textureId
        let frame = try renderer.renderFrame(timelineMicros: 0)
        let frameResult = try previewTextureManager.renderDecodedFrame(textureId: textureId, image: frame.image, projectId: projectId, sessionId: session.sessionId, monitorId: monitorId, timelineMicros: frame.timelineMicros, sourceMicros: frame.sourceMicros, assetPath: frame.assetPath)
        return ["success": true, "prepared": true, "monitorId": monitorId, "texture": previewTexture, "firstFrame": frameResult]
    }

    func renderFrame(projectId: String, monitorId: String, textureId: Int64, timelineMicros: Int64) throws -> [String: Any?] {
        guard let session = sessions[projectId] else {
            throw NSError(domain: "IosNleEngineManager", code: 24, userInfo: [NSLocalizedDescriptionKey: IosNleErrorCode.sessionNotFound])
        }
        guard let renderer = truePreviewRenderers[monitorId] else {
            throw NSError(domain: "IosNleEngineManager", code: 25, userInfo: [NSLocalizedDescriptionKey: "iOS true preview is not prepared for monitor \(monitorId)."])
        }
        session.seek(timelineMicros)
        let frame = try renderer.renderFrame(timelineMicros: session.playheadMicros)
        return try previewTextureManager.renderDecodedFrame(textureId: textureId, image: frame.image, projectId: projectId, sessionId: session.sessionId, monitorId: monitorId, timelineMicros: frame.timelineMicros, sourceMicros: frame.sourceMicros, assetPath: frame.assetPath)
    }

    func renderTruePreviewFrame(monitorId: String, timelineMicros: Int64) throws -> [String: Any?] {
        try requireInitialized()
        guard let projectId = truePreviewProjectIds[monitorId], let textureId = truePreviewTextureIds[monitorId] else {
            throw NSError(domain: "IosNleEngineManager", code: 26, userInfo: [NSLocalizedDescriptionKey: "iOS true preview is not prepared for monitor \(monitorId)."])
        }
        return try renderFrame(projectId: projectId, monitorId: monitorId, textureId: textureId, timelineMicros: timelineMicros)
    }

    func startTruePreview(monitorId: String, fromTimelineMicros: Int64) throws -> [String: Any?] {
        try requireInitialized()
        guard let projectId = truePreviewProjectIds[monitorId], let session = sessions[projectId] else {
            throw NSError(domain: "IosNleEngineManager", code: 27, userInfo: [NSLocalizedDescriptionKey: "iOS true preview is not prepared for monitor \(monitorId)."])
        }
        stopTruePreview(monitorId: monitorId)
        session.seek(fromTimelineMicros)
        session.play()
        let frameRate = max(1.0, frameRate(from: session.renderGraph))
        let intervalNanos = max(1_000_000, Int((1.0 / frameRate) * 1_000_000_000.0))
        let startWall = CFAbsoluteTimeGetCurrent()
        let startMicros = session.playheadMicros
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "ios.nle.truePreview.\(monitorId)"))
        timer.schedule(deadline: .now(), repeating: .nanoseconds(intervalNanos))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let elapsedMicros = Int64((CFAbsoluteTimeGetCurrent() - startWall) * 1_000_000.0)
            let target = startMicros + elapsedMicros
            do {
                if session.durationMicros > 0 && target >= session.durationMicros {
                    session.pause()
                    self.stopTruePreview(monitorId: monitorId)
                    self.eventEmitter.emit(IosNleEvent(type: "preview_ended", projectId: projectId, sessionId: session.sessionId, payload: ["monitorId": monitorId]))
                    return
                }
                _ = try self.renderTruePreviewFrame(monitorId: monitorId, timelineMicros: target)
            } catch {
                session.pause()
                self.stopTruePreview(monitorId: monitorId)
                self.eventEmitter.emit(IosNleEvent(type: "preview_error", projectId: projectId, sessionId: session.sessionId, payload: ["monitorId": monitorId, "message": error.localizedDescription]))
            }
        }
        playbackTimers[monitorId] = timer
        timer.resume()
        return ["success": true, "playing": true, "monitorId": monitorId]
    }

    func pauseTruePreview(monitorId: String) throws -> [String: Any?] {
        try requireInitialized()
        stopTruePreview(monitorId: monitorId)
        if let projectId = truePreviewProjectIds[monitorId] { sessions[projectId]?.pause() }
        return ["success": true, "paused": true, "monitorId": monitorId]
    }

    func stopTruePreview(monitorId: String) {
        playbackTimers[monitorId]?.cancel()
        playbackTimers.removeValue(forKey: monitorId)
    }

    func disposeTruePreview(monitorId: String) throws -> [String: Any?] {
        try requireInitialized()
        stopTruePreview(monitorId: monitorId)
        if let textureId = truePreviewTextureIds.removeValue(forKey: monitorId) { _ = try? previewTextureManager.disposePreviewTexture(textureId: textureId) }
        truePreviewRenderers.removeValue(forKey: monitorId)
        truePreviewProjectIds.removeValue(forKey: monitorId)
        return ["success": true, "disposed": true, "monitorId": monitorId]
    }

    private func frameRate(from graph: [String: Any]) -> Double {
        if let project = graph["project"] as? [String: Any], let number = project["frameRate"] as? NSNumber { return number.doubleValue }
        return 30.0
    }

    func startProxyJob(args: [String: Any?]) throws -> [String: Any?] {
        try requireInitialized()
        let projectId = args["projectId"] as? String
        let jobId = args.stringRequired("jobId")
        let assetId = args.stringRequired("assetId")
        let inputPath = args.stringRequired("inputPath")
        let outputPath = args.stringRequired("outputPath")
        IosNleProxyJobFoundation().start(projectId: projectId, jobId: jobId, assetId: assetId, inputPath: inputPath, outputPath: outputPath, eventEmitter: eventEmitter)
        return ["success": true, "jobId": jobId, "placeholder": true]
    }

    func cancelProxyJob(jobId: String) throws -> [String: Any?] {
        try requireInitialized()
        eventEmitter.emit(IosNleEvent(type: IosNleEventType.proxyCancelled, projectId: nil, sessionId: nil, jobId: jobId, payload: ["jobId": jobId, "platform": "ios"]))
        return ["success": true, "jobId": jobId]
    }

    func startExportJob(args: [String: Any?]) throws -> [String: Any?] {
        try requireInitialized()
        let projectId = args.stringRequired("projectId")
        let jobId = args.stringRequired("jobId")
        let renderGraphJson = args.stringRequired("renderGraphJson")
        let outputPath = args.stringRequired("outputPath")
        IosNleExportJobFoundation().start(projectId: projectId, jobId: jobId, renderGraphJson: renderGraphJson, outputPath: outputPath, eventEmitter: eventEmitter)
        return ["success": true, "jobId": jobId]
    }

    func cancelExportJob(jobId: String) throws -> [String: Any?] {
        try requireInitialized()
        eventEmitter.emit(IosNleEvent(type: IosNleEventType.exportCancelled, projectId: nil, sessionId: nil, jobId: jobId, payload: ["jobId": jobId, "platform": "ios"]))
        return ["success": true, "jobId": jobId]
    }
}

private extension Dictionary where Key == String, Value == Any? {
    func stringRequired(_ key: String) throws -> String {
        if let value = self[key] as? String, !value.isEmpty { return value }
        throw NSError(domain: "IosNleArguments", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(IosNleErrorCode.invalidArguments): missing string \(key)"])
    }
}
