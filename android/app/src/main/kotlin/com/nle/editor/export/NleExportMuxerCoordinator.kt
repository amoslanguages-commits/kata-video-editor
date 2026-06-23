package com.nle.editor.export

import android.media.MediaCodec
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.SystemClock
import com.nle.editor.sync.NleExportSyncTelemetry
import java.nio.ByteBuffer

class NleExportMuxerCoordinator(
    outputPath: String,
    val syncTelemetry: NleExportSyncTelemetry = NleExportSyncTelemetry(),
) {
    private val muxer = MediaMuxer(
        outputPath,
        MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4,
    )

    private var videoFrameIndex = 0

    private var started = false
    private var videoTrackIndex = -1
    private var audioTrackIndex = -1

    private var expectsAudio = true
    private var videoFormatReady = false
    private var audioFormatReady = false

    private val pendingVideoSamples = mutableListOf<PendingSample>()
    private val pendingAudioSamples = mutableListOf<PendingSample>()

    fun setExpectsAudio(value: Boolean) {
        expectsAudio = value
    }

    fun addVideoFormat(format: MediaFormat) {
        if (videoFormatReady) return

        videoTrackIndex = muxer.addTrack(format)
        videoFormatReady = true
        maybeStart()
    }

    fun addAudioFormat(format: MediaFormat) {
        if (audioFormatReady) return

        audioTrackIndex = muxer.addTrack(format)
        audioFormatReady = true
        maybeStart()
    }

    fun writeVideoSample(
        encodedData: ByteBuffer,
        info: MediaCodec.BufferInfo,
        timelineTimeUs: Long = info.presentationTimeUs,
    ) {
        if (info.size <= 0) return

        val before = SystemClock.elapsedRealtime()

        if (!started) {
            pendingVideoSamples.add(PendingSample.copyOf(encodedData, info))
            return
        }

        muxer.writeSampleData(
            videoTrackIndex,
            encodedData,
            info,
        )

        val renderCostMs = SystemClock.elapsedRealtime() - before
        syncTelemetry.onVideoFrame(
            timelineTimeUs     = timelineTimeUs,
            presentationTimeUs = info.presentationTimeUs,
            renderCostMs       = renderCostMs,
        )
        videoFrameIndex++
    }

    fun writeAudioSample(
        encodedData: ByteBuffer,
        info: MediaCodec.BufferInfo,
        durationUs: Long = 0L,
    ) {
        if (info.size <= 0) return
        if (audioTrackIndex < 0) return

        if (!started) {
            pendingAudioSamples.add(PendingSample.copyOf(encodedData, info))
            return
        }

        muxer.writeSampleData(
            audioTrackIndex,
            encodedData,
            info,
        )

        syncTelemetry.onAudioSample(
            presentationTimeUs = info.presentationTimeUs,
            durationUs         = durationUs,
        )
    }

    private fun maybeStart() {
        if (started) return
        if (!videoFormatReady) return
        if (expectsAudio && !audioFormatReady) return

        muxer.start()
        started = true

        for (sample in pendingVideoSamples) {
            muxer.writeSampleData(
                videoTrackIndex,
                sample.data,
                sample.info,
            )
        }

        for (sample in pendingAudioSamples) {
            muxer.writeSampleData(
                audioTrackIndex,
                sample.data,
                sample.info,
            )
        }

        pendingVideoSamples.clear()
        pendingAudioSamples.clear()
    }

    fun release() {
        runCatching {
            if (started) {
                muxer.stop()
            }
        }

        muxer.release()
    }

    private data class PendingSample(
        val data: ByteBuffer,
        val info: MediaCodec.BufferInfo,
    ) {
        companion object {
            fun copyOf(
                source: ByteBuffer,
                info: MediaCodec.BufferInfo,
            ): PendingSample {
                val copy = ByteBuffer.allocateDirect(info.size)

                val oldPosition = source.position()
                val oldLimit = source.limit()

                source.position(info.offset)
                source.limit(info.offset + info.size)

                copy.put(source)
                copy.flip()

                source.position(oldPosition)
                source.limit(oldLimit)

                val newInfo = MediaCodec.BufferInfo()
                newInfo.set(
                    0,
                    info.size,
                    info.presentationTimeUs,
                    info.flags,
                )

                return PendingSample(copy, newInfo)
            }
        }
    }
}
