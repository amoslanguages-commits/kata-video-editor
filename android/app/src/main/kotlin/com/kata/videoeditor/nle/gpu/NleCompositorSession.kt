package com.kata.videoeditor.nle.gpu

import android.view.Surface
import com.nle.editor.rendergraph.NleRenderGraphParser

class NleCompositorSession {
    private val parser = NleRenderGraphParser()
    private val compositor = NleGpuCompositor()

    fun renderPreviewFrame(
        projectId: String,
        renderGraphJson: String,
        timelineTimeMicros: Long,
        surface: Surface,
        width: Int,
        height: Int,
    ) {
        val graph = parser.parse(renderGraphJson)

        compositor.renderToSurface(
            surface = surface,
            width = width,
            height = height,
            graph = graph,
            timelineTimeUs = timelineTimeMicros
        )
    }

    fun renderExportFrame(
        projectId: String,
        renderGraphJson: String,
        timelineTimeMicros: Long,
        encoderSurface: Surface,
        width: Int,
        height: Int,
        presentationTimeNanos: Long,
    ) {
        val graph = parser.parse(renderGraphJson)

        compositor.renderToSurface(
            surface = encoderSurface,
            width = width,
            height = height,
            graph = graph,
            timelineTimeUs = timelineTimeMicros,
            presentationTimeNanos = presentationTimeNanos
        )
    }

    fun release() {
        compositor.release()
    }
}
