package com.kata.videoeditor.nle.export

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.view.Surface
import com.nle.editor.export.NleExportMuxerCoordinator
import java.io.File
import java.nio.ByteBuffer

/**
 * Wraps a MediaCodec AVC encoder and MediaMuxer for the V2 true-decoder export pipeline.
 *
 * Usage:
 * 1. Construct with output parameters.
 * 2. Call [prepare] — creates the encoder, [inputSurface], and the muxer file.
 * 3. Render frames onto [inputSurface] via EGL (see [NleTrueDecoderVideoExporter]).
 * 4. Call [drain] after each frame to push encoded data into the muxer.
 * 5. Call [drain] with `endOfStream = true` to finalize.
 * 6. Call [release] in a `finally` block.
 */
class NleSurfaceVideoEncoder(
    private val outputPath: String,
    private val width: Int,
    private val height: Int,
    private val frameRate: Int,
    private val bitrate: Int,
    private val iFrameIntervalSeconds: Int,
    private val muxerCoordinator: NleExportMuxerCoordinator? = null,
) {
    private lateinit var encoder: MediaCodec
    private lateinit var muxer: MediaMuxer

    private val bufferInfo = MediaCodec.BufferInfo()

    private var trackIndex  = -1
    private var muxerStarted = false

    /** The encoder input surface that callers render frames onto via EGL. */
    lateinit var inputSurface: Surface
        private set

    // ── Lifecycle ────────────────────────────────────────────────────────────

    /** Creates the encoder, muxer, and [inputSurface]. Must be called once before rendering. */
    fun prepare() {
        File(outputPath).parentFile?.mkdirs()
        File(outputPath).delete()

        val format = MediaFormat.createVideoFormat(
            MediaFormat.MIMETYPE_VIDEO_AVC,
            width,
            height,
        )
        format.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface,
        )
        format.setInteger(MediaFormat.KEY_BIT_RATE,         bitrate)
        format.setInteger(MediaFormat.KEY_FRAME_RATE,       frameRate)
        format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, iFrameIntervalSeconds)

        encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        inputSurface = encoder.createInputSurface()
        encoder.start()

        if (muxerCoordinator == null) {
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        }
    }

    // ── Drain ────────────────────────────────────────────────────────────────

    /**
     * Drains available encoded data from the encoder into the muxer.
     *
     * If [endOfStream] is true, signals end-of-stream to the encoder and loops
     * until the EOS flag is received.
     */
    fun drain(endOfStream: Boolean) {
        if (endOfStream) {
            encoder.signalEndOfInputStream()
        }

        while (true) {
            val outputIndex = encoder.dequeueOutputBuffer(bufferInfo, 10_000L)

            when {
                outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) return
                    // Still waiting for EOS — keep draining.
                }

                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (muxerCoordinator != null) {
                        muxerCoordinator.addVideoFormat(encoder.outputFormat)
                    } else {
                        check(!muxerStarted) { "Encoder output format changed twice." }
                        trackIndex = muxer.addTrack(encoder.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                }

                outputIndex >= 0 -> {
                    val encodedData: ByteBuffer = encoder.getOutputBuffer(outputIndex)
                        ?: throw IllegalStateException("Encoder output buffer is null.")

                    // Skip codec-config buffers — the muxer learns the format from addTrack.
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }

                    if (bufferInfo.size > 0) {
                        if (muxerCoordinator != null) {
                            encodedData.position(bufferInfo.offset)
                            encodedData.limit(bufferInfo.offset + bufferInfo.size)
                            muxerCoordinator.writeVideoSample(encodedData, bufferInfo)
                        } else {
                            check(muxerStarted) { "Muxer has not started yet." }
                            encodedData.position(bufferInfo.offset)
                            encodedData.limit(bufferInfo.offset + bufferInfo.size)
                            muxer.writeSampleData(trackIndex, encodedData, bufferInfo)
                        }
                    }

                    val eos = bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                    encoder.releaseOutputBuffer(outputIndex, false)

                    if (eos) return
                }
            }
        }
    }

    // ── Release ──────────────────────────────────────────────────────────────

    /** Stops and releases the encoder, muxer, and input surface. */
    fun release() {
        try { if (::inputSurface.isInitialized) inputSurface.release() } catch (_: Throwable) {}
        try { if (::encoder.isInitialized)      encoder.stop()          } catch (_: Throwable) {}
        try { if (::encoder.isInitialized)      encoder.release()       } catch (_: Throwable) {}
        if (muxerCoordinator == null) {
            try { if (muxerStarted)                 muxer.stop()            } catch (_: Throwable) {}
            try { if (::muxer.isInitialized)        muxer.release()         } catch (_: Throwable) {}
        }
    }
}
