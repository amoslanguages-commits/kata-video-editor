import Foundation
import AVFoundation

final class IosNleAvAssetReaderFoundation {
    func canRead(path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url)
        return asset.isReadable
    }
}

final class IosNleAvAssetWriterFoundation {
    func outputSettingsPlaceholder() -> [String: Any] {
        return [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
    }
}

final class IosNleProxyJobFoundation {
    func start(
        projectId: String?,
        jobId: String,
        assetId: String,
        inputPath: String,
        outputPath: String,
        eventEmitter: IosNleEventEmitter
    ) {
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.proxyStarted,
                projectId: projectId,
                sessionId: nil,
                jobId: jobId,
                payload: [
                    "jobId": jobId,
                    "assetId": assetId,
                    "inputPath": inputPath,
                    "outputPath": outputPath,
                    "progress": 0,
                    "stage": "Preparing iOS proxy"
                ]
            )
        )

        let inputUrl = URL(fileURLWithPath: inputPath)
        let outputUrl = URL(fileURLWithPath: outputPath)
        let asset = AVURLAsset(url: inputUrl)

        do {
            try FileManager.default.createDirectory(
                at: outputUrl.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: outputPath) {
                try FileManager.default.removeItem(at: outputUrl)
            }
        } catch {
            emitProxyFailed(
                projectId: projectId,
                jobId: jobId,
                assetId: assetId,
                code: IosNleErrorCode.commandFailed,
                message: "Could not prepare iOS proxy output.",
                technicalMessage: error.localizedDescription,
                eventEmitter: eventEmitter
            )
            return
        }

        let preset = AVAssetExportSession.exportPresets(compatibleWith: asset)
            .contains(AVAssetExportPreset960x540)
            ? AVAssetExportPreset960x540
            : AVAssetExportPresetMediumQuality

        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            emitProxyFailed(
                projectId: projectId,
                jobId: jobId,
                assetId: assetId,
                code: IosNleErrorCode.commandFailed,
                message: "Could not create iOS proxy export session.",
                technicalMessage: "AVAssetExportSession returned nil for preset \(preset).",
                eventEmitter: eventEmitter
            )
            return
        }

        session.outputURL = outputUrl
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true

        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.proxyProgress,
                projectId: projectId,
                sessionId: nil,
                jobId: jobId,
                payload: [
                    "jobId": jobId,
                    "assetId": assetId,
                    "progress": 10,
                    "stage": "Exporting iOS proxy"
                ]
            )
        )

        session.exportAsynchronously {
            switch session.status {
            case .completed:
                let fileSize = (try? FileManager.default
                    .attributesOfItem(atPath: outputPath)[.size] as? NSNumber)?
                    .int64Value ?? 0
                eventEmitter.emit(
                    IosNleEvent(
                        type: IosNleEventType.proxyCompleted,
                        projectId: projectId,
                        sessionId: nil,
                        jobId: jobId,
                        payload: [
                            "jobId": jobId,
                            "assetId": assetId,
                            "outputPath": outputPath,
                            "fileSize": fileSize,
                            "progress": 100,
                            "stage": "Complete"
                        ]
                    )
                )

            case .cancelled:
                eventEmitter.emit(
                    IosNleEvent(
                        type: IosNleEventType.proxyCancelled,
                        projectId: projectId,
                        sessionId: nil,
                        jobId: jobId,
                        payload: [
                            "jobId": jobId,
                            "assetId": assetId,
                            "stage": "Cancelled"
                        ]
                    )
                )

            default:
                self.emitProxyFailed(
                    projectId: projectId,
                    jobId: jobId,
                    assetId: assetId,
                    code: IosNleErrorCode.commandFailed,
                    message: "iOS proxy export failed.",
                    technicalMessage: session.error?.localizedDescription ?? "Status: \(session.status.rawValue)",
                    eventEmitter: eventEmitter
                )
            }
        }
    }

    private func emitProxyFailed(
        projectId: String?,
        jobId: String,
        assetId: String,
        code: String,
        message: String,
        technicalMessage: String,
        eventEmitter: IosNleEventEmitter
    ) {
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.proxyFailed,
                projectId: projectId,
                sessionId: nil,
                jobId: jobId,
                payload: [
                    "jobId": jobId,
                    "assetId": assetId,
                    "code": code,
                    "message": message,
                    "technicalMessage": technicalMessage
                ]
            )
        )
    }
}

final class IosNleExportJobFoundation {
    func start(
        projectId: String,
        jobId: String,
        renderGraphJson: String,
        outputPath: String,
        eventEmitter: IosNleEventEmitter
    ) {
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.exportStarted,
                projectId: projectId,
                sessionId: nil,
                jobId: jobId,
                payload: [
                    "jobId": jobId,
                    "outputPath": outputPath,
                    "progress": 0,
                    "stage": "Preparing iOS export"
                ]
            )
        )

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let composition = try self.buildComposition(renderGraphJson: renderGraphJson)
                let outputUrl = URL(fileURLWithPath: outputPath)

                try FileManager.default.createDirectory(
                    at: outputUrl.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                if FileManager.default.fileExists(atPath: outputPath) {
                    try FileManager.default.removeItem(at: outputUrl)
                }

                eventEmitter.emit(
                    IosNleEvent(
                        type: IosNleEventType.exportProgress,
                        projectId: projectId,
                        sessionId: nil,
                        jobId: jobId,
                        payload: [
                            "jobId": jobId,
                            "outputPath": outputPath,
                            "progress": 35,
                            "stage": "Composing timeline"
                        ]
                    )
                )

                guard let session = AVAssetExportSession(
                    asset: composition,
                    presetName: AVAssetExportPresetHighestQuality
                ) else {
                    throw NSError(
                        domain: "IosNleExportJobFoundation",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Could not create AVAssetExportSession."]
                    )
                }

                session.outputURL = outputUrl
                session.outputFileType = .mp4
                session.shouldOptimizeForNetworkUse = true

                eventEmitter.emit(
                    IosNleEvent(
                        type: IosNleEventType.exportProgress,
                        projectId: projectId,
                        sessionId: nil,
                        jobId: jobId,
                        payload: [
                            "jobId": jobId,
                            "outputPath": outputPath,
                            "progress": 70,
                            "stage": "Encoding"
                        ]
                    )
                )

                session.exportAsynchronously {
                    switch session.status {
                    case .completed:
                        let fileSize = (try? FileManager.default
                            .attributesOfItem(atPath: outputPath)[.size] as? NSNumber)?
                            .int64Value ?? 0
                        eventEmitter.emit(
                            IosNleEvent(
                                type: IosNleEventType.exportCompleted,
                                projectId: projectId,
                                sessionId: nil,
                                jobId: jobId,
                                payload: [
                                    "jobId": jobId,
                                    "stage": "Complete",
                                    "progress": 100,
                                    "result": [
                                        "outputPath": outputPath,
                                        "fileSize": fileSize,
                                        "platform": "ios_avfoundation_v1"
                                    ]
                                ]
                            )
                        )

                    case .cancelled:
                        eventEmitter.emit(
                            IosNleEvent(
                                type: IosNleEventType.exportCancelled,
                                projectId: projectId,
                                sessionId: nil,
                                jobId: jobId,
                                payload: [
                                    "jobId": jobId,
                                    "stage": "Cancelled"
                                ]
                            )
                        )

                    default:
                        self.emitExportFailed(
                            projectId: projectId,
                            jobId: jobId,
                            outputPath: outputPath,
                            code: IosNleErrorCode.commandFailed,
                            message: "iOS native export failed.",
                            technicalMessage: session.error?.localizedDescription ?? "Status: \(session.status.rawValue)",
                            eventEmitter: eventEmitter
                        )
                    }
                }
            } catch {
                self.emitExportFailed(
                    projectId: projectId,
                    jobId: jobId,
                    outputPath: outputPath,
                    code: IosNleErrorCode.commandFailed,
                    message: "Could not prepare iOS native export.",
                    technicalMessage: error.localizedDescription,
                    eventEmitter: eventEmitter
                )
            }
        }
    }

    private func buildComposition(renderGraphJson: String) throws -> AVMutableComposition {
        let data = Data(renderGraphJson.utf8)
        guard
            let graph = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let assets = graph["assets"] as? [[String: Any]],
            let clips = graph["clips"] as? [[String: Any]]
        else {
            throw NSError(
                domain: "IosNleExportJobFoundation",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Render graph is missing assets or clips."]
            )
        }

        let assetsById = Dictionary(
            uniqueKeysWithValues: assets.compactMap { asset -> (String, [String: Any])? in
                guard let id = asset["id"] as? String else { return nil }
                return (id, asset)
            }
        )

        let mediaClips = clips
            .filter { clip in
                let type = (clip["clipType"] as? String) ?? (clip["type"] as? String) ?? "video"
                return type != "text" && type != "audio" && ((clip["isDisabled"] as? Bool) != true)
            }
            .sorted {
                int64($0["timelineStartMicros"]) < int64($1["timelineStartMicros"])
            }

        if mediaClips.isEmpty {
            throw NSError(
                domain: "IosNleExportJobFoundation",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No exportable media clips in render graph."]
            )
        }

        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        for clip in mediaClips {
            guard
                let assetId = clip["assetId"] as? String,
                let assetNode = assetsById[assetId],
                let sourcePath = sourcePath(from: assetNode)
            else {
                continue
            }

            let asset = AVURLAsset(url: URL(fileURLWithPath: sourcePath))
            let sourceIn = int64(clip["sourceInMicros"])
            let sourceOut = int64(clip["sourceOutMicros"])
            let timelineStart = int64(clip["timelineStartMicros"])
            let timelineEnd = int64(clip["timelineEndMicros"])

            let durationMicros = max(1, min(
                sourceOut > sourceIn ? sourceOut - sourceIn : Int64.max,
                timelineEnd > timelineStart ? timelineEnd - timelineStart : Int64.max
            ))

            let sourceStart = CMTime(value: sourceIn, timescale: 1_000_000)
            let duration = CMTime(value: durationMicros, timescale: 1_000_000)
            let destination = CMTime(value: timelineStart, timescale: 1_000_000)
            let range = CMTimeRange(start: sourceStart, duration: duration)

            if let sourceVideo = asset.tracks(withMediaType: .video).first {
                try videoTrack?.insertTimeRange(range, of: sourceVideo, at: destination)
            }

            if let sourceAudio = asset.tracks(withMediaType: .audio).first {
                try audioTrack?.insertTimeRange(range, of: sourceAudio, at: destination)
            }
        }

        return composition
    }

    private func sourcePath(from assetNode: [String: Any]) -> String? {
        for key in ["exportPath", "originalPath", "proxyPath", "previewPath", "path"] {
            if let value = assetNode[key] as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func int64(_ value: Any?) -> Int64 {
        if let value = value as? Int64 { return value }
        if let value = value as? Int { return Int64(value) }
        if let value = value as? Double { return Int64(value) }
        if let value = value as? String, let parsed = Int64(value) { return parsed }
        return 0
    }

    private func emitExportFailed(
        projectId: String,
        jobId: String,
        outputPath: String,
        code: String,
        message: String,
        technicalMessage: String,
        eventEmitter: IosNleEventEmitter
    ) {
        eventEmitter.emit(
            IosNleEvent(
                type: IosNleEventType.exportFailed,
                projectId: projectId,
                sessionId: nil,
                jobId: jobId,
                payload: [
                    "jobId": jobId,
                    "code": code,
                    "message": message,
                    "technicalMessage": technicalMessage,
                    "outputPath": outputPath
                ]
            )
        )
    }
}
