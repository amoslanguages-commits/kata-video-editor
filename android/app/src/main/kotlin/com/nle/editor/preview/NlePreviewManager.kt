package com.nle.editor.preview

import io.flutter.view.TextureRegistry
import com.nle.editor.scopes.NleScopeManager
import com.nle.editor.audio.NlePreviewAudioMixer

class NlePreviewManager(
    textureRegistry: TextureRegistry,
    private val events: NlePreviewEventSink,
    val scopeManager: NleScopeManager? = null,
    val monitorId: String
) {
    var projectId: String? = null

    private val audioMixer = NlePreviewAudioMixer()
    private val audioPlayer = NlePreviewAudioPlayer(audioMixer)

    private val renderer = NleTrueDecoderPreviewRenderer(textureRegistry, monitorId)
    private val scheduler = NlePreviewFrameScheduler(
        renderer = renderer,
        events = events,
        audioPlayer = audioPlayer,
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
                val graph = renderer.currentGraph()
                if (graph != null) {
                    audioMixer.updateGraph(graph, config.preferProxy)
                    audioPlayer.prepare(graph)
                }
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
        try {
            scheduler.runOnRenderThread {
                renderer.updateRenderGraph(
                    renderGraphJson = renderGraphJson,
                    preferProxy = preferProxy,
                )
                val graph = renderer.currentGraph()
                if (graph != null) {
                    audioMixer.updateGraph(graph, preferProxy)
                    audioPlayer.prepare(graph)
                }
            }
        } catch (error: Throwable) {
            events.onPreviewError(error.message ?: error.toString())
            throw error
        }
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
                audioPlayer.release()
                audioMixer.release()
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
