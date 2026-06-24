package com.kata.videoeditor.nle.export

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.nio.ByteBuffer
import kotlin.math.abs

/**
 * Decodes video frames from a single source asset using [MediaCodec] in surface output mode.
 *
 * Frames are decoded onto a [NleDecoderOutputSurface] (a SurfaceTexture/OES texture pair).
 * The caller retrieves each frame by calling [decodeFrameAtOrAfter], which handles seeking,
 * feeding the extractor, and draining the decoder.
 *
 * **Thread model**: [prepare] and [decodeFrameAtOrAfter] must be called on the GL thread
 * (the thread where [NleEglWindowSurface.makeCurrent] was called), because the
 * [NleDecoderOutputSurface] allocates and updates an OES texture in that context.
 *
 * **Lifecycle**: Call [prepare] once, then call [decodeFrameAtOrAfter] repeatedly,
 * then call [release] in a `finally` block.
 */
class NleVideoSourceDecoder(val asset: NleTrueExportAsset) {

    private val extractor   = MediaExtractor()
    private lateinit var decoder: MediaCodec
    private lateinit var outputSurface: NleDecoderOutputSurface

    private val bufferInfo = MediaCodec.BufferInfo()

    private var started   = false
    private var inputDone  = false
    private var outputDone = false

    private var lastQueuedSampleTimeUs = -1L
    private var lastDecodedTimeUs      = -1L
    private var lastSeekUs             = Long.MIN_VALUE

    // ── Public API ────────────────────────────────────────────────────────────

    /**
     * Opens the asset, selects the video track, creates the decoder, and starts it.
     *
     * Must be called exactly once before [decodeFrameAtOrAfter].
     * The caller's EGL context must be current (for OES texture allocation).
     */
    fun prepare() {
        if (started) return

        extractor.setDataSource(asset.path)

        val (_, format) = NleMediaTrackUtil.selectFirstVideoTrack(extractor)

        val mime = format.getString(MediaFormat.KEY_MIME)
            ?: throw IllegalStateException("Missing video MIME type for asset: ${asset.id}")

        outputSurface = NleDecoderOutputSurface()

        try {
            decoder = MediaCodec.createDecoderByType(mime)
            decoder.configure(format, outputSurface.surface, null, 0)
        } catch (e: Exception) {
            if (mime == "video/dolby-vision") {
                // iPhone Dolby Vision profile 8.4 is backwards compatible with HEVC
                decoder = MediaCodec.createDecoderByType("video/hevc")
                format.setString(MediaFormat.KEY_MIME, "video/hevc")
                decoder.configure(format, outputSurface.surface, null, 0)
            } else {
                throw e
            }
        }
        decoder.start()

        started = true
    }

    /**
     * Returns the first decoded frame whose presentation timestamp is ≥ [targetUs].
     *
     * If the decoder needs to seek (because [targetUs] is far from the last position,
     * or earlier), it flushes the codec and re-seeks the extractor.
     *
     * @throws IllegalStateException if no frame could be decoded.
     */
    fun decodeFrameAtOrAfter(targetUs: Long): NleDecodedVideoFrame {
        ensurePrepared()

        val jumpTooFar  = lastDecodedTimeUs >= 0 && abs(targetUs - lastDecodedTimeUs) > 1_000_000L
        val isBackwards = lastDecodedTimeUs >= 0 && targetUs < lastDecodedTimeUs

        if (isBackwards || jumpTooFar || lastSeekUs == Long.MIN_VALUE) {
            seekTo(targetUs)
        }

        val frameToleranceUs = 50_000L // 50 ms tolerance for sync frames
        var renderAttempts = 0
        val decodeStartTimeMs = android.os.SystemClock.elapsedRealtime()

        while (!outputDone) {
            if (android.os.SystemClock.elapsedRealtime() - decodeStartTimeMs > 1500L) {
                throw IllegalStateException("Seek taking too long (sparse keyframes). Please generate proxies.")
            }

            feedDecoderInput()

            val outputIndex = decoder.dequeueOutputBuffer(bufferInfo, 10_000L)

            when {
                outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    // Decoder has no output yet; keep feeding input.
                }

                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    // Decoder format update — safe to ignore for surface output.
                }

                outputIndex >= 0 -> {
                    val ptsUs = bufferInfo.presentationTimeUs
                    val isEos = bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0

                    if (isEos) {
                        outputDone = true
                        decoder.releaseOutputBuffer(outputIndex, false)

                        // At EOS, re-seek to the last decoded frame to produce a valid result.
                        if (lastDecodedTimeUs >= 0) {
                            seekTo(lastDecodedTimeUs)
                            continue
                        }

                        throw IllegalStateException(
                            "Decoder reached EOS before producing any frame for asset: ${asset.id}"
                        )
                    }

                    // Render the frame only when we have reached (or passed) the target time.
                    val shouldRender = ptsUs >= targetUs - frameToleranceUs
                    decoder.releaseOutputBuffer(outputIndex, shouldRender)

                    if (shouldRender) {
                        renderAttempts += 1
                        try {
                            val frame = outputSurface.awaitFrameAndUpdate()
                            lastDecodedTimeUs = ptsUs
                            return frame
                        } catch (e: RuntimeException) {
                            if (renderAttempts >= 4) throw e
                            continue
                        }
                    }
                }
            }
        }

        throw IllegalStateException(
            "Could not decode frame at $targetUs µs from asset: ${asset.id}"
        )
    }

    // ── Release ──────────────────────────────────────────────────────────────

    /**
     * Stops the decoder, releases the extractor, and frees the output surface.
     *
     * Must be called from the GL thread (OES texture deletion).
     */
    fun release() {
        if (!started) return

        try { decoder.stop()          } catch (_: Throwable) {}
        try { decoder.release()       } catch (_: Throwable) {}
        try { extractor.release()     } catch (_: Throwable) {}
        try { outputSurface.release() } catch (_: Throwable) {}

        started = false
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private fun feedDecoderInput() {
        if (inputDone) return

        val inputIndex = decoder.dequeueInputBuffer(0)
        if (inputIndex < 0) return

        val inputBuffer: ByteBuffer = decoder.getInputBuffer(inputIndex)
            ?: throw IllegalStateException("Decoder input buffer at index $inputIndex is null.")

        val sampleSize = extractor.readSampleData(inputBuffer, 0)

        if (sampleSize < 0) {
            // End of stream from extractor.
            decoder.queueInputBuffer(
                inputIndex, 0, 0, 0L,
                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
            )
            inputDone = true
            return
        }

        val sampleTimeUs = extractor.sampleTime
        val sampleFlags  = extractor.sampleFlags

        decoder.queueInputBuffer(inputIndex, 0, sampleSize, sampleTimeUs, sampleFlags)
        lastQueuedSampleTimeUs = sampleTimeUs
        extractor.advance()
    }

    private fun seekTo(targetUs: Long) {
        ensurePrepared()

        extractor.seekTo(
            targetUs.coerceAtLeast(0L),
            MediaExtractor.SEEK_TO_PREVIOUS_SYNC,
        )

        decoder.flush()

        inputDone  = false
        outputDone = false
        lastQueuedSampleTimeUs = -1L
        lastDecodedTimeUs      = -1L
        lastSeekUs             = targetUs
    }

    private fun ensurePrepared() {
        if (!started) prepare()
    }
}
