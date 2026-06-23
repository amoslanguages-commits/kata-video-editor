package com.kata.videoeditor.nle

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.util.Log

/**
 * Silent [AudioTrack] sink — foundation for real audio decoding in a later step.
 *
 * V1 creates a minimal PCM 16-bit stereo 44.1 kHz track in streaming mode,
 * writes silence to keep it alive, and exposes play/pause/release.
 *
 * The track is intentionally kept silent; real decoded PCM data will be fed
 * here once Step 17+ native decode is in place.
 */
class NleSilentAudioSink {
    companion object {
        private const val TAG          = "NleSilentAudioSink"
        private const val SAMPLE_RATE  = 44_100
        private const val CHANNEL_CONF = AudioFormat.CHANNEL_OUT_STEREO
        private const val ENCODING     = AudioFormat.ENCODING_PCM_16BIT
    }

    private var audioTrack: AudioTrack? = null
    private var released = false

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    /**
     * Creates and starts the [AudioTrack].
     * Safe to call multiple times — a no-op after the first successful call.
     */
    fun initialize(): Boolean {
        if (audioTrack != null) return true
        return try {
            val minBuf = AudioTrack.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONF, ENCODING)
            val bufSize = minBuf.coerceAtLeast(4096)

            @Suppress("DEPRECATION")
            val track = AudioTrack(
                AudioManager.STREAM_MUSIC,
                SAMPLE_RATE,
                CHANNEL_CONF,
                ENCODING,
                bufSize,
                AudioTrack.MODE_STREAM
            )
            audioTrack = track
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create AudioTrack: ${e.message}", e)
            false
        }
    }

    fun play() {
        val track = audioTrack ?: return
        if (track.playState != AudioTrack.PLAYSTATE_PLAYING) {
            track.play()
        }
    }

    fun pause() {
        val track = audioTrack ?: return
        if (track.playState == AudioTrack.PLAYSTATE_PLAYING) {
            track.pause()
        }
    }

    fun release() {
        if (released) return
        released = true
        try {
            audioTrack?.stop()
            audioTrack?.release()
        } catch (_: Exception) {}
        audioTrack = null
    }

    val isInitialized: Boolean get() = audioTrack != null
}
