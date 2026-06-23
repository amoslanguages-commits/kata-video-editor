import Foundation

final class IosNleProxyJobFoundation {
    private static let shared = IosNleProxyJobStore()

    func start(
        projectId: String?,
        jobId: String,
        assetId: String,
        inputPath: String,
        outputPath: String,
        eventEmitter: IosNleEventEmitter
    ) {
        let renderer = IosNleNativeProxyRenderer(eventEmitter: eventEmitter) { finishedJobId in
            IosNleProxyJobFoundation.shared.release(jobId: finishedJobId)
        }
        IosNleProxyJobFoundation.shared.retain(renderer: renderer, jobId: jobId)
        do {
            _ = try renderer.start(
                projectId: projectId,
                jobId: jobId,
                assetId: assetId,
                inputPath: inputPath,
                outputPath: outputPath,
                profile: [:]
            )
        } catch {
            IosNleProxyJobFoundation.shared.release(jobId: jobId)
            eventEmitter.emit(
                IosNleEvent(
                    type: IosNleEventType.proxyFailed,
                    projectId: projectId,
                    sessionId: nil,
                    jobId: jobId,
                    payload: [
                        "assetId": assetId,
                        "stage": "Failed",
                        "errorMessage": error.localizedDescription
                    ]
                )
            )
        }
    }

    func cancel(jobId: String) -> [String: Any?] {
        return IosNleProxyJobFoundation.shared.cancel(jobId: jobId)
    }
}

private final class IosNleProxyJobStore {
    private var renderers: [String: IosNleNativeProxyRenderer] = [:]
    private let lock = NSLock()

    func retain(renderer: IosNleNativeProxyRenderer, jobId: String) {
        lock.lock()
        renderers[jobId] = renderer
        lock.unlock()
    }

    func release(jobId: String) {
        lock.lock()
        renderers.removeValue(forKey: jobId)
        lock.unlock()
    }

    func cancel(jobId: String) -> [String: Any?] {
        lock.lock()
        let renderer = renderers[jobId]
        lock.unlock()
        return renderer?.cancel(jobId: jobId) ?? ["success": true, "jobId": jobId, "cancelled": true]
    }
}
