import Foundation

struct IosNleGraphValidationResult {
    let valid: Bool
    let warnings: [String]
    let errors: [String]
    let summary: [String: Any]

    func toMap() -> [String: Any] {
        return [
            "valid": valid,
            "warnings": warnings,
            "errors": errors,
            "summary": summary
        ]
    }
}

final class IosNleRenderGraphValidator {
    func validate(_ graph: [String: Any]) -> IosNleGraphValidationResult {
        var warnings: [String] = []
        var errors: [String] = []

        let assets = graph["assets"] as? [[String: Any]] ?? []
        let tracks = graph["tracks"] as? [[String: Any]] ?? []
        let clips = graph["clips"] as? [[String: Any]] ?? []
        let transitions = graph["transitions"] as? [[String: Any]] ?? []

        if tracks.isEmpty {
            warnings.append("Project has no tracks.")
        }

        if clips.isEmpty {
            warnings.append("Project has no clips.")
        }

        for clip in clips {
            let start = (clip["timelineStartMicros"] as? NSNumber)?.int64Value ?? 0
            let end = (clip["timelineEndMicros"] as? NSNumber)?.int64Value ?? 0

            if end < start {
                errors.append("Clip has invalid timing.")
            }
        }

        return IosNleGraphValidationResult(
            valid: errors.isEmpty,
            warnings: warnings,
            errors: errors,
            summary: [
                "assets": assets.count,
                "tracks": tracks.count,
                "clips": clips.count,
                "transitions": transitions.count
            ]
        )
    }
}
