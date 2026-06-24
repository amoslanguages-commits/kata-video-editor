package com.nle.editor.rendergraph

data class NleResolvedVisualLayer(
    val track: NleRenderTrack,
    val clip: NleRenderClip,
    val asset: NleRenderAsset?,
    val timelineTimeUs: Long,
    val localTimeUs: Long,
    val sourceTimeUs: Long,
    val layerIndex: Int,
) {
    val colorCurveStack: com.nle.editor.curves.NleColorCurveStack?
        get() = clip.colorCurveStack
    val secondaryGrades: com.nle.editor.grade.NleSecondaryGradeStack?
        get() = clip.secondaryGrades
}

class NleVisualLayerResolver {

    fun resolve(
        graph: NleRenderGraph,
        timelineTimeUs: Long,
    ): List<NleResolvedVisualLayer> {
        val assetMap = graph.assets.associateBy { it.id }

        val enabledTrackIds = emptySet<String>()

        val visualTracks = graph.tracks
            .filter { it.isVisual }
            .filter { !it.isHidden }
            .filter { !it.isMuted }
            .filter {
                enabledTrackIds.isEmpty() || enabledTrackIds.contains(it.id)
            }
            .sortedWith(
                compareBy<NleRenderTrack> { it.layerOrder }
                    .thenBy { it.sortOrder }
            )

        val resolved = mutableListOf<NleResolvedVisualLayer>()

        for (track in visualTracks) {
            val activeClips = track.clips
                .asSequence()
                .filter { !it.isDisabled }
                .filter { clip ->
                    timelineTimeUs >= clip.timelineStartUs &&
                        timelineTimeUs < clip.timelineEndUs
                }
                .sortedWith(
                    compareBy<NleRenderClip> { it.zIndex }
                        .thenBy { it.timelineStartUs }
                )
                .toList()

            for (clip in activeClips) {
                if (clip.type == "adjustment") {
                    // 29B-8 only prepares the adjustment hook.
                    // Actual adjustment stack can be expanded later.
                    continue
                }

                val localTimeUs = timelineTimeUs - clip.timelineStartUs
                val sourceTimeUs = clip.sourceStartUs +
                    (localTimeUs * safeSpeed(clip.speed)).toLong()

                resolved.add(
                    NleResolvedVisualLayer(
                        track = track,
                        clip = clip,
                        asset = clip.assetId?.let(assetMap::get),
                        timelineTimeUs = timelineTimeUs,
                        localTimeUs = localTimeUs,
                        sourceTimeUs = sourceTimeUs.coerceAtLeast(0L),
                        layerIndex = resolved.size,
                    )
                )
            }
        }

        return resolved
    }

    private fun safeSpeed(speed: Double): Double {
        if (speed <= 0.0) return 1.0
        return speed
    }
}
