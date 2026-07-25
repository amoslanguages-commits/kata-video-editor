import AVFoundation
import CoreMedia
import Flutter
import UIKit

/// iOS counterpart of the Android `NleMediaScanner`.
/// Handles the "nle/media_scanner" method channel with the same methods
/// and result shapes as Android.
class IosNleMediaScanner {

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "media_scan":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Path is required", details: nil))
                return
            }
            do {
                result(try scanFile(path))
            } catch {
                result(FlutterError(code: "SCAN_FAILED", message: error.localizedDescription, details: nil))
            }
        case "media_generate_thumbnail":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String,
                  let outputPath = args["outputPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Path and outputPath are required", details: nil))
                return
            }
            let width = (args["width"] as? Int) ?? 512
            let height = (args["height"] as? Int) ?? 512
            result(generateThumbnail(path: path, outputPath: outputPath, width: width, height: height))
        case "media_file_exists":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(false)
                return
            }
            result(FileManager.default.fileExists(atPath: path))
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func scanFile(_ path: String) throws -> [String: Any] {
        guard FileManager.default.fileExists(atPath: path) else {
            throw NSError(domain: "IosNleMediaScanner", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "File does not exist: \(path)"])
        }

        let asset = AVAsset(url: URL(fileURLWithPath: path))
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let durationMicros = durationSeconds.isFinite ? Int64(durationSeconds * 1_000_000) : 0

        var type = "unknown"
        var width = 0
        var height = 0
        var fps = 30.0
        var sampleRate = 0
        var channelCount = 0
        var bitrate = 0
        var videoCodec = ""
        var audioCodec = ""
        var colorSpace = "rec709"
        var hasHdr = false

        let videoTracks = asset.tracks(withMediaType: .video)
        let audioTracks = asset.tracks(withMediaType: .audio)

        if !videoTracks.isEmpty {
            type = "video"
            if let track = videoTracks.first {
                let size = track.naturalSize.applying(track.preferredTransform)
                width = Int(abs(size.width))
                height = Int(abs(size.height))
                fps = track.nominalFrameRate > 0 ? Double(track.nominalFrameRate) : 30.0
                bitrate = Int(track.estimatedDataRate)
                if let formatDesc = track.formatDescriptions.first {
                    let fd = formatDesc as! CMFormatDescription
                    videoCodec = codecMime(for: CMFormatDescriptionGetMediaSubType(fd), isVideo: true)
                    if let extensions = CMFormatDescriptionGetExtensions(fd) as? [String: Any],
                       let primaries = extensions[kCVImageBufferColorPrimariesKey as String] as? String,
                       primaries.contains("2020") {
                        colorSpace = "bt2020"
                        hasHdr = true
                    }
                }
            }
        } else if !audioTracks.isEmpty {
            type = "audio"
        } else if let image = UIImage(contentsOfFile: path) {
            type = "image"
            width = Int(image.size.width)
            height = Int(image.size.height)
        }

        if let audioTrack = audioTracks.first {
            if let formatDesc = audioTrack.formatDescriptions.first {
                let fd = formatDesc as! CMFormatDescription
                audioCodec = codecMime(for: CMFormatDescriptionGetMediaSubType(fd), isVideo: false)
                if let audioFd = fd as? CMAudioFormatDescription,
                   let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFd) {
                    sampleRate = Int(asbd.pointee.mSampleRate)
                    channelCount = Int(asbd.pointee.mChannelsPerFrame)
                }
            }
            if bitrate == 0 {
                bitrate = Int(audioTrack.estimatedDataRate)
            }
        }

        return [
            "path": path,
            "type": type,
            "durationMicros": durationMicros,
            "width": width,
            "height": height,
            "fps": fps,
            "sampleRate": sampleRate,
            "channelCount": channelCount,
            "bitrate": bitrate,
            "videoCodec": videoCodec,
            "audioCodec": audioCodec,
            "colorSpace": colorSpace,
            "hasHdr": hasHdr,
        ]
    }

    private func codecMime(for subType: FourCharCode, isVideo: Bool) -> String {
        switch subType {
        case kCMVideoCodecType_H264: return "video/avc"
        case kCMVideoCodecType_HEVC: return "video/hevc"
        case kCMVideoCodecType_MPEG4Video: return "video/mp4v"
        case kCMVideoCodecType_VP9: return "video/x-vnd.on2.vp9"
        case kAudioFormatMPEG4AAC: return "audio/mp4a-latm"
        case kAudioFormatMPEGLayer3: return "audio/mpeg"
        case kAudioFormatLinearPCM: return "audio/raw"
        case kAudioFormatAppleLossless: return "audio/alac"
        default:
            let chars: [UInt8] = [
                UInt8((subType >> 24) & 0xFF), UInt8((subType >> 16) & 0xFF),
                UInt8((subType >> 8) & 0xFF), UInt8(subType & 0xFF),
            ]
            let fourCC = String(bytes: chars, encoding: .ascii) ?? "unknown"
            return isVideo ? "video/\(fourCC)" : "audio/\(fourCC)"
        }
    }

    private func generateThumbnail(path: String, outputPath: String, width: Int, height: Int) -> String? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }

        var image: UIImage?
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        if !asset.tracks(withMediaType: .video).isEmpty {
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
                image = UIImage(cgImage: cgImage)
            }
        } else {
            image = UIImage(contentsOfFile: path)
        }

        guard let source = image, source.size.width > 0, source.size.height > 0 else { return nil }

        let ratio = source.size.width / source.size.height
        var targetW = CGFloat(width)
        var targetH = CGFloat(height)
        if source.size.width > source.size.height {
            targetH = targetW / ratio
        } else {
            targetW = targetH * ratio
        }
        let targetSize = CGSize(width: max(1, targetW), height: max(1, targetH))
        let scaled = UIGraphicsImageRenderer(size: targetSize).image { _ in
            source.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return nil }
        let dir = (outputPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        do {
            try data.write(to: URL(fileURLWithPath: outputPath))
            return outputPath
        } catch {
            return nil
        }
    }
}
