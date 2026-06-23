import Foundation
import AVFoundation

final class IosNleCompositedExportRenderer {
    private let eventEmitter: IosNleEventEmitter

    init(eventEmitter: IosNleEventEmitter) {
        self.eventEmitter = eventEmitter
    }

    func start(
        projectId: String,
        jobId: String,
        renderGraphJson: String,
        outputPath: String
    ) throws -> [String: Any?] {
        let job = try parseJob(projectId: projectId, renderGraphJson: renderGraphJson, outputPath: outputPath)
        emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportStarted, payload: [
            "stage": "Preparing compositor",
            "progress": NSNumber(value: 0)
        ])

        let composition = AVMutableComposition()
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []

        for clip in job.videoClips {
            let asset = AVAsset(url: clip.assetUrl)
            guard let sourceVideoTrack = asset.tracks(withMediaType: .video).first else {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 20, userInfo: [NSLocalizedDescriptionKey: "Clip \(clip.id) source has no video track."])
            }
            guard let videoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 21, userInfo: [NSLocalizedDescriptionKey: "Could not create composition video track."])
            }

            let sourceRange = CMTimeRange(
                start: CMTime(value: clip.sourceStartMicros, timescale: 1_000_000),
                duration: CMTime(value: max(Int64(1), clip.sourceEndMicros - clip.sourceStartMicros), timescale: 1_000_000)
            )
            let timelineStart = CMTime(value: clip.timelineStartMicros, timescale: 1_000_000)
            try videoTrack.insertTimeRange(sourceRange, of: sourceVideoTrack, at: timelineStart)

            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            instruction.setTransform(sourceVideoTrack.preferredTransform, at: timelineStart)
            instruction.setOpacity(Float(clip.opacity), at: timelineStart)
            instruction.setOpacity(0, at: CMTime(value: clip.timelineEndMicros, timescale: 1_000_000))
            layerInstructions.append(instruction)

            if let sourceAudioTrack = asset.tracks(withMediaType: .audio).first,
               let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try? audioTrack.insertTimeRange(sourceRange, of: sourceAudioTrack, at: timelineStart)
            }
        }

        let videoInstruction = AVMutableVideoCompositionInstruction()
        videoInstruction.timeRange = CMTimeRange(
            start: .zero,
            duration: CMTime(value: max(Int64(1), job.durationMicros), timescale: 1_000_000)
        )
        videoInstruction.layerInstructions = layerInstructions.reversed()

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: job.width, height: job.height)
        videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(max(1, job.frameRate)))
        videoComposition.instructions = [videoInstruction]

        let outputUrl = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(
            at: outputUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        if FileManager.default.fileExists(atPath: outputPath) {
            try FileManager.default.removeItem(at: outputUrl)
        }

        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "IosNleCompositedExportRenderer", code: 22, userInfo: [NSLocalizedDescriptionKey: "Could not create composited AVAssetExportSession."])
        }
        session.outputURL = outputUrl
        session.outputFileType = .mp4
        session.videoComposition = videoComposition
        session.shouldOptimizeForNetworkUse = true

        startProgressTimer(jobId: jobId, projectId: projectId, session: session)

        session.exportAsynchronously { [weak self, weak session] in
            guard let self, let session else { return }
            switch session.status {
            case .completed:
                let size: Int64
                if let attrs = try? FileManager.default.attributesOfItem(atPath: outputPath),
                   let number = attrs[.size] as? NSNumber {
                    size = number.int64Value
                } else {
                    size = 0
                }
                self.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportCompleted, payload: [
                    "stage": "Complete",
                    "progress": NSNumber(value: 100),
                    "result": [
                        "outputPath": outputPath,
                        "fileSize": NSNumber(value: size),
                        "renderer": "ios_avfoundation_compositor_v1"
                    ]
                ])
            case .cancelled:
                self.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportCancelled, payload: ["stage": "Cancelled"])
            default:
                self.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportFailed, payload: [
                    "stage": "Failed",
                    "errorMessage": session.error?.localizedDescription ?? "iOS composited export failed."
                ])
            }
        }

        return ["success": true, "jobId": jobId, "accepted": true, "nativeRenderer": "ios_avfoundation_compositor_v1"]
    }

    private func startProgressTimer(jobId: String, projectId: String, session: AVAssetExportSession) {
        DispatchQueue.global(qos: .utility).async { [weak self, weak session] in
            var lastProgress = -1
            while let session, session.status == .exporting || session.status == .waiting {
                let progress = min(97, max(1, Int(session.progress * 97.0)))
                if progress != lastProgress {
                    lastProgress = progress
                    self?.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportProgress, payload: [
                        "stage": "Compositing",
                        "progress": NSNumber(value: progress)
                    ])
                }
                Thread.sleep(forTimeInterval: 0.25)
            }
        }
    }

    private func parseJob(projectId: String, renderGraphJson: String, outputPath: String) throws -> IosCompositedExportJob {
        let root = try parseRoot(renderGraphJson)
        let project = root["project"] as? [String: Any] ?? root
        let assets = array(root["assets"])
        let tracks = array(root["tracks"])
        var clips = array(root["clips"])
        if clips.isEmpty { clips = tracks.flatMap { array($0["clips"]) } }

        let width = int(project["width"]) ?? int(project["targetWidth"]) ?? 1920
        let height = int(project["height"]) ?? int(project["targetHeight"]) ?? 1080
        let frameRate = int(project["frameRate"]) ?? 30
        let duration = int64(project["durationMicros"]) ?? clips.map { int64($0["timelineEndMicros"]) ?? 0 }.max() ?? 0

        var videoClips: [IosCompositedClip] = []
        for clip in clips {
            if bool(clip["isDisabled"]) { continue }
            let type = string(clip["clipType"]) ?? string(clip["type"]) ?? "video"
            if type == "text" || type == "image" || type == "adjustment" {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 10, userInfo: [NSLocalizedDescriptionKey: "iOS composited export currently supports video layers only. Metal/AVAssetWriter overlay export is required for text/images."])
            }
            guard type == "video" else { continue }
            if (double(clip["speed"]) ?? 1.0) != 1.0 {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 11, userInfo: [NSLocalizedDescriptionKey: "iOS composited export does not support speed changes yet."])
            }
            guard let assetId = string(clip["assetId"]) ?? string(clip["asset_id"]),
                  let asset = assets.first(where: { string($0["id"]) == assetId }) else {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 12, userInfo: [NSLocalizedDescriptionKey: "A composited video clip is missing its asset."])
            }
            let path = string(asset["exportPath"]) ?? string(asset["sourcePath"]) ?? string(asset["originalPath"]) ?? string(asset["path"]) ?? ""
            guard !path.isEmpty else {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 13, userInfo: [NSLocalizedDescriptionKey: "A composited video asset path is missing."])
            }
            let start = int64(clip["timelineStartMicros"]) ?? 0
            let end = max(start + 1, int64(clip["timelineEndMicros"]) ?? start + 1)
            let sourceStart = int64(clip["sourceInMicros"]) ?? int64(clip["sourceStartMicros"]) ?? 0
            let sourceEnd = max(sourceStart + 1, int64(clip["sourceOutMicros"]) ?? int64(clip["sourceEndMicros"]) ?? sourceStart + (end - start))
            videoClips.append(IosCompositedClip(
                id: string(clip["id"]) ?? "clip_\(videoClips.count)",
                assetUrl: url(from: path),
                timelineStartMicros: start,
                timelineEndMicros: end,
                sourceStartMicros: sourceStart,
                sourceEndMicros: sourceEnd,
                opacity: double(clip["opacity"]) ?? 1.0
            ))
        }

        guard !videoClips.isEmpty else {
            throw NSError(domain: "IosNleCompositedExportRenderer", code: 14, userInfo: [NSLocalizedDescriptionKey: "No video layers found for composited export."])
        }

        return IosCompositedExportJob(
            projectId: projectId,
            width: width,
            height: height,
            frameRate: frameRate,
            durationMicros: max(Int64(1), duration),
            outputPath: outputPath,
            videoClips: videoClips
        )
    }

    private func parseRoot(_ json: String) throws -> [String: Any] {
        let data = Data(json.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let root = object as? [String: Any] else {
            throw NSError(domain: "IosNleCompositedExportRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid render graph JSON."])
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
    private func int(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        if let value = value as? String { return Int(value) }
        return nil
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

private struct IosCompositedExportJob {
    let projectId: String
    let width: Int
    let height: Int
    let frameRate: Int
    let durationMicros: Int64
    let outputPath: String
    let videoClips: [IosCompositedClip]
}

private struct IosCompositedClip {
    let id: String
    let assetUrl: URL
    let timelineStartMicros: Int64
    let timelineEndMicros: Int64
    let sourceStartMicros: Int64
    let sourceEndMicros: Int64
    let opacity: Double
}
