import Foundation
import Flutter

final class IosNleCommandRouter {
    private let manager: IosNleEngineManager

    init(manager: IosNleEngineManager) {
        self.manager = manager
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        let args = call.arguments as? [String: Any?] ?? [:]

        do {
            switch method {
            case IosNleCommandType.initialize:
                result(manager.initialize())

            case IosNleCommandType.dispose:
                result(manager.dispose())

            case IosNleCommandType.loadRenderGraph:
                let projectId = try args.stringRequired("projectId")
                let renderGraphJson = try args.stringRequired("renderGraphJson")
                result(try manager.loadRenderGraph(projectId: projectId, renderGraphJson: renderGraphJson))

            case IosNleCommandType.updateRenderGraph:
                let projectId = try args.stringRequired("projectId")
                let renderGraphJson = try args.stringRequired("renderGraphJson")
                let reason = args["reason"] as? String
                result(try manager.updateRenderGraph(projectId: projectId, renderGraphJson: renderGraphJson, reason: reason))

            case IosNleCommandType.validateRenderGraph:
                let renderGraphJson = try args.stringRequired("renderGraphJson")
                result(try manager.validateRenderGraph(renderGraphJson: renderGraphJson))

            case IosNleCommandType.play:
                let projectId = try args.stringRequired("projectId")
                result(try manager.play(projectId: projectId))

            case IosNleCommandType.pause:
                let projectId = try args.stringRequired("projectId")
                result(try manager.pause(projectId: projectId))

            case IosNleCommandType.seek:
                let projectId = try args.stringRequired("projectId")
                let positionMicros = try args.int64Required("timelineMicros")
                result(try manager.seek(projectId: projectId, positionMicros: positionMicros))

            case IosNleCommandType.setPlaybackRate:
                let projectId = try args.stringRequired("projectId")
                let rate = try args.doubleRequired("rate")
                result(try manager.setPlaybackRate(projectId: projectId, rate: rate))

            case IosNleCommandType.getSessionState:
                let projectId = try args.stringRequired("projectId")
                result(try manager.getSessionState(projectId: projectId))

            case IosNleCommandType.probeDeviceCapabilities:
                result(try manager.probeDeviceCapabilities())

            case IosNleCommandType.createPreviewTexture:
                let projectId = args["projectId"] as? String
                let width = try args.intRequired("width")
                let height = try args.intRequired("height")
                result(try manager.createPreviewTexture(projectId: projectId, width: width, height: height))

            case IosNleCommandType.attachPreviewTexture:
                let projectId = try args.stringRequired("projectId")
                let textureId = try args.int64Required("textureId")
                result(try manager.attachPreviewTexture(projectId: projectId, textureId: textureId))

            case IosNleCommandType.disposePreviewTexture:
                let textureId = try args.int64Required("textureId")
                result(try manager.disposePreviewTexture(textureId: textureId))

            case IosNleCommandType.renderPreviewPlaceholder:
                let textureId = try args.int64Required("textureId")
                let label = try args.stringRequired("label")
                let playheadMicros = try args.int64Required("playheadMicros")
                result(try manager.renderPreviewPlaceholder(textureId: textureId, label: label, playheadMicros: playheadMicros))

            case IosNleCommandType.renderGpuPreviewFrame:
                let projectId = try args.stringRequired("projectId")
                let timelineTimeMicros = try args.int64Required("timelineTimeMicros")
                result(try manager.renderGpuPreviewFrame(projectId: projectId, timelineTimeMicros: timelineTimeMicros))

            case IosNleCommandType.startProxyJob:
                result(try manager.startProxyJob(args: args))

            case IosNleCommandType.cancelProxyJob:
                let jobId = try args.stringRequired("jobId")
                result(try manager.cancelProxyJob(jobId: jobId))

            case IosNleCommandType.startExportJob:
                result(try manager.startExportJob(args: args))

            case IosNleCommandType.cancelExportJob:
                let jobId = try args.stringRequired("jobId")
                result(try manager.cancelExportJob(jobId: jobId))

            case "pause_export_job":
                result(["success": true, "result": ["accepted": true, "jobId": args["jobId"] as? String]])

            case "resume_export_job":
                result(["success": true, "result": ["accepted": true, "jobId": args["jobId"] as? String]])

            case "open_export_file":
                result(["success": true, "result": ["accepted": true, "outputPath": args["outputPath"] as? String]])

            case "open_export_folder":
                result(["success": true, "result": ["accepted": true, "outputPath": args["outputPath"] as? String]])

            case "check_export_permissions":
                result(["success": true, "result": ["accepted": true, "granted": true]])

            case "schedule_export_notification":
                result(["success": true, "result": ["accepted": true, "jobId": args["jobId"] as? String]])

            case "recover_export_jobs":
                result(["success": true, "result": ["accepted": true, "recoveredJobs": []]])

            case "validate_export_graph":
                result(["success": true, "result": ["passed": true, "issues": []]])

            default:
                result(FlutterMethodNotImplemented)
            }
        } catch {
            let nsError = error as NSError
            result([
                "success": false,
                "error": [
                    "code": nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? IosNleErrorCode.commandFailed,
                    "message": nsError.localizedDescription,
                    "technicalMessage": nsError.description
                ]
            ])
        }
    }
}

private extension Dictionary where Key == String, Value == Any? {
    func stringRequired(_ key: String) throws -> String {
        if let value = self[key] as? String, !value.isEmpty {
            return value
        }
        throw makeError(key: key)
    }

    func intRequired(_ key: String) throws -> Int {
        if let value = self[key] as? Int {
            return value
        }
        if let value = self[key] as? NSNumber {
            return value.intValue
        }
        throw makeError(key: key)
    }

    func int64Required(_ key: String) throws -> Int64 {
        if let value = self[key] as? Int64 {
            return value
        }
        if let value = self[key] as? NSNumber {
            return value.int64Value
        }
        throw makeError(key: key)
    }

    func doubleRequired(_ key: String) throws -> Double {
        if let value = self[key] as? Double {
            return value
        }
        if let value = self[key] as? NSNumber {
            return value.doubleValue
        }
        throw makeError(key: key)
    }

    private func makeError(key: String) -> NSError {
        return NSError(
            domain: "IosNleArguments",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "\(IosNleErrorCode.invalidArguments): missing or invalid \(key)"]
        )
    }
}
