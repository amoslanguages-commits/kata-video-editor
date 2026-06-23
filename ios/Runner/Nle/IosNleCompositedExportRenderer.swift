import Foundation
import AVFoundation
import UIKit
import QuartzCore

final class IosNleCompositedExportRenderer {
    private let eventEmitter: IosNleEventEmitter
    private var sessions: [String: AVAssetExportSession] = [:]
    private let lock = NSLock()

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
        emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportStarted, payload: ["stage": "Preparing compositor", "progress": NSNumber(value: 0)])

        let composition = AVMutableComposition()
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []

        for clip in job.videoClips {
            let asset = AVAsset(url: clip.assetUrl)
            guard let sourceVideoTrack = asset.tracks(withMediaType: .video).first else {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 20, userInfo: [NSLocalizedDescriptionKey: "Clip \(clip.id) source has no video track."])
            }
            guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 21, userInfo: [NSLocalizedDescriptionKey: "Could not create composition video track."])
            }

            let sourceDurationMicros = max(Int64(1), clip.sourceEndMicros - clip.sourceStartMicros)
            let timelineDurationMicros = max(Int64(1), clip.timelineEndMicros - clip.timelineStartMicros)
            let sourceRange = CMTimeRange(
                start: CMTime(value: clip.sourceStartMicros, timescale: 1_000_000),
                duration: CMTime(value: sourceDurationMicros, timescale: 1_000_000)
            )
            let timelineStart = CMTime(value: clip.timelineStartMicros, timescale: 1_000_000)
            let timelineDuration = CMTime(value: timelineDurationMicros, timescale: 1_000_000)
            try videoTrack.insertTimeRange(sourceRange, of: sourceVideoTrack, at: timelineStart)
            if sourceDurationMicros != timelineDurationMicros {
                videoTrack.scaleTimeRange(CMTimeRange(start: timelineStart, duration: sourceRange.duration), toDuration: timelineDuration)
            }

            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            instruction.setTransform(sourceVideoTrack.preferredTransform, at: timelineStart)
            instruction.setOpacity(Float(clip.opacity), at: timelineStart)
            instruction.setOpacity(0, at: CMTime(value: clip.timelineEndMicros, timescale: 1_000_000))
            layerInstructions.append(instruction)

            if let sourceAudioTrack = asset.tracks(withMediaType: .audio).first,
               let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try? audioTrack.insertTimeRange(sourceRange, of: sourceAudioTrack, at: timelineStart)
                if sourceDurationMicros != timelineDurationMicros {
                    audioTrack.scaleTimeRange(CMTimeRange(start: timelineStart, duration: sourceRange.duration), toDuration: timelineDuration)
                }
            }
        }

        let videoInstruction = AVMutableVideoCompositionInstruction()
        videoInstruction.timeRange = CMTimeRange(start: .zero, duration: CMTime(value: max(Int64(1), job.durationMicros), timescale: 1_000_000))
        videoInstruction.layerInstructions = Array(layerInstructions.reversed())

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: job.width, height: job.height)
        videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(max(1, job.frameRate)))
        videoComposition.instructions = [videoInstruction]
        attachOverlayLayers(videoComposition: videoComposition, job: job)

        let outputUrl = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(at: outputUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        if FileManager.default.fileExists(atPath: outputPath) { try FileManager.default.removeItem(at: outputUrl) }

        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "IosNleCompositedExportRenderer", code: 22, userInfo: [NSLocalizedDescriptionKey: "Could not create composited AVAssetExportSession."])
        }
        session.outputURL = outputUrl
        session.outputFileType = .mp4
        session.videoComposition = videoComposition
        session.shouldOptimizeForNetworkUse = true

        lock.lock()
        sessions[jobId] = session
        lock.unlock()

        startProgressTimer(jobId: jobId, projectId: projectId, session: session)

        session.exportAsynchronously { [weak self, weak session] in
            guard let self, let session else { return }
            self.lock.lock()
            self.sessions.removeValue(forKey: jobId)
            self.lock.unlock()
            switch session.status {
            case .completed:
                let size: Int64
                if let attrs = try? FileManager.default.attributesOfItem(atPath: outputPath), let number = attrs[.size] as? NSNumber { size = number.int64Value } else { size = 0 }
                self.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportCompleted, payload: [
                    "stage": "Complete",
                    "progress": NSNumber(value: 100),
                    "result": ["outputPath": outputPath, "fileSize": NSNumber(value: size), "renderer": "ios_avfoundation_compositor_v3_overlays_speed"]
                ])
            case .cancelled:
                self.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportCancelled, payload: ["stage": "Cancelled"])
            default:
                self.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportFailed, payload: ["stage": "Failed", "errorMessage": session.error?.localizedDescription ?? "iOS composited export failed."])
            }
        }

        return ["success": true, "jobId": jobId, "accepted": true, "nativeRenderer": "ios_avfoundation_compositor_v3_overlays_speed"]
    }

    func cancel(jobId: String) -> [String: Any?] {
        lock.lock()
        let session = sessions.removeValue(forKey: jobId)
        lock.unlock()
        session?.cancelExport()
        return ["success": true, "jobId": jobId, "cancelled": true]
    }

    private func attachOverlayLayers(videoComposition: AVMutableVideoComposition, job: IosCompositedExportJob) {
        guard !job.overlayClips.isEmpty else { return }
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        let frame = CGRect(x: 0, y: 0, width: job.width, height: job.height)
        parentLayer.frame = frame
        videoLayer.frame = frame
        parentLayer.addSublayer(videoLayer)

        for overlay in job.overlayClips {
            let layer: CALayer?
            switch overlay.kind {
            case "text": layer = makeTextLayer(overlay: overlay, job: job)
            case "image": layer = makeImageLayer(overlay: overlay, job: job)
            default: layer = nil
            }
            guard let layer else { continue }
            addVisibilityAnimation(to: layer, overlay: overlay, durationMicros: job.durationMicros)
            parentLayer.addSublayer(layer)
        }

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }

    private func makeTextLayer(overlay: IosOverlayClip, job: IosCompositedExportJob) -> CALayer {
        let textLayer = CATextLayer()
        textLayer.string = overlay.text ?? ""
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = max(18, CGFloat(job.height) * 0.055 * CGFloat(overlay.scale))
        textLayer.opacity = Float(overlay.opacity)
        textLayer.frame = overlayFrame(overlay: overlay, job: job, defaultWidth: Double(job.width) * 0.8, defaultHeight: Double(job.height) * 0.18)
        return textLayer
    }

    private func makeImageLayer(overlay: IosOverlayClip, job: IosCompositedExportJob) -> CALayer? {
        guard let url = overlay.assetUrl, let image = UIImage(contentsOfFile: url.path) else { return nil }
        let layer = CALayer()
        layer.contents = image.cgImage
        layer.contentsGravity = .resizeAspect
        layer.opacity = Float(overlay.opacity)
        let defaultWidth = image.size.width > 0 ? min(Double(job.width), Double(image.size.width)) : Double(job.width) * 0.5
        let defaultHeight = image.size.height > 0 ? min(Double(job.height), Double(image.size.height)) : Double(job.height) * 0.5
        layer.frame = overlayFrame(overlay: overlay, job: job, defaultWidth: defaultWidth, defaultHeight: defaultHeight)
        return layer
    }

    private func overlayFrame(overlay: IosOverlayClip, job: IosCompositedExportJob, defaultWidth: Double, defaultHeight: Double) -> CGRect {
        let width = defaultWidth * overlay.scale
        let height = defaultHeight * overlay.scale
        let centerX = Double(job.width) * 0.5 + overlay.positionX
        let centerY = Double(job.height) * 0.5 - overlay.positionY
        return CGRect(x: centerX - width * 0.5, y: centerY - height * 0.5, width: width, height: height)
    }

    private func addVisibilityAnimation(to layer: CALayer, overlay: IosOverlayClip, durationMicros: Int64) {
        let total = max(0.001, Double(durationMicros) / 1_000_000.0)
        let start = max(0.0, min(1.0, Double(overlay.timelineStartMicros) / Double(max(Int64(1), durationMicros))))
        let end = max(start, min(1.0, Double(overlay.timelineEndMicros) / Double(max(Int64(1), durationMicros))))
        let epsilon = min(0.001, max(0.0, end - start))
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = total
        animation.keyTimes = [
            NSNumber(value: 0),
            NSNumber(value: start),
            NSNumber(value: min(1.0, start + epsilon)),
            NSNumber(value: end),
            NSNumber(value: min(1.0, end + epsilon)),
            NSNumber(value: 1),
        ]
        animation.values = [0, 0, overlay.opacity, overlay.opacity, 0, 0]
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: "timelineOpacity")
    }

    private func startProgressTimer(jobId: String, projectId: String, session: AVAssetExportSession) {
        DispatchQueue.global(qos: .utility).async { [weak self, weak session] in
            var lastProgress = -1
            while let session, session.status == .exporting || session.status == .waiting {
                let progress = min(97, max(1, Int(session.progress * 97.0)))
                if progress != lastProgress {
                    lastProgress = progress
                    self?.emit(jobId: jobId, projectId: projectId, type: IosNleEventType.exportProgress, payload: ["stage": "Compositing", "progress": NSNumber(value: progress)])
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
        var overlayClips: [IosOverlayClip] = []
        for clip in clips {
            if bool(clip["isDisabled"]) { continue }
            let type = string(clip["clipType"]) ?? string(clip["type"]) ?? "video"
            if type == "adjustment" { continue }
            if type == "text" {
                overlayClips.append(parseOverlayClip(clip: clip, kind: "text", asset: nil))
                continue
            }
            guard let assetId = string(clip["assetId"]) ?? string(clip["asset_id"]), let asset = assets.first(where: { string($0["id"]) == assetId }) else {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 12, userInfo: [NSLocalizedDescriptionKey: "A composited clip is missing its asset."])
            }
            let path = string(asset["exportPath"]) ?? string(asset["sourcePath"]) ?? string(asset["originalPath"]) ?? string(asset["path"]) ?? ""
            guard !path.isEmpty else {
                throw NSError(domain: "IosNleCompositedExportRenderer", code: 13, userInfo: [NSLocalizedDescriptionKey: "A composited asset path is missing."])
            }
            if type == "image" {
                overlayClips.append(parseOverlayClip(clip: clip, kind: "image", asset: asset))
                continue
            }
            guard type == "video" else { continue }
            let start = int64(clip["timelineStartMicros"]) ?? 0
            let end = max(start + 1, int64(clip["timelineEndMicros"]) ?? start + 1)
            let speed = max(0.01, double(clip["speed"]) ?? 1.0)
            let sourceStart = int64(clip["sourceInMicros"]) ?? int64(clip["sourceStartMicros"]) ?? 0
            let defaultSourceEnd = sourceStart + Int64(Double(end - start) * speed)
            let sourceEnd = max(sourceStart + 1, int64(clip["sourceOutMicros"]) ?? int64(clip["sourceEndMicros"]) ?? defaultSourceEnd)
            videoClips.append(IosCompositedClip(
                id: string(clip["id"]) ?? "clip_\(videoClips.count)",
                assetUrl: url(from: path),
                timelineStartMicros: start,
                timelineEndMicros: end,
                sourceStartMicros: sourceStart,
                sourceEndMicros: sourceEnd,
                speed: speed,
                opacity: double(clip["opacity"]) ?? 1.0
            ))
        }

        guard !videoClips.isEmpty else {
            throw NSError(domain: "IosNleCompositedExportRenderer", code: 14, userInfo: [NSLocalizedDescriptionKey: "No video layers found for composited export."])
        }

        return IosCompositedExportJob(projectId: projectId, width: width, height: height, frameRate: frameRate, durationMicros: max(Int64(1), duration), outputPath: outputPath, videoClips: videoClips, overlayClips: overlayClips)
    }

    private func parseOverlayClip(clip: [String: Any], kind: String, asset: [String: Any]?) -> IosOverlayClip {
        let path = asset.flatMap { string($0["exportPath"]) ?? string($0["sourcePath"]) ?? string($0["originalPath"]) ?? string($0["path"]) }
        let start = int64(clip["timelineStartMicros"]) ?? 0
        let end = max(start + 1, int64(clip["timelineEndMicros"]) ?? start + 1)
        let transform = clip["transform"] as? [String: Any]
        return IosOverlayClip(
            id: string(clip["id"]) ?? "overlay_\(kind)",
            kind: kind,
            assetUrl: path.map { url(from: $0) },
            text: string(clip["textContent"]) ?? (clip["text"] as? [String: Any]).flatMap { string($0["content"]) },
            timelineStartMicros: start,
            timelineEndMicros: end,
            positionX: double(clip["positionX"]) ?? transform.flatMap { double($0["positionX"]) } ?? 0,
            positionY: double(clip["positionY"]) ?? transform.flatMap { double($0["positionY"]) } ?? 0,
            scale: max(0.01, double(clip["scale"]) ?? transform.flatMap { double($0["scale"]) } ?? 1),
            opacity: max(0, min(1, double(clip["opacity"]) ?? transform.flatMap { double($0["opacity"]) } ?? 1))
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
    let overlayClips: [IosOverlayClip]
}

private struct IosCompositedClip {
    let id: String
    let assetUrl: URL
    let timelineStartMicros: Int64
    let timelineEndMicros: Int64
    let sourceStartMicros: Int64
    let sourceEndMicros: Int64
    let speed: Double
    let opacity: Double
}

private struct IosOverlayClip {
    let id: String
    let kind: String
    let assetUrl: URL?
    let text: String?
    let timelineStartMicros: Int64
    let timelineEndMicros: Int64
    let positionX: Double
    let positionY: Double
    let scale: Double
    let opacity: Double
}
