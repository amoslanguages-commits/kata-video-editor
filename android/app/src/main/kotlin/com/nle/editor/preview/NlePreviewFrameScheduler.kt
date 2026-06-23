package com.nle.editor.preview

import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import com.nle.editor.sync.NlePreviewSyncTelemetry
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

class NlePreviewFrameScheduler(
    private val renderer: NleTrueDecoderPreviewRenderer,
    private val events: NlePreviewEventSink,
    val syncTelemetry: NlePreviewSyncTelemetry = NlePreviewSyncTelemetry(),
) {
    private val thread = HandlerThread("NlePreviewFrameScheduler")
    private lateinit var handler: Handler

    private val playing = AtomicBoolean(false)

    private var startTimelineUs: Long = 0L
    private var startClockMs: Long = 0L
    private var consecutiveDroppedFrames = 0

    private val renderThreadTimeoutMs = 2500L
    private val maxConsecutiveDroppedFrames = 5

    fun startThread() {
        if (!thread.isAlive) {
            thread.start()
            handler = Handler(thread.looper)
        }
    }

    fun runOnRenderThread(task: () -> Unit) {
        startThread()
        handler.post {
            try {
                task()
            } catch (t: Throwable) {
                playing.set(false)
                events.onPreviewError(t.message ?: t.toString())
            }
        }
    }

    fun <T> runOnRenderThreadBlocking(task: () -> T): T {
        startThread()

        if (Thread.currentThread() == thread) {
            return task()
        }

        val result = AtomicReference<T?>()
        val error = AtomicReference<Throwable?>()
        val latch = CountDownLatch(1)

        handler.post {
            try {
                result.set(task())
            } catch (t: Throwable) {
                error.set(t)
            } finally {
                latch.countDown()
            }
        }

        if (!latch.await(renderThreadTimeoutMs, TimeUnit.MILLISECONDS)) {
            throw TimeoutException("Native preview render thread timed out after ${renderThreadTimeoutMs}ms.")
        }

        error.get()?.let { throw it }

        @Suppress("UNCHECKED_CAST")
        return result.get() as T
    }

    fun play(fromTimelineUs: Long) {
        startThread()

        val graph = renderer.currentGraph()
        if (graph == null) {
            events.onPreviewError("Preview graph is missing.")
            return
        }

        if (graph.project.durationUs <= 0L) {
            events.onPreviewError("Preview duration is empty.")
            return
        }

        startTimelineUs = fromTimelineUs.coerceIn(0L, graph.project.durationUs)
        startClockMs = SystemClock.elapsedRealtime()
        consecutiveDroppedFrames = 0

        playing.set(true)
        renderer.setPlaying()

        syncTelemetry.startSession(startTimelineUs)

        handler.removeCallbacksAndMessages(null)
        handler.post(renderRunnable)
    }

    fun pause() {
        playing.set(false)
        renderer.setPaused()

        if (::handler.isInitialized) {
            handler.removeCallbacksAndMessages(null)
        }
    }

    fun seekAndRender(timelineTimeUs: Long): NlePreviewFrameResult {
        startThread()

        playing.set(false)
        renderer.setPaused()

        handler.removeCallbacksAndMessages(null)

        return runOnRenderThreadBlocking {
            val result = renderer.renderFrame(timelineTimeUs)
            emitFrameResult(result)
            if (result.rendered) {
                consecutiveDroppedFrames = 0
            }
            result
        }
    }

    fun stop() {
        pause()
    }

    fun release() {
        pause()

        if (thread.isAlive) {
            thread.quitSafely()
        }
    }

    private val renderRunnable = object : Runnable {
        override fun run() {
            if (!playing.get()) return

            val graph = renderer.currentGraph()

            if (graph == null) {
                playing.set(false)
                renderer.setPaused()
                events.onPreviewError("Preview graph is missing.")
                return
            }

            val frameRate = graph.project.frameRate.coerceAtLeast(1.0)
            val frameDurationMs = (1000.0 / frameRate).toLong().coerceAtLeast(8L)

            val elapsedMs = SystemClock.elapsedRealtime() - startClockMs
            val timelineTimeUs = startTimelineUs + elapsedMs * 1000L

            if (timelineTimeUs >= graph.project.durationUs) {
                playing.set(false)
                renderer.setPaused()
                events.onPreviewEnded()
                return
            }

            val before = SystemClock.elapsedRealtime()
            val result = renderer.renderFrame(timelineTimeUs)
            val renderCostMs = SystemClock.elapsedRealtime() - before

            syncTelemetry.onFrame(
                timelineTimeUs = timelineTimeUs,
                renderCostMs = renderCostMs,
            )

            val rendered = emitFrameResult(result)
            if (rendered) {
                consecutiveDroppedFrames = 0
            } else {
                consecutiveDroppedFrames += 1
                if (consecutiveDroppedFrames >= maxConsecutiveDroppedFrames) {
                    playing.set(false)
                    renderer.setPaused()
                    events.onPreviewError(
                        "Native preview stopped after ${consecutiveDroppedFrames} consecutive render failures."
                    )
                    return
                }
            }

            val delayMs = (frameDurationMs - renderCostMs).coerceAtLeast(0L)

            if (renderCostMs > frameDurationMs * 2) {
                events.onPreviewDroppedFrame(
                    timelineTimeUs = timelineTimeUs,
                    reason = "Render too slow: ${renderCostMs}ms",
                )
            }

            handler.postDelayed(this, delayMs)
        }
    }

    private fun emitFrameResult(result: NlePreviewFrameResult): Boolean {
        return if (result.rendered) {
            events.onPreviewFrameRendered(result.timelineTimeUs)
            true
        } else {
            events.onPreviewDroppedFrame(
                timelineTimeUs = result.timelineTimeUs,
                reason = result.reason ?: "Unknown render failure.",
            )
            false
        }
    }
}
