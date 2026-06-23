import Foundation
import Flutter

final class IosNleEventEmitter: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var pendingEvents: [[String: Any?]] = []

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events

        pendingEvents.forEach { event in
            events(event)
        }

        pendingEvents.removeAll()

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func emit(_ event: IosNleEvent) {
        let map = event.toMap()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if let sink = self.eventSink {
                sink(map)
            } else {
                self.pendingEvents.append(map)
            }
        }
    }

    func emitError(
        projectId: String?,
        sessionId: String?,
        code: String,
        message: String,
        technicalMessage: String?,
        payload: [String: Any?] = [:]
    ) {
        emit(
            IosNleEvent(
                type: IosNleEventType.engineError,
                projectId: projectId,
                sessionId: sessionId,
                payload: [
                    "code": code,
                    "message": message,
                    "technicalMessage": technicalMessage,
                    "platform": "ios"
                ].merging(payload) { current, _ in current }
            )
        )
    }
}
