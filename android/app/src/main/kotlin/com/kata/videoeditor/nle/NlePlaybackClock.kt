package com.kata.videoeditor.nle

import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.SystemClock

/**
 * Native playback clock that runs on a dedicated [HandlerThread].
 *
 * - Ticks at ~60 fps (16 ms interval) while playing.
 * - Clamps playhead to [0, durationMicros] and auto-pauses at end.
 * - Thread-safe: all public methods may be called from any thread; they
 *   are serialised onto the clock thread via [Handler.post].
 *
 * @param durationMicros  Total timeline duration. Pass 0 to disable end-clamp.
 * @param onTick          Callback invoked on the clock thread with the current
 *                        playhead position (micros) and isPlaying flag.
 * @param onEnded         Callback invoked once when playback reaches the end.
 */
class NlePlaybackClock(
    private var durationMicros: Long = 0L,
    private val onTick: (playheadMicros: Long, isPlaying: Boolean) -> Unit,
    private val onEnded: () -> Unit = {}
) {
    companion object {
        private const val TICK_INTERVAL_MS = 16L          // ~60 fps
        private const val MICROS_PER_MS    = 1_000L
    }

    private val thread = HandlerThread("nle-playback-clock").also { it.start() }
    private val handler = Handler(thread.looper)
    private val mainHandler = Handler(Looper.getMainLooper())

    // ── Volatile state (read from multiple threads) ───────────────────────────

    @Volatile private var playheadMicros: Long = 0L
    @Volatile private var isPlaying: Boolean  = false
    @Volatile private var playbackRate: Float  = 1.0f

    /** Wall-clock ms at which the clock was last started / resumed. */
    private var startWallMs: Long = 0L
    /** Playhead value (micros) at the moment the clock was last started. */
    private var startPlayheadMicros: Long = 0L

    // ── Runnable that drives the ticker ──────────────────────────────────────

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (!isPlaying) return

            val elapsed = (SystemClock.elapsedRealtime() - startWallMs) * MICROS_PER_MS
            val pos     = startPlayheadMicros + (elapsed * playbackRate).toLong()

            val clamped = if (durationMicros > 0L) pos.coerceAtMost(durationMicros) else pos
            playheadMicros = clamped

            onTick(clamped, true)

            if (durationMicros > 0L && clamped >= durationMicros) {
                isPlaying = false
                mainHandler.post { onEnded() }
                return
            }

            handler.postDelayed(this, TICK_INTERVAL_MS)
        }
    }

    // ── Public API (thread-safe) ─────────────────────────────────────────────

    val currentPlayheadMicros: Long get() = playheadMicros
    val currentIsPlaying: Boolean   get() = isPlaying

    fun play() {
        handler.post {
            if (isPlaying) return@post
            isPlaying              = true
            startWallMs            = SystemClock.elapsedRealtime()
            startPlayheadMicros    = playheadMicros
            handler.post(tickRunnable)
        }
    }

    fun pause() {
        handler.post {
            if (!isPlaying) return@post
            // Snapshot current position before stopping
            val elapsed = (SystemClock.elapsedRealtime() - startWallMs) * MICROS_PER_MS
            playheadMicros = startPlayheadMicros + (elapsed * playbackRate).toLong()
            isPlaying = false
            handler.removeCallbacks(tickRunnable)
            onTick(playheadMicros, false)
        }
    }

    fun seek(positionMicros: Long) {
        handler.post {
            val clamped = if (durationMicros > 0L)
                positionMicros.coerceIn(0L, durationMicros)
            else
                positionMicros.coerceAtLeast(0L)

            playheadMicros      = clamped
            startPlayheadMicros = clamped
            startWallMs         = SystemClock.elapsedRealtime()
            onTick(clamped, isPlaying)
        }
    }

    fun setRate(rate: Float) {
        handler.post {
            // Snapshot position at current rate before changing
            if (isPlaying) {
                val elapsed = (SystemClock.elapsedRealtime() - startWallMs) * MICROS_PER_MS
                playheadMicros      = startPlayheadMicros + (elapsed * playbackRate).toLong()
                startPlayheadMicros = playheadMicros
                startWallMs         = SystemClock.elapsedRealtime()
            }
            playbackRate = rate.coerceIn(0.25f, 4.0f)
        }
    }

    fun setDuration(micros: Long) {
        handler.post { durationMicros = micros.coerceAtLeast(0L) }
    }

    fun release() {
        handler.post {
            isPlaying = false
            handler.removeCallbacks(tickRunnable)
        }
        thread.quitSafely()
    }
}
