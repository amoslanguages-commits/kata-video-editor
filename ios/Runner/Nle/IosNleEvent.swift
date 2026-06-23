import Foundation

struct IosNleEvent {
    let type: String
    let projectId: String?
    let sessionId: String?
    let commandId: String?
    let jobId: String?
    let payload: [String: Any?]

    init(
        type: String,
        projectId: String?,
        sessionId: String?,
        commandId: String? = nil,
        jobId: String? = nil,
        payload: [String: Any?]
    ) {
        self.type = type
        self.projectId = projectId
        self.sessionId = sessionId
        self.commandId = commandId
        self.jobId = jobId
        self.payload = payload
    }

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
