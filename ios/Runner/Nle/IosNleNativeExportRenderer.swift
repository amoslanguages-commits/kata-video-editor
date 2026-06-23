import Foundation
import AVFoundation

final class IosNleNativeExportRenderer {
    private let eventEmitter: IosNleEventEmitter
    private let compositedRenderer: IosNleCompositedExportRenderer
    private var sessions: [String: AVAssetExportSession] = [:]
    private let lock = NSLock()

    init(eventEmitter: IosNleEventEmitter) {
        self.eventEmitter = eventEmitter
        self.compositedRenderer = IosNleCompositedExportRenderer(eventEmitter: eventEmitter)
    }

    func start(
        projectId: String,
        jobId: String,
        renderGraphJson: String,
        outputPath: String
    ) throws -> [String: Any?] {
        if requiresCompositedExport(renderGraphJson) {
            return try compositedRenderer.start(
                projectId: projectId,
                jobId: jobId,
                renderGraphJson: renderGraphJson,
                outputPath: outputPath
            )
        }

        let job = try parseSingleClipJob(projectId: projectId, renderGraphJson: renderGraphJson, outputPath: outputPath)

        emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportStarted, payload: ["stage": "Preparing", "progress": NSNumber(value: 0)])

        let composition = AVMutableComposition()
        let asset = AVAsset(url: job.assetUrl)
        let sourceStart = CMTime(value: job.sourceStartMicros, timescale: 1_000_000)
        let durationMicros = max(Int64(1), job.sourceEndMicros - job.sourceStartMicros)
        let sourceDuration = CMTime(value: durationMicros, timescale: 1_000_000)
        let sourceRange = CMTimeRange(start: sourceStart, duration: sourceDuration)

        guard let sourceVideoTrack = asset.tracks(withMediaType: .video).first else {
            throw NSError(domain: "IosNleNativeExportRenderer", code: 10, userInfo: [NSLocalizedDescriptionKey: "Source asset has no video track."])
        }
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "IosNleNativeExportRenderer", code: 11, userInfo: [NSLocalizedDescriptionKey: "Could not create video composition track."])
        }

        try compositionVideoTrack.insertTimeRange(sourceRange, of: sourceVideoTrack, at: .zero)
        compositionVideoTrack.preferredTransform = sourceVideoTrack.preferredTransform

        if let sourceAudioTrack = asset.tracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? compositionAudioTrack.insertTimeRange(sourceRange, of: sourceAudioTrack, at: .zero)
        }

        let outputUrl = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(at: outputUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        if FileManager.default.fileExists(atPath: outputPath) { try FileManager.default.removeItem(at: outputUrl) }

        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "IosNleNativeExportRenderer", code: 12, userInfo: [NSLocalizedDescriptionKey: "Could not create AVAssetExportSession."])
        }

        session.outputURL = outputUrl
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true

        lock.lock()
        sessions[jobId] = session
        lock.unlock()

        startProgressTimer(jobId: jobId, projectId: projectId, session: session)

        session.exportAsynchronously { [weak self, weak session] in
            guard let self else { return }
            self.lock.lock()
            self.sessions.removeValue(forKey: jobId)
            self.lock.unlock()
            guard let session else { return }
            switch session.status {
            case .completed:
                let size: Int64
                if let attrs = try? FileManager.default.attributesOfItem(atPath: outputPath), let number = attrs[.size] as? NSNumber { size = number.int64Value } else { size = 0 }
                self.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportCompleted, payload: [
                    "stage": "Complete",
                    "progress": NSNumber(value: 100),
                    "result": ["outputPath": outputPath, "fileSize": NSNumber(value: size), "renderer": "ios_avasset_export_session_v1"]
                ])
            case .cancelled:
                self.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportCancelled, payload: ["stage": "Cancelled"])
            default:
                self.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportFailed, payload: ["stage": "Failed", "errorMessage": session.error?.localizedDescription ?? "iOS native export failed."])
            }
        }

        return ["success": true, "jobId": jobId, "accepted": true, "nativeRenderer": "ios_avasset_export_session_v1"]
    }

    func cancel(jobId: String) -> [String: Any?] {
        lock.lock()
        let session = sessions.removeValue(forKey: jobId)
        lock.unlock()
        if let session {
            session.cancelExport()
            return ["success": true, "jobId": jobId, "cancelled": true]
        }
        return compositedRenderer.cancel(jobId: jobId)
    }

    private func startProgressTimer(jobId: String, projectId: String, session: AVAssetExportSession) {
        DispatchQueue.global(qos: .utility).async { [weak self, weak session] in
            var lastProgress = -1
            while let session, session.status == .exporting || session.status == .waiting {
                let progress = min(97, max(1, Int(session.progress * 97.0)))
                if progress != lastProgress {
                    lastProgress = progress
                    self?.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportProgress, payload: ["stage": "Exporting", "progress": NSNumber(value: progress)])
                }
                Thread.sleep(forTimeInterval: 0.25)
            }
        }
    }

    private func requiresCompositedExport(_ renderGraphJson: String) -> Bool {
        guard let root = try? parseRoot(renderGraphJson) else { return false }
        let tracks = array(root["tracks"])
        var clips = array(root["clips"])
        if clips.isEmpty { clips = tracks.flatMap { array($0["clips"]) } }
        let enabled = clips.filter { !bool($0["isDisabled"]) }
        guard enabled.count == 1 else { return true }
        let clip = enabled[0]
        let type = string(clip["clipType"]) ?? string(clip["type"]) ?? "video"
        if type != "video" { return true }
        if (double(clip["speed"]) ?? 1.0) != 1.0 { return true }
        if (double(clip["opacity"]) ?? 1.0) != 1.0 { return true }
        return false
    }

    private func parseSingleClipJob(projectId: String, renderGraphJson: String, outputPath: String) throws -> IosExportJobDescriptor {
        let root = try parseRoot(renderGraphJson)
        let assets = array(root["assets"])
        let tracks = array(root["tracks"])
        var clips = array(root["clips"])
        if clips.isEmpty { clips = tracks.flatMap { array($0["clips"]) } }
        let visualClips = clips.filter { clip in
            if bool(clip["isDisabled"]) { return false }
            let type = string(clip["clipType"]) ?? string(clip["type"]) ?? "video"
            return type == "video"
        }
        guard visualClips.count == 1, clips.count == 1 else {
            throw NSError(domain: "IosNleNativeExportRenderer", code: 2, userInfo: [NSLocalizedDescriptionKey: "iOS native export currently supports exactly one video clip without overlays/text."])
        }
        let clip = visualClips[0]
        if (double(clip["speed"]) ?? 1.0) != 1.0 {
            throw NSError(domain: "IosNleNativeExportRenderer", code: 3, userInfo: [NSLocalizedDescriptionKey: "iOS native pass-through export does not support speed changes yet."])
        }
        let assetId = string(clip["assetId"]) ?? string(clip["asset_id"])
        guard let asset = assets.first(where: { string($0["id"]) == assetId }) else {
            throw NSError(domain: "IosNleNativeExportRenderer", code: 4, userInfo: [NSLocalizedDescriptionKey: "Export asset was not found."])
        }
        let path = string(asset["exportPath"]) ?? string(asset["sourcePath"]) ?? string(asset["originalPath"]) ?? string(asset["path"]) ?? ""
        guard !path.isEmpty else {
            throw NSError(domain: "IosNleNativeExportRenderer", code: 5, userInfo: [NSLocalizedDescriptionKey: "Export asset path is missing."])
        }
        let sourceStart = int64(clip["sourceInMicros"]) ?? int64(clip["sourceStartMicros"]) ?? 0
        let fallbackEnd = sourceStart + ((int64(clip["timelineEndMicros"]) ?? 0) - (int64(clip["timelineStartMicros"]) ?? 0))
        let sourceEnd = max(sourceStart + 1, int64(clip["sourceOutMicros"]) ?? int64(clip["sourceEndMicros"]) ?? fallbackEnd)
        return IosExportJobDescriptor(projectId: projectId, assetUrl: url(from: path), sourceStartMicros: sourceStart, sourceEndMicros: sourceEnd, outputPath: outputPath)
    }

    private func parseRoot(_ json: String) throws -> [String: Any] {
        let data = Data(json.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let root = object as? [String: Any] else {
            throw NSError(domain: "IosNleNativeExportRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid render graph JSON."])
        }
        return root
    }

    private func emit(jobId: String, projectId: String?, type: String, payload: [String: Any?]) {
        eventEmitter.emit(IosNleEvent(type: type, projectId: projectId, sessionId: nil, jobId: jobId, payload: payload))
    }

    private func array(_ value: Any?) -> [[String: Any]] { value as? [[String: Any]] ?? [] }
    private func string(_ value: Any?) -> String? { (value as? String).flatMap { $0.isEmpty ? nil : $0 } }
    private func bool(_ value: Any?) -> Bool {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        if let value = value as? String { return value.lowercased() == "true" }
        return false
    }
    private func int64(_ value: Any?) -> Int64? {
        if let value = value as? Int64 { return value }
        if let value = value as? Int { return Int64(value) }
        if let value = value as? NSNumber { return value.int64Value }
        if let value = value as? String { return Int64(value) }
        return nil
    }
    private func double(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }
    private func url(from path: String) -> URL {
        if path.hasPrefix("file://"), let url = URL(string: path) { return url }
        return URL(fileURLWithPath: path)
    }
}

private struct IosExportJobDescriptor {
    let projectId: String
    let assetUrl: URL
    let sourceStartMicros: Int64
    let sourceEndMicros: Int64
    let outputPath: String
}
