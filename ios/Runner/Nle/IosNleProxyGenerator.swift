import AVFoundation
import Flutter
import UIKit

/// iOS counterpart of the Android `NleProxyGenerator`.
/// Handles the "nle/proxy_generator" method channel with the same methods
/// and result shapes as Android. Uses AVAssetExportSession transcodes.
class IosNleProxyGenerator {
    private var activeJobs: [String: AVAssetExportSession] = [:]
    private let lock = NSLock()

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "proxy_generate":
            guard let args = call.arguments as? [String: Any],
                  let jobId = args["jobId"] as? String,
                  let sourcePath = args["sourcePath"] as? String,
                  let outputPath = args["outputPath"] as? String else {
                result(FlutterError(code: "BAD_ARGS", message: "Missing required arguments for proxy generation", details: nil))
                return
            }
            let maxHeight = (args["maxHeight"] as? Int) ?? 720
            let bitrate = (args["bitrate"] as? Int) ?? 2500000
            let codec = (args["codec"] as? String) ?? "video/avc"
            generate(
                jobId: jobId,
                sourcePath: sourcePath,
                outputPath: outputPath,
                maxHeight: maxHeight,
                bitrate: bitrate,
                codec: codec,
                result: result
            )
        case "proxy_cancel":
            if let args = call.arguments as? [String: Any],
               let jobId = args["jobId"] as? String {
                lock.lock()
                let session = activeJobs.removeValue(forKey: jobId)
                lock.unlock()
                session?.cancelExport()
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func generate(
        jobId: String,
        sourcePath: String,
        outputPath: String,
        maxHeight: Int,
        bitrate: Int,
        codec: String,
        result: @escaping FlutterResult
    ) {
        guard FileManager.default.fileExists(atPath: sourcePath) else {
            result(FlutterError(code: "TRANSCODE_FAILED", message: "Source file does not exist: \(sourcePath)", details: nil))
            return
        }

        let asset = AVAsset(url: URL(fileURLWithPath: sourcePath))
        let wantsHevc = codec.lowercased().contains("hevc") || codec.lowercased().contains("h265")
        let preset: String
        if wantsHevc {
            preset = maxHeight >= 2160 ? AVAssetExportPresetHEVC3840x2160 : AVAssetExportPresetHEVC1920x1080
        } else if maxHeight <= 480 {
            preset = AVAssetExportPreset640x480
        } else if maxHeight <= 540 {
            preset = AVAssetExportPreset960x540
        } else if maxHeight <= 720 {
            preset = AVAssetExportPreset1280x720
        } else if maxHeight <= 1080 {
            preset = AVAssetExportPreset1920x1080
        } else {
            preset = AVAssetExportPreset3840x2160
        }

        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            result(FlutterError(code: "TRANSCODE_FAILED", message: "Could not create an export session for preset \(preset).", details: nil))
            return
        }

        let dir = (outputPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(atPath: outputPath)

        session.outputURL = URL(fileURLWithPath: outputPath)
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = false

        lock.lock()
        activeJobs[jobId] = session
        lock.unlock()

        session.exportAsynchronously {
            DispatchQueue.main.async { [weak self] in
                self?.lock.lock()
                self?.activeJobs.removeValue(forKey: jobId)
                self?.lock.unlock()

                switch session.status {
                case .completed:
                    let outAsset = AVAsset(url: URL(fileURLWithPath: outputPath))
                    var width = 0
                    var height = 0
                    var fps = 30.0
                    if let track = outAsset.tracks(withMediaType: .video).first {
                        let size = track.naturalSize.applying(track.preferredTransform)
                        width = Int(abs(size.width))
                        height = Int(abs(size.height))
                        fps = track.nominalFrameRate > 0 ? Double(track.nominalFrameRate) : 30.0
                    }
                    let fileSize = ((try? FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? NSNumber) ?? 0).int64Value
                    let durationSeconds = CMTimeGetSeconds(outAsset.duration)
                    let durationMicros = durationSeconds.isFinite ? Int64(durationSeconds * 1_000_000) : 0
                    result([
                        "proxyPath": outputPath,
                        "width": width,
                        "height": height,
                        "fps": fps,
                        "bitrate": bitrate,
                        "fileSizeBytes": fileSize,
                        "durationMicros": durationMicros,
                        "codec": codec,
                    ])
                case .cancelled:
                    try? FileManager.default.removeItem(atPath: outputPath)
                    result(FlutterError(code: "CANCELLED", message: "Proxy generation was cancelled", details: nil))
                default:
                    try? FileManager.default.removeItem(atPath: outputPath)
                    result(FlutterError(
                        code: "TRANSCODE_FAILED",
                        message: session.error?.localizedDescription ?? "Proxy generation failed.",
                        details: nil
                    ))
                }
            }
        }
    }
}
