package com.nle.editor.preview

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Handler
import android.os.HandlerThread
import com.nle.editor.audio.NlePreviewAudioMixer
import com.nle.editor.rendergraph.NleRenderGraph
import java.util.concurrent.atomic.AtomicBoolean

class NlePreviewAudioPlayer(
    private val mixer: NlePreviewAudioMixer
) {
    private var audioTrack: AudioTrack? = null
    private val thread = HandlerThread("NlePreviewAudioPlayer")
    private lateinit var handler: Handler
    private val playing = AtomicBoolean(false)
    
    private var currentTimelineUs = 0L
    private var startTimelineUsWhenPlayed = 0L
    private val chunkSizeFrames = 2048

    fun startThread() {
        if (!thread.isAlive) {
            thread.start()
            handler = Handler(thread.looper)
        }
    }

    fun prepare(graph: NleRenderGraph) {
        val sampleRate = graph.audioMix.sampleRate.coerceAtLeast(8000)
        val channels = graph.audioMix.channels.coerceIn(1, 2)
        val channelConfig = if (channels == 2) AudioFormat.CHANNEL_OUT_STEREO else AudioFormat.CHANNEL_OUT_MONO

        val minBufferSize = AudioTrack.getMinBufferSize(
            sampleRate,
            channelConfig,
            AudioFormat.ENCODING_PCM_FLOAT
        )

        audioTrack?.release()
        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(channelConfig)
                    .build()
            )
            .setBufferSizeInBytes(minBufferSize * 4) // Float is 4 bytes
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
    }

    fun play(fromTimelineUs: Long) {
        startThread()
        currentTimelineUs = fromTimelineUs
        startTimelineUsWhenPlayed = fromTimelineUs
        playing.set(true)
        
        audioTrack?.let {
            it.pause()
            it.flush()
            it.play()
        }

        handler.removeCallbacksAndMessages(null)
        handler.post(audioRunnable)
    }

    fun pause() {
        playing.set(false)
        val track = audioTrack
        if (track != null) {
            val headUs = getPlaybackHeadPositionUs()
            track.pause()
            currentTimelineUs = headUs
        }
        if (::handler.isInitialized) {
            handler.removeCallbacksAndMessages(null)
        }
    }

    fun seek(timelineTimeUs: Long) {
        currentTimelineUs = timelineTimeUs
        startTimelineUsWhenPlayed = timelineTimeUs
        audioTrack?.let {
            it.pause()
            it.flush()
            if (playing.get()) {
                it.play()
            }
        }
    }

    fun getPlaybackHeadPositionUs(): Long {
        val track = audioTrack ?: return currentTimelineUs
        if (!playing.get()) {
            return currentTimelineUs 
        }
        val headPositionFrames = track.playbackHeadPosition.toLong()
        val sampleRate = track.sampleRate.toLong()
        if (sampleRate <= 0) return currentTimelineUs
        
        val elapsedUs = (headPositionFrames * 1_000_000L) / sampleRate
        return startTimelineUsWhenPlayed + elapsedUs
    }

    fun release() {
        pause()
        audioTrack?.release()
        audioTrack = null
        if (thread.isAlive) {
            thread.quitSafely()
        }
    }

    private val audioRunnable = object : Runnable {
        override fun run() {
            if (!playing.get()) return
            val track = audioTrack ?: return

            val chunk = mixer.mixPreviewChunk(currentTimelineUs, chunkSizeFrames)
            if (chunk != null && chunk.data.isNotEmpty()) {
                val written = track.write(chunk.data, 0, chunk.data.size, AudioTrack.WRITE_BLOCKING)
                if (written > 0) {
                    val framesWritten = written / chunk.channelCount
                    val durationUs = (framesWritten * 1_000_000L) / chunk.sampleRate
                    currentTimelineUs += durationUs
                }
            } else {
                val sampleRate = track.sampleRate
                val durationUs = (chunkSizeFrames * 1_000_000L) / sampleRate
                
                val emptyData = FloatArray(chunkSizeFrames * track.channelCount)
                track.write(emptyData, 0, emptyData.size, AudioTrack.WRITE_BLOCKING)
                currentTimelineUs += durationUs
            }

            if (playing.get()) {
                handler.post(this)
            }
        }
    }
}
