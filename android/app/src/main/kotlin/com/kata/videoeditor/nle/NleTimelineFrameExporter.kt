package com.kata.videoeditor.nle

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import com.kata.videoeditor.nle.gpu.NleCompositorSession

/**
 * V1 timeline frame exporter.
 *
 * Algorithm:
 *   1. For each clip on the [NleExportTimeline], compute the set of output
 *      frame timestamps owned by that clip.
 *   2. Map each output timestamp back to a source-file timestamp via the
 *      clip's trim offset.
 *   3. Extract a bitmap from the source file at the source timestamp using
 *      [MediaMetadataRetriever].
 *   4. Scale / letterbox the bitmap to the target resolution and draw it onto
 *      the [MediaCodec] input Surface.
 *   5. Drain the encoder output into [MediaMuxer].
 *
 * Limitations (V1):
 *   • Frame sampling only — not a true decoder pipeline.
 *   • Video track only; no audio.
 *   • Hard cuts only; no transitions.
 */
class NleTimelineFrameExporter(
    private val compositorSession: NleCompositorSession? = null
) {

    /**
     * Render [timeline] to [outputPath] using [profile] settings.
     *
     * @param cancelled  Shared flag; set to `true` by another thread to abort.
     * @param onProgress Callback with [0, 100] progress values.
     */
    fun export(
        timeline: NleExportTimeline,
        outputPath: String,
        profile: NleExportProfile,
        cancelled: AtomicBoolean,
        onProgress: (Int) -> Unit
    ) {
        // Ensure even dimensions (H.264 requirement)
        val outW = (profile.width  / 2) * 2
        val outH = (profile.height / 2) * 2

        val frameDurationMicros = 1_000_000L / profile.frameRate
        val totalFrames = (timeline.totalDurationMicros / frameDurationMicros).toInt()
            .coerceAtLeast(1)

        // Set up MediaCodec encoder
        val format = MediaFormat.createVideoFormat(profile.codec, outW, outH).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE,  profile.bitrateBps)
            setInteger(MediaFormat.KEY_FRAME_RATE, profile.frameRate)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, profile.gopInterval)
        }

        val encoder = MediaCodec.createEncoderByType(profile.codec)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val inputSurface = encoder.createInputSurface()
        encoder.start()

        // Ensure output directory exists
        File(outputPath).parentFile?.mkdirs()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var muxerTrackIndex = -1
        var muxerStarted = false

        val bufferInfo = MediaCodec.BufferInfo()

        // Paint used for bitmap blitting
        val paint = Paint(Paint.FILTER_BITMAP_FLAG)

        var frameIndex = 0

        try {
            // Track-level retriever cache (keyed by source path)
            val retrieverCache = mutableMapOf<String, MediaMetadataRetriever>()

            for (clip in timeline.clips) {
                if (cancelled.get()) break

                // Pre-open the retriever for this clip
                val retriever = retrieverCache.getOrPut(clip.sourcePath) {
                    MediaMetadataRetriever().also { it.setDataSource(clip.sourcePath) }
                }

                // Calculate which frames fall inside this clip
                val clipFirstFrame = (clip.timelineStartMicros / frameDurationMicros).toInt()
                val clipLastFrame  = ((clip.timelineEndMicros - 1) / frameDurationMicros).toInt()

                for (f in clipFirstFrame..clipLastFrame) {
                    if (cancelled.get()) break

                    val timelineMicros = f * frameDurationMicros
                    // Source timestamp = clip source-in + offset into this clip
                    val clipOffsetMicros = timelineMicros - clip.timelineStartMicros
                    val sourceMicros = clip.sourceInMicros + clipOffsetMicros

                    // ── GPU compositor render path (primary) ─────────────────
                    val presentationTimeNanos = timelineMicros * 1_000L
                    var gpuRendered = false

                    if (compositorSession != null) {
                        try {
                            compositorSession.renderExportFrame(
                                projectId              = "export",
                                renderGraphJson        = timeline.renderGraphJson,
                                timelineTimeMicros     = timelineMicros,
                                encoderSurface         = inputSurface,
                                width                  = outW,
                                height                 = outH,
                                presentationTimeNanos  = presentationTimeNanos
                            )
                            gpuRendered = true
                        } catch (_: Exception) {
                            // Fall through to Canvas blit below
                        }
                    }

                    // ── Canvas blit fallback ─────────────────────────────────
                    if (!gpuRendered) {
                        // Retrieve frame bitmap
                        val raw = retriever.getFrameAtTime(
                            sourceMicros,
                            MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                        )

                        val bmp = raw ?: createBlackBitmap(outW, outH)

                        // Draw onto encoder input surface
                        val canvas: Canvas? = inputSurface.lockHardwareCanvas()
                            ?: inputSurface.lockCanvas(null)

                        if (canvas != null) {
                            drawBitmapFit(canvas, bmp, outW, outH, paint)
                            inputSurface.unlockCanvasAndPost(canvas)
                        }

                        raw?.recycle()
                    }

                    // Signal encoder with presentation time
                    // (Surface-based encoding: PTS is set via signalEndOfInputStream or
                    //  queued via EGL; here we rely on canvas submission timing and then
                    //  drain using dequeueOutputBuffer)
                    drainEncoder(
                        encoder      = encoder,
                        muxer        = muxer,
                        bufferInfo   = bufferInfo,
                        muxerTrack   = { muxerTrackIndex },
                        setMuxerTrack = { idx ->
                            muxerTrackIndex = idx
                            if (!muxerStarted) {
                                muxer.start()
                                muxerStarted = true
                            }
                        },
                        endOfStream  = false,
                        presentationTimeMicros = timelineMicros
                    )

                    frameIndex++
                    val progress = ((frameIndex.toFloat() / totalFrames) * 98).toInt().coerceIn(0, 98)
                    onProgress(progress)
                }
            }

            // Close all retrievers
            retrieverCache.values.forEach { it.release() }

            if (!cancelled.get()) {
                // Signal end of stream
                encoder.signalEndOfInputStream()
                drainEncoder(
                    encoder      = encoder,
                    muxer        = muxer,
                    bufferInfo   = bufferInfo,
                    muxerTrack   = { muxerTrackIndex },
                    setMuxerTrack = { idx ->
                        muxerTrackIndex = idx
                        if (!muxerStarted) {
                            muxer.start()
                            muxerStarted = true
                        }
                    },
                    endOfStream  = true,
                    presentationTimeMicros = timeline.totalDurationMicros
                )
                onProgress(100)
            }
        } finally {
            try { encoder.stop()  } catch (_: Exception) {}
            try { encoder.release() } catch (_: Exception) {}
            try { inputSurface.release() } catch (_: Exception) {}
            if (muxerStarted) {
                try { muxer.stop()    } catch (_: Exception) {}
            }
            try { muxer.release() } catch (_: Exception) {}

            if (cancelled.get()) {
                // Clean up partial output
                File(outputPath).takeIf { it.exists() }?.delete()
            }
        }
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    /** Drain encoded data from the codec into the muxer. */
    private fun drainEncoder(
        encoder: MediaCodec,
        muxer: MediaMuxer,
        bufferInfo: MediaCodec.BufferInfo,
        muxerTrack: () -> Int,
        setMuxerTrack: (Int) -> Unit,
        endOfStream: Boolean,
        presentationTimeMicros: Long
    ) {
        val timeoutUs = if (endOfStream) 10_000L else 0L
        while (true) {
            val outputBufferIndex = encoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
            when {
                outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) break
                }
                outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    setMuxerTrack(muxer.addTrack(encoder.outputFormat))
                }
                outputBufferIndex >= 0 -> {
                    val outputBuffer = encoder.getOutputBuffer(outputBufferIndex)
                    if (outputBuffer != null &&
                        bufferInfo.size > 0 &&
                        (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) == 0
                    ) {
                        bufferInfo.presentationTimeUs = presentationTimeMicros
                        if (muxerTrack() >= 0) {
                            muxer.writeSampleData(muxerTrack(), outputBuffer, bufferInfo)
                        }
                    }
                    encoder.releaseOutputBuffer(outputBufferIndex, false)
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
        }
    }

    /** Scale and letter-box [bmp] into the target canvas dimensions. */
    private fun drawBitmapFit(
        canvas: Canvas,
        bmp: Bitmap,
        outW: Int,
        outH: Int,
        paint: Paint
    ) {
        // Fill background black
        canvas.drawRGB(0, 0, 0)

        val scaleW = outW.toFloat() / bmp.width
        val scaleH = outH.toFloat() / bmp.height
        val scale  = minOf(scaleW, scaleH)

        val drawW  = bmp.width  * scale
        val drawH  = bmp.height * scale
        val left   = (outW - drawW) / 2f
        val top    = (outH - drawH) / 2f

        val matrix = Matrix().apply {
            setScale(scale, scale)
            postTranslate(left, top)
        }
        canvas.drawBitmap(bmp, matrix, paint)
    }

    private fun createBlackBitmap(w: Int, h: Int): Bitmap {
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        bmp.eraseColor(android.graphics.Color.BLACK)
        return bmp
    }
}
