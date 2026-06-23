import Foundation

final class IosNleEngineSession {
    let projectId: String
    let sessionId: String = UUID().uuidString

    private(set) var renderGraphJson: String
    private(set) var renderGraph: [String: Any]
    private(set) var isPlaying: Bool = false
    private(set) var playheadMicros: Int64 = 0
    private(set) var durationMicros: Int64 = 0
    private(set) var playbackRate: Double = 1.0

    let createdAtMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000.0)
    private(set) var updatedAtMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000.0)

    init(
        projectId: String,
        renderGraphJson: String
    ) throws {
        self.projectId = projectId
        self.renderGraphJson = renderGraphJson
        self.renderGraph = try IosNleEngineSession.parseJson(renderGraphJson)
        self.durationMicros = IosNleEngineSession.resolveDurationMicros(renderGraph)
    }

    func updateGraph(_ json: String) throws {
        renderGraphJson = json
        renderGraph = try Self.parseJson(json)
        durationMicros = Self.resolveDurationMicros(renderGraph)

        if durationMicros > 0 && playheadMicros > durationMicros {
            playheadMicros = durationMicros
        }

        touch()
    }

    func play() {
        isPlaying = true
        touch()
    }

    func pause() {
        isPlaying = false
        touch()
    }

    func seek(_ positionMicros: Int64) {
        if durationMicros > 0 {
            playheadMicros = min(max(positionMicros, 0), durationMicros)
        } else {
            playheadMicros = max(positionMicros, 0)
        }

        touch()
    }

    func setPlaybackRate(_ rate: Double) {
        playbackRate = min(max(rate, 0.25), 4.0)
        touch()
    }

    func toMap() -> [String: Any?] {
        return [
            "sessionId": sessionId,
            "projectId": projectId,
            "isPlaying": isPlaying,
            "playheadMicros": playheadMicros,
            "durationMicros": durationMicros,
            "playbackRate": playbackRate,
            "createdAtMillis": createdAtMillis,
            "updatedAtMillis": updatedAtMillis
        ]
    }

    private func touch() {
        updatedAtMillis = Int64(Date().timeIntervalSince1970 * 1000.0)
    }

    private static func parseJson(_ json: String) throws -> [String: Any] {
        let data = Data(json.utf8)
        let object = try JSONSerialization.jsonObject(with: data)

        guard let map = object as? [String: Any] else {
            throw NSError(
                domain: "IosNleEngineSession",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Render graph must be a JSON object."]
            )
        }

        return map
    }

    private static func resolveDurationMicros(_ graph: [String: Any]) -> Int64 {
        if let project = graph["project"] as? [String: Any],
           let duration = project["durationMicros"] as? NSNumber,
           duration.int64Value > 0 {
            return duration.int64Value
        }

        guard let clips = graph["clips"] as? [[String: Any]] else {
            return 0
        }

        var maxEnd: Int64 = 0

        for clip in clips {
            if let end = clip["timelineEndMicros"] as? NSNumber {
                maxEnd = max(maxEnd, end.int64Value)
            }
        }

        return maxEnd
    }
}
