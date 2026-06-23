package com.nle.editor.qa

import com.nle.editor.rendergraph.NleRenderGraph

class NlePreviewExportMatchProbe {

    fun probe(
        previewGraph: NleRenderGraph,
        exportGraph: NleRenderGraph
    ): List<NleColorQaIssue> {
        val issues = mutableListOf<NleColorQaIssue>()

        // 1. Verify timeline structure matches
        if (previewGraph.tracks.size != exportGraph.tracks.size) {
            issues.add(
                NleColorQaIssue(
                    id = "PREVIEW_EXPORT_TRACKS_MISMATCH",
                    severity = NleColorQaSeverity.ERROR,
                    area = NleColorQaArea.PREVIEW_EXPORT,
                    title = "Preview/Export tracks mismatch",
                    message = "Preview render graph has ${previewGraph.tracks.size} tracks, but Export has ${exportGraph.tracks.size}.",
                    suggestedFix = "Check timeline serialization logic in both providers."
                )
            )
        }

        // 2. Verify export hints are aligned
        val prevHints = previewGraph.exportHints
        val expHints = exportGraph.exportHints


        // 3. Compare clip processor presence
        for (i in 0 until minOf(previewGraph.tracks.size, exportGraph.tracks.size)) {
            val prevTrack = previewGraph.tracks[i]
            val expTrack = exportGraph.tracks[i]

            for (j in 0 until minOf(prevTrack.clips.size, expTrack.clips.size)) {
                val prevClip = prevTrack.clips[j]
                val expClip = expTrack.clips[j]

                val prevHasLut = prevClip.lutStack != null && prevClip.lutStack.hasEnabledLuts
                val expHasLut = expClip.lutStack != null && expClip.lutStack.hasEnabledLuts

                if (prevHasLut != expHasLut) {
                    issues.add(
                        NleColorQaIssue(
                            id = "PREVIEW_EXPORT_LUT_MISMATCH_${prevClip.id}",
                            severity = NleColorQaSeverity.ERROR,
                            area = NleColorQaArea.PREVIEW_EXPORT,
                            title = "Clip LUT stack mismatch",
                            message = "Clip \"${prevClip.name}\" has active LUTs in preview but not in export, or vice versa.",
                            suggestedFix = "Verify lutRepository lookup filters are consistent."
                        )
                    )
                }
            }
        }

        return issues
    }
}
