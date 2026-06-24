package com.nle.editor.preview

import io.flutter.view.TextureRegistry
import com.nle.editor.scopes.NleScopeManager

class NlePreviewManager(
    textureRegistry: TextureRegistry,
    private val events: NlePreviewEventSink,
    val scopeManager: NleScopeManager? = null,
    val monitorId: String
) {
    var projectId: String? = null

    private val renderer = NleTrueDecoderPreviewRenderer(textureRegistry, monitorId)
    private val scheduler = NlePreviewFrameScheduler(
        renderer = renderer,
        events = events,
        audioPlayer = null,
    )

    init {
        renderer.eventSink = events
        renderer.scopeManager = scopeManager
    }

    fun prepare(config: NlePreviewConfig) {
        this.projectId = config.projectId
        try {
            val textureId = renderer.prepareFlutterSurface(config)
            val size = renderer.outputSize()

            events.onPreviewTextureReady(
                textureId = textureId,
                width = size.width,
                height = size.height,
            )

            scheduler.runOnRenderThreadBlocking {
                renderer.prepareDecoderPipeline(config)
            }

            val initialFrame = scheduler.runOnRenderThreadBlocking {
                renderer.renderFrame(0L)
            }
            if (initialFrame.rendered) {
                events.onPreviewFrameRendered(initialFrame.timelineTimeUs)
            } else {
                val reason = initialFrame.reason ?: "Initial native preview frame did not render."
                events.onPreviewDroppedFrame(
                    timelineTimeUs = initialFrame.timelineTimeUs,
                    reason = reason,
                )
                throw IllegalStateException(reason)
            }
        } catch (error: Throwable) {
            events.onPreviewError(error.message ?: error.toString())
            throw error
        }
    }

    fun updateRenderGraph(
        renderGraphJson: String,
        preferProxy: Boolean = true,
    ) {
        // Stabilization mode: avoid rebuilding the native preview decoder graph on every
        // timeline edit. Rebuilding here caused frame-rate drops, buffering, and timeline
        // interaction lag on real devices. A later controlled preview pipeline should add
        // debounced graph updates with cancellation/backpressure instead of immediate rebuilds.
        return
    }

    fun renderFrame(timelineTimeUs: Long): NlePreviewFrameResult {
        return scheduler.seekAndRender(timelineTimeUs)
    }

    fun play(fromTimelineUs: Long) {
        scheduler.play(fromTimelineUs)
    }

    fun pause() {
        scheduler.pause()
    }

    fun stop() {
        scheduler.stop()
    }

    fun release() {
        try {
            scheduler.runOnRenderThreadBlocking {
                scheduler.pause()
                renderer.release()
            }
        } catch (_: Throwable) {
            try { renderer.release() } catch (_: Throwable) {}
        }
        scheduler.release()
    }

    fun currentGraph(): com.nle.editor.rendergraph.NleRenderGraph? {
        return renderer.currentGraph()
    }
}
