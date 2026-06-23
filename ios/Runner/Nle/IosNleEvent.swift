import Foundation

struct IosNleEvent {
    let type: String
    let projectId: String?
    let sessionId: String?
    let commandId: String? = nil
    let jobId: String? = nil
    let payload: [String: Any?]

    func toMap() -> [String: Any?] {
        return [
            "type": type,
            "projectId": projectId,
            "sessionId": sessionId,
            "commandId": commandId,
            "jobId": jobId,
            "payload": payload,
            "timestampMicros": Int64(Date().timeIntervalSince1970 * 1_000_000.0)
        ]
    }
}
