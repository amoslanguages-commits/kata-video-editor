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
    var audioPlayer: NlePreviewAudioPlayer? = null,
) {
    private val thread = HandlerThread("NlePreviewFrameScheduler")
    private lateinit var handler: Handler

    private val playing = AtomicBoolean(false)

    private var startTimelineUs: Long = 0L
    private var startClockMs: Long = 0L
    private var consecutiveDroppedFrames = 0
    private var lastRenderCostMs: Long = 0L

    private val renderThreadTimeoutMs = 8000L
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
        audioPlayer?.play(startTimelineUs)

        syncTelemetry.startSession(startTimelineUs)

        handler.removeCallbacksAndMessages(null)
        handler.post(renderRunnable)
    }

    fun pause() {
        playing.set(false)
        renderer.setPaused()
        audioPlayer?.pause()

        if (::handler.isInitialized) {
            handler.removeCallbacksAndMessages(null)
        }
    }

    fun seekAndRender(timelineTimeUs: Long): NlePreviewFrameResult {
        startThread()

        playing.set(false)
        renderer.setPaused()
        audioPlayer?.seek(timelineTimeUs)

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

            // If audio player is available, use its playback head for perfect A/V sync.
            // Otherwise, fallback to system clock.
            val baseTimelineTimeUs = audioPlayer?.getPlaybackHeadPositionUs() ?: run {
                val elapsedMs = SystemClock.elapsedRealtime() - startClockMs
                startTimelineUs + elapsedMs * 1000L
            }

            // Predictive A/V sync: The frame we request will take `lastRenderCostMs` to decode.
            // By the time it appears on screen, the audio will have advanced by that amount.
            // So we request the frame from the FUTURE to perfectly align with the audio when it's drawn.
            val expectedDecodeDelayUs = (lastRenderCostMs * 1000L).coerceIn(0L, 200_000L) // cap at 200ms
            val timelineTimeUs = baseTimelineTimeUs + expectedDecodeDelayUs

            if (baseTimelineTimeUs >= graph.project.durationUs) {
                playing.set(false)
                renderer.setPaused()
                audioPlayer?.pause()
                events.onPreviewEnded()
                return
            }

            val before = SystemClock.elapsedRealtime()
            val result = renderer.renderFrame(timelineTimeUs)
            lastRenderCostMs = SystemClock.elapsedRealtime() - before

            syncTelemetry.onFrame(
                timelineTimeUs = timelineTimeUs,
                renderCostMs = lastRenderCostMs,
            )

            val rendered = emitFrameResult(result)
            if (rendered) {
                consecutiveDroppedFrames = 0
            } else {
                consecutiveDroppedFrames += 1
                if (consecutiveDroppedFrames >= maxConsecutiveDroppedFrames) {
                    playing.set(false)
                    renderer.setPaused()
                    audioPlayer?.pause()
                    events.onPreviewError(
                        "Native preview stopped after ${consecutiveDroppedFrames} consecutive render failures."
                    )
                    return
                }
            }

            val delayMs = (frameDurationMs - lastRenderCostMs).coerceAtLeast(0L)

            if (lastRenderCostMs > frameDurationMs * 2) {
                // If rendering is slow, drop video frame warning but keep going. Audio will keep playing.
                events.onPreviewDroppedFrame(
                    timelineTimeUs = timelineTimeUs,
                    reason = "Render too slow: ${lastRenderCostMs}ms",
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
