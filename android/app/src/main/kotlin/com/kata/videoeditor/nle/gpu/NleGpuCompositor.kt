package com.kata.videoeditor.nle.gpu

import android.os.Handler
import android.os.HandlerThread
import android.view.Surface
import com.nle.editor.compositor.NleDefaultLayerTextureProvider
import com.nle.editor.compositor.NleMultilayerCompositor
import com.nle.editor.rendergraph.NleRenderGraph
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class NleGpuCompositor {
    private val eglCore = NleEglCore()
    private val videoSource = NlePreviewVideoTextureSource()
    private var textureProvider: NleDefaultLayerTextureProvider? = null
    private var compositor: NleMultilayerCompositor? = null

    private val renderThread = HandlerThread("NleGpuCompositorThread")
    private lateinit var handler: Handler

    private var initialized = false

    fun initialize() {
        if (initialized) return

        renderThread.start()
        handler = Handler(renderThread.looper)

        runBlockingOnRenderThread {
            eglCore.initialize()
        }

        initialized = true
    }

    fun renderToSurface(
        surface: Surface,
        width: Int,
        height: Int,
        graph: NleRenderGraph,
        timelineTimeUs: Long,
        presentationTimeNanos: Long = timelineTimeUs * 1000L,
    ) {
        initialize()

        runBlockingOnRenderThread {
            val eglSurface = NleEglWindowSurface(
                eglCore = eglCore,
                surface = surface
            )

            try {
                eglSurface.create()
                eglSurface.makeCurrent()

                var provider = textureProvider
                var comp = compositor
                if (comp == null || provider == null) {
                    provider = NleDefaultLayerTextureProvider(videoSource, width, height)
                    comp = NleMultilayerCompositor(provider)
                    textureProvider = provider
                    compositor = comp
                }

                videoSource.updateGraph(graph)

                comp.renderFrame(
                    graph = graph,
                    timelineTimeUs = timelineTimeUs,
                    outputWidth = width,
                    outputHeight = height
                )

                eglSurface.setPresentationTime(presentationTimeNanos)
                eglSurface.swapBuffers()
            } finally {
                eglSurface.release()
            }
        }
    }

    fun release() {
        if (!initialized) return

        runBlockingOnRenderThread {
            compositor?.release()
            compositor = null
            textureProvider?.release()
            textureProvider = null
            eglCore.release()
        }

        try {
            renderThread.quitSafely()
        } catch (_: Throwable) {
        }

        initialized = false
    }

    private fun runBlockingOnRenderThread(block: () -> Unit) {
        val latch = CountDownLatch(1)
        var throwable: Throwable? = null

        handler.post {
            try {
                block()
            } catch (e: Throwable) {
                throwable = e
            } finally {
                latch.countDown()
            }
        }

        latch.await(10, TimeUnit.SECONDS)

        throwable?.let { throw it }
    }
}
