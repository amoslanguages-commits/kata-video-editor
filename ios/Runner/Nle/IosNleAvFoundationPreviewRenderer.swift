import Foundation
import AVFoundation
import CoreGraphics

final class IosNleAvFoundationPreviewRenderer {
    struct RenderedFrame {
        let image: CGImage
        let timelineMicros: Int64
        let sourceMicros: Int64
        let assetPath: String
    }

    private let renderGraph: [String: Any]
    private let preferProxy: Bool

    init(renderGraph: [String: Any], preferProxy: Bool) {
        self.renderGraph = renderGraph
        self.preferProxy = preferProxy
    }

    func renderFrame(timelineMicros: Int64) throws -> RenderedFrame {
        let assetsById = buildAssetIndex()
        guard let clip = activeVideoClip(at: timelineMicros, assetsById: assetsById) else {
            throw NSError(
                domain: "IosNleAvFoundationPreviewRenderer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No active video clip at \(timelineMicros)µs."]
            )
        }

        guard let assetId = clip["assetId"] as? String,
              let asset = assetsById[assetId] else {
            throw NSError(
                domain: "IosNleAvFoundationPreviewRenderer",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Active clip is missing its media asset."]
            )
        }

        let path = resolvedPath(for: asset)
        guard !path.isEmpty else {
            throw NSError(
                domain: "IosNleAvFoundationPreviewRenderer",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Media asset has no readable path."]
            )
        }

        let sourceMicros = sourceTimeMicros(for: clip, timelineMicros: timelineMicros)
        let url = fileUrl(from: path)
        let avAsset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let time = CMTime(value: sourceMicros, timescale: 1_000_000)
        var actualTime = CMTime.zero
        let image = try generator.copyCGImage(at: time, actualTime: &actualTime)

        return RenderedFrame(
            image: image,
            timelineMicros: timelineMicros,
            sourceMicros: Int64(CMTimeGetSeconds(actualTime) * 1_000_000.0),
            assetPath: path
        )
    }

    private func buildAssetIndex() -> [String: [String: Any]] {
        guard let assets = renderGraph["assets"] as? [[String: Any]] else {
            return [:]
        }
        var result: [String: [String: Any]] = [:]
        for asset in assets {
            if let id = asset["id"] as? String {
                result[id] = asset
            }
        }
        return result
    }

    private func activeVideoClip(
        at timelineMicros: Int64,
        assetsById: [String: [String: Any]]
    ) -> [String: Any]? {
        guard let tracks = renderGraph["tracks"] as? [[String: Any]] else {
            return nil
        }

        var matches: [([String: Any], Int, Int)] = []

        for track in tracks {
            let hidden = bool(track["isHidden"])
            let visual = bool(track["isVisual"])
            if hidden || !visual { continue }

            let layerOrder = int(track["layerOrder"]) ?? int(track["sortOrder"]) ?? 0
            let clips = track["clips"] as? [[String: Any]] ?? []
            for clip in clips {
                if bool(clip["isDisabled"]) { continue }
                guard let assetId = clip["assetId"] as? String,
                      let asset = assetsById[assetId],
                      bool(asset["hasVideo"]) else {
                    continue
                }
                let start = int64(clip["timelineStartMicros"]) ?? 0
                let end = int64(clip["timelineEndMicros"]) ?? start
                if timelineMicros >= start && timelineMicros < end {
                    matches.append((clip, layerOrder, int(clip["zIndex"]) ?? 0))
                }
            }
        }

        return matches.sorted { lhs, rhs in
            if lhs.1 == rhs.1 { return lhs.2 < rhs.2 }
            return lhs.1 < rhs.1
        }.last?.0
    }

    private func sourceTimeMicros(for clip: [String: Any], timelineMicros: Int64) -> Int64 {
        let timelineStart = int64(clip["timelineStartMicros"]) ?? 0
        let sourceStart = int64(clip["sourceStartMicros"]) ?? 0
        let speed = double(clip["speed"]) ?? 1.0
        let offset = max(0, timelineMicros - timelineStart)
        return sourceStart + Int64(Double(offset) * max(speed, 0.0001))
    }

    private func resolvedPath(for asset: [String: Any]) -> String {
        if preferProxy,
           let proxy = asset["proxyPath"] as? String,
           !proxy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return proxy
        }
        return (asset["originalPath"] as? String) ?? ""
    }

    private func fileUrl(from path: String) -> URL {
        if path.hasPrefix("file://"), let url = URL(string: path) {
            return url
        }
        return URL(fileURLWithPath: path)
    }

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
}
