package com.nle.editor.qa

import com.nle.editor.rendergraph.NleRenderGraph

data class NleQaIssue(
    val id: String,
    val severity: String,
    val message: String,
)

data class NleQaReport(
    val passed: Boolean,
    val issues: List<NleQaIssue>,
)

class NleRenderGraphQaValidator {

    fun validate(graph: NleRenderGraph): NleQaReport {
        val issues = mutableListOf<NleQaIssue>()

        if (graph.schema != "nle.render_graph") {
            issues.add(
                fail(
                    id = "schema.invalid",
                    message = "Invalid schema: ${graph.schema}",
                )
            )
        }

        if (graph.version < 2) {
            issues.add(
                fail(
                    id = "schema.version",
                    message = "RenderGraph version must be 2+.",
                )
            )
        }

        if (graph.project.durationUs <= 0L) {
            issues.add(
                fail(
                    id = "project.duration",
                    message = "Project duration must be greater than zero.",
                )
            )
        }

        if (graph.project.width <= 0 || graph.project.height <= 0) {
            issues.add(
                fail(
                    id = "project.size",
                    message = "Project width/height must be greater than zero.",
                )
            )
        }

        val assetIds = graph.assets.map { it.id }.toSet()

        for (track in graph.tracks) {
            if (track.id.isBlank()) {
                issues.add(
                    fail(
                        id = "track.id",
                        message = "Track id cannot be blank.",
                    )
                )
            }

            for (clip in track.clips) {
                if (clip.timelineEndUs <= clip.timelineStartUs) {
                    issues.add(
                        fail(
                            id = "clip.${clip.id}.timing",
                            message = "Clip ${clip.id} has invalid timeline timing.",
                        )
                    )
                }

                if (clip.speed <= 0.0) {
                    issues.add(
                        fail(
                            id = "clip.${clip.id}.speed",
                            message = "Clip ${clip.id} speed must be greater than zero.",
                        )
                    )
                }

                if (clip.transform.opacity < 0.0 || clip.transform.opacity > 1.0) {
                    issues.add(
                        fail(
                            id = "clip.${clip.id}.opacity",
                            message = "Clip ${clip.id} opacity must be between 0 and 1.",
                        )
                    )
                }

                if (!clip.assetId.isNullOrBlank() && !assetIds.contains(clip.assetId)) {
                    issues.add(
                        warning(
                            id = "clip.${clip.id}.asset",
                            message = "Clip ${clip.id} references missing asset ${clip.assetId}.",
                        )
                    )
                }
            }
        }

        val failed = issues.any { it.severity == "fail" }

        return NleQaReport(
            passed = !failed,
            issues = issues,
        )
    }

    private fun fail(
        id: String,
        message: String,
    ): NleQaIssue {
        return NleQaIssue(
            id = id,
            severity = "fail",
            message = message,
        )
    }

    private fun warning(
        id: String,
        message: String,
    ): NleQaIssue {
        return NleQaIssue(
            id = id,
            severity = "warning",
            message = message,
        )
    }
}
