package com.nle.editor.preview

import com.nle.editor.rendergraph.NleRenderGraph
import kotlin.math.roundToInt

class NlePreviewSizeResolver {

    fun resolve(
        graph: NleRenderGraph,
        qualityMode: NlePreviewQualityMode,
        maxPreviewWidth: Int,
        maxPreviewHeight: Int,
    ): NlePreviewOutputSize {
        val projectWidth = graph.project.width.coerceAtLeast(1)
        val projectHeight = graph.project.height.coerceAtLeast(1)

        val scaleLimit = when (qualityMode) {
            NlePreviewQualityMode.PERFORMANCE -> 0.38
            NlePreviewQualityMode.BALANCED -> 0.55
            NlePreviewQualityMode.QUALITY -> 0.75
            NlePreviewQualityMode.AUTO -> 0.50
        }

        val widthLimit = maxPreviewWidth.coerceAtLeast(240)
        val heightLimit = maxPreviewHeight.coerceAtLeast(240)

        val ratio = minOf(
            widthLimit.toDouble() / projectWidth.toDouble(),
            heightLimit.toDouble() / projectHeight.toDouble(),
            scaleLimit,
            1.0,
        )

        val width = (projectWidth * ratio).roundToInt().coerceAtLeast(240)
        val height = (projectHeight * ratio).roundToInt().coerceAtLeast(240)

        return NlePreviewOutputSize(
            width = width,
            height = height,
        )
    }
}
