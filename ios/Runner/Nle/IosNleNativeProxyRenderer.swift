import Foundation
import AVFoundation

final class IosNleNativeProxyRenderer {
    private let eventEmitter: IosNleEventEmitter
    private let onFinished: ((String) -> Void)?
    private var sessions: [String: AVAssetExportSession] = [:]
    private let lock = NSLock()

    init(eventEmitter: IosNleEventEmitter, onFinished: ((String) -> Void)? = nil) {
        self.eventEmitter = eventEmitter
        self.onFinished = onFinished
    }

    func start(
        projectId: String?,
        jobId: String,
        assetId: String,
        inputPath: String,
        outputPath: String,
        profile: [String: Any?]
    ) throws -> [String: Any?] {
        emit(jobId: jobId, projectId: projectId, type: "proxy_started", payload: [
            "assetId": assetId,
            "stage": "Preparing",
            "progress": NSNumber(value: 0)
        ])

        let inputUrl = url(from: inputPath)
        let outputUrl = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(
            at: outputUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        if FileManager.default.fileExists(atPath: outputPath) {
            try FileManager.default.removeItem(at: outputUrl)
        }

        let asset = AVAsset(url: inputUrl)
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: presetName(from: profile)
        ) else {
            throw NSError(domain: "IosNleNativeProxyRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create AVAssetExportSession for proxy."])
        }
        session.outputURL = outputUrl
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true

        lock.lock()
        sessions[jobId] = session
        lock.unlock()

        startProgressTimer(jobId: jobId, projectId: projectId, assetId: assetId, session: session)

        session.exportAsynchronously { [weak self, weak session] in
            guard let self, let session else { return }
            defer { self.onFinished?(jobId) }
            self.lock.lock()
            self.sessions.removeValue(forKey: jobId)
            self.lock.unlock()

            switch session.status {
            case .completed:
                let size: Int64
                if let attrs = try? FileManager.default.attributesOfItem(atPath: outputPath),
                   let number = attrs[.size] as? NSNumber {
                    size = number.int64Value
                } else {
                    size = 0
                }
                self.emit(jobId: jobId, projectId: projectId, type: "proxy_completed", payload: [
                    "assetId": assetId,
                    "proxyPath": outputPath,
                    "outputPath": outputPath,
                    "proxyCodec": "h264/aac-mp4",
                    "fileSize": NSNumber(value: size),
                    "renderer": "ios_avasset_proxy_v1"
                ])
            case .cancelled:
                self.emit(jobId: jobId, projectId: projectId, type: "proxy_cancelled", payload: [
                    "assetId": assetId,
                    "stage": "Cancelled"
                ])
            default:
                try? FileManager.default.removeItem(at: outputUrl)
                self.emit(jobId: jobId, projectId: projectId, type: "proxy_failed", payload: [
                    "assetId": assetId,
                    "stage": "Failed",
                    "errorMessage": session.error?.localizedDescription ?? "iOS proxy export failed."
                ])
            }
        }

        return ["success": true, "jobId": jobId, "assetId": assetId, "accepted": true, "nativeRenderer": "ios_avasset_proxy_v1"]
    }

    func cancel(jobId: String) -> [String: Any?] {
        lock.lock()
        let session = sessions.removeValue(forKey: jobId)
        lock.unlock()
        session?.cancelExport()
        onFinished?(jobId)
        return ["success": true, "jobId": jobId, "cancelled": true]
    }

    private func startProgressTimer(jobId: String, projectId: String?, assetId: String, session: AVAssetExportSession) {
        DispatchQueue.global(qos: .utility).async { [weak self, weak session] in
            var lastProgress = -1
            while let session, session.status == .waiting || session.status == .exporting {
                let progress = min(98, max(1, Int(session.progress * 98.0)))
                if progress != lastProgress {
                    lastProgress = progress
                    self?.emit(jobId: jobId, projectId: projectId, type: "proxy_progress", payload: [
                        "assetId": assetId,
                        "stage": "Transcoding",
                        "progress": NSNumber(value: progress)
                    ])
                }
                Thread.sleep(forTimeInterval: 0.25)
            }
        }
    }

    private func presetName(from profile: [String: Any?]) -> String {
        let height = int(profile["height"]) ?? int(profile["targetHeight"]) ?? int(profile["proxyHeight"]) ?? 720
        if height <= 540 { return AVAssetExportPreset960x540 }
        if height <= 720 { return AVAssetExportPreset1280x720 }
        return AVAssetExportPreset1920x1080
    }

    private func int(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        if let value = value as? String { return Int(value) }
        return nil
    }

    private func url(from path: String) -> URL {
        if path.hasPrefix("file://"), let url = URL(string: path) { return url }
        return URL(fileURLWithPath: path)
    }

    private func emit(jobId: String, projectId: String?, type: String, payload: [String: Any?]) {
        eventEmitter.emit(IosNleEvent(type: type, projectId: projectId, sessionId: nil, jobId: jobId, payload: payload))
    }
}
