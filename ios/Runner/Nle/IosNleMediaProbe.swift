import Foundation
import AVFoundation

final class IosNleMediaProbe {
    func probe(path: String) async throws -> [String: Any?] {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw NSError(
                domain: "IosNleMediaProbe",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Media file does not exist."]
            )
        }

        let asset = AVURLAsset(url: url)

        let duration = try await asset.load(.duration)
        let tracks = try await asset.load(.tracks)

        let videoTrack = tracks.first { $0.mediaType == .video }
        let audioTrack = tracks.first { $0.mediaType == .audio }

        var width = 0
        var height = 0
        var frameRate: Float = 0
        var transform: CGAffineTransform = .identity

        if let videoTrack {
            let naturalSize = try await videoTrack.load(.naturalSize)
            transform = try await videoTrack.load(.preferredTransform)
            frameRate = try await videoTrack.load(.nominalFrameRate)

            width = Int(abs(naturalSize.width))
            height = Int(abs(naturalSize.height))
        }

        let rotation = rotationDegrees(from: transform)

        return [
            "path": path,
            "durationMicros": Int64(CMTimeGetSeconds(duration) * 1_000_000.0),
            "width": width,
            "height": height,
            "frameRate": frameRate,
            "rotation": rotation,
            "hasVideo": videoTrack != nil,
            "hasAudio": audioTrack != nil,
            "videoTrackCount": tracks.filter { $0.mediaType == .video }.count,
            "audioTrackCount": tracks.filter { $0.mediaType == .audio }.count,
            "platform": "ios"
        ]
    }

    private func rotationDegrees(from transform: CGAffineTransform) -> Int {
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            return 90
        }

        if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            return 270
        }

        if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            return 180
        }

        return 0
    }
}
