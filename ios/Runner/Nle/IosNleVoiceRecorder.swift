import AVFoundation
import Flutter
import UIKit

/// iOS counterpart of the Android `NleVoiceRecorder`.
/// Handles the "nle/voice_recorder" method channel with the same method
/// names and result shapes as Android.
class IosNleVoiceRecorder {
    private var recorder: AVAudioRecorder?
    private var isRecording = false
    private var isPaused = false
    private var outputPath: String?
    private var sampleRate = 48000
    private var channels = 1
    private var bitrate = 128000
    private var startTime: Date?
    private var pauseTime: Date?
    private var totalPaused: TimeInterval = 0

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "voice_prepare":
            guard let args = call.arguments as? [String: Any],
                  let path = args["outputPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "outputPath is required", details: nil))
                return
            }
            let sRate = (args["sampleRate"] as? Int) ?? 48000
            let chCount = (args["channelCount"] as? Int) ?? 1
            let bRate = (args["bitrate"] as? Int) ?? 128000
            do {
                try prepare(path: path, sampleRate: sRate, channels: chCount, bitrate: bRate)
                result(nil)
            } catch {
                result(FlutterError(code: "PREPARE_FAILED", message: error.localizedDescription, details: nil))
            }
        case "voice_start":
            do {
                try start()
                result(nil)
            } catch {
                result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
            }
        case "voice_pause":
            pauseRecording()
            result(nil)
        case "voice_resume":
            resumeRecording()
            result(nil)
        case "voice_stop":
            result(stop())
        case "voice_cancel":
            cancel()
            result(nil)
        case "voice_meter":
            result(meter())
        case "voice_is_recording":
            result(isRecording)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func prepare(path: String, sampleRate: Int, channels: Int, bitrate: Int) throws {
        releaseRecorder()
        outputPath = path
        self.sampleRate = sampleRate
        self.channels = channels
        self.bitrate = bitrate

        let dir = (path as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderBitRateKey: bitrate,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let recorder = try AVAudioRecorder(url: URL(fileURLWithPath: path), settings: settings)
        recorder.isMeteringEnabled = true
        guard recorder.prepareToRecord() else {
            throw NSError(domain: "IosNleVoiceRecorder", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "AVAudioRecorder failed to prepare"])
        }
        self.recorder = recorder
        isRecording = false
        isPaused = false
        totalPaused = 0
    }

    private func start() throws {
        guard let recorder = recorder else {
            throw NSError(domain: "IosNleVoiceRecorder", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Recorder not prepared"])
        }
        guard recorder.record() else {
            throw NSError(domain: "IosNleVoiceRecorder", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "AVAudioRecorder failed to start"])
        }
        isRecording = true
        isPaused = false
        startTime = Date()
        totalPaused = 0
    }

    private func pauseRecording() {
        guard isRecording, !isPaused, let recorder = recorder else { return }
        recorder.pause()
        isPaused = true
        pauseTime = Date()
    }

    private func resumeRecording() {
        guard isRecording, isPaused, let recorder = recorder else { return }
        recorder.record()
        isPaused = false
        if let pauseTime = pauseTime {
            totalPaused += Date().timeIntervalSince(pauseTime)
        }
    }

    private func stop() -> [String: Any] {
        var durationMicros: Int64 = 0
        if let startTime = startTime {
            var paused = totalPaused
            if isPaused, let pauseTime = pauseTime {
                paused += Date().timeIntervalSince(pauseTime)
            }
            let duration = max(0, Date().timeIntervalSince(startTime) - paused)
            durationMicros = Int64(duration * 1_000_000)
        }
        let path = outputPath ?? ""
        let formatInfo: [String: Any] = [
            "sampleRate": sampleRate,
            "channels": channels,
            "bitDepth": 16,
            "codec": "aac",
            "bitrate": bitrate,
        ]
        recorder?.stop()
        releaseRecorder()
        return [
            "outputPath": path,
            "durationMicros": durationMicros,
            "formatInfo": formatInfo,
        ]
    }

    private func cancel() {
        let path = outputPath
        releaseRecorder()
        if let path = path {
            try? FileManager.default.removeItem(atPath: path)
        }
    }

    private func meter() -> [String: Any] {
        var peak = 0.0
        var rms = 0.0
        var clipping = false
        if let recorder = recorder, isRecording, !isPaused {
            recorder.updateMeters()
            peak = min(1.0, pow(10.0, Double(recorder.peakPower(forChannel: 0)) / 20.0))
            rms = min(1.0, pow(10.0, Double(recorder.averagePower(forChannel: 0)) / 20.0))
            clipping = peak >= 0.99
        }
        return ["peak": peak, "rms": rms, "clipping": clipping]
    }

    private func releaseRecorder() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        isPaused = false
        outputPath = nil
    }
}
