package com.kata.videoeditor.nle.export

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import com.nle.editor.compositor.NleDefaultLayerTextureProvider
import com.nle.editor.compositor.NleMultilayerCompositor
import com.nle.editor.preview.NlePreviewEglRenderer
import com.nle.editor.preview.NlePreviewVideoTextureSource
import com.nle.editor.rendergraph.NleRenderGraphParser
import java.io.File
import kotlin.math.max

class NleCompositedExportRenderer(
    private val emit: (type: String, payload: Map<String, Any?>) -> Unit,
) {
    private val graphParser = NleRenderGraphParser()

    fun render(
        jobId: String,
        renderGraphJson: String,
        outputPath: String,
        profileMap: Map<String, Any?>,
        token: NleExportCancellationToken,
    ) {
        val graph = graphParser.parse(renderGraphJson)
        val width = profileMap.exportInt("width")
            ?: profileMap.exportInt("targetWidth")
            ?: profileMap.exportInt("outputWidth")
            ?: graph.project.width
        val height = profileMap.exportInt("height")
            ?: profileMap.exportInt("resolution")
            ?: profileMap.exportInt("targetHeight")
            ?: graph.project.height
        val frameRate = (profileMap.exportInt("frameRate") ?: graph.project.frameRate.toInt()).coerceAtLeast(1)
        val bitRate = profileMap.exportInt("bitRate")
            ?: profileMap.exportInt("videoBitrate")
            ?: profileMap.exportInt("videoBitrateBps")
            ?: defaultBitrate(width, height, frameRate)
        val durationUs = graph.project.durationUs.coerceAtLeast(1L)
        val frameStepUs = 1_000_000L / frameRate
        val totalFrames = max(1L, (durationUs + frameStepUs - 1L) / frameStepUs)

        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) outputFile.delete()

        emit("export_progress", mapOf("stage" to "Preparing compositor", "progress" to 1))

        var encoder: MediaCodec? = null
        var muxer: MediaMuxer? = null
        var egl: NlePreviewEglRenderer? = null
        var textureProvider: NleDefaultLayerTextureProvider? = null
        var compositor: NleMultilayerCompositor? = null
        val decoderPool = NleVideoDecoderPool()
        var muxerStarted = false
        var muxerTrack = -1

        try {
            val activeEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
            encoder = activeEncoder
            val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
                setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
                setInteger(MediaFormat.KEY_FRAME_RATE, frameRate)
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            }
            activeEncoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            val inputSurface = activeEncoder.createInputSurface()
            activeEncoder.start()

            val activeMuxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            muxer = activeMuxer

            val activeEgl = NlePreviewEglRenderer()
            egl = activeEgl
            activeEgl.initialize(inputSurface)
            activeEgl.makeCurrent()

            val activeTextureProvider = NleDefaultLayerTextureProvider(
                videoTextureSource = NlePreviewVideoTextureSource(
                    graph = graph,
                    decoderPool = decoderPool,
                    preferProxy = false,
                ),
                outputWidth = width,
                outputHeight = height,
            )
            textureProvider = activeTextureProvider

            val activeCompositor = NleMultilayerCompositor(activeTextureProvider)
            compositor = activeCompositor

            var frameIndex = 0L
            while (frameIndex < totalFrames) {
                if (token.cancelled) throw NleExportCancelledException()
                val timelineUs = (frameIndex * frameStepUs).coerceAtMost(durationUs - 1L)
                activeEgl.makeCurrent()
                activeCompositor.renderFrame(
                    graph = graph,
                    timelineTimeUs = timelineUs,
                    outputWidth = width,
                    outputHeight = height,
                    resolvedColorPipeline = null,
                )
                android.opengl.EGLES20.glFinish()
                activeEgl.setPresentationTimeNanos(timelineUs * 1000L)
                activeEgl.swapBuffers()
                drainEncoder(
                    encoder = activeEncoder,
                    muxer = activeMuxer,
                    endOfStream = false,
                    muxerStarted = muxerStarted,
                    currentTrack = muxerTrack,
                ).also { drain ->
                    muxerStarted = drain.muxerStarted
                    muxerTrack = drain.trackIndex
                }

                if (frameIndex % frameRate == 0L || frameIndex == totalFrames - 1L) {
                    val progress = (2 + (frameIndex * 96 / totalFrames)).toInt().coerceIn(2, 98)
                    emit("export_progress", mapOf("stage" to "Compositing", "progress" to progress))
                }
                frameIndex += 1
            }

            activeEncoder.signalEndOfInputStream()
            drainEncoder(
                encoder = activeEncoder,
                muxer = activeMuxer,
                endOfStream = true,
                muxerStarted = muxerStarted,
                currentTrack = muxerTrack,
            )

            emit("export_progress", mapOf("stage" to "Finalizing", "progress" to 99))
        } catch (cancelled: NleExportCancelledException) {
            outputFile.delete()
            throw cancelled
        } finally {
            try { compositor?.release() } catch (_: Throwable) {}
            try { textureProvider?.release() } catch (_: Throwable) {}
            try { decoderPool.releaseAll() } catch (_: Throwable) {}
            try { egl?.release() } catch (_: Throwable) {}
            try { encoder?.stop() } catch (_: Throwable) {}
            try { encoder?.release() } catch (_: Throwable) {}
            try { muxer?.stop() } catch (_: Throwable) {}
            try { muxer?.release() } catch (_: Throwable) {}
        }

        if (!outputFile.exists() || outputFile.length() <= 0L) {
            throw IllegalStateException("Native composited export completed but output file was not created.")
        }
    }

    private fun drainEncoder(
        encoder: MediaCodec,
        muxer: MediaMuxer,
        endOfStream: Boolean,
        muxerStarted: Boolean,
        currentTrack: Int,
    ): DrainState {
        val bufferInfo = MediaCodec.BufferInfo()
        var started = muxerStarted
        var trackIndex = currentTrack

        while (true) {
            val outputBufferId = encoder.dequeueOutputBuffer(bufferInfo, if (endOfStream) 10_000L else 0L)
            when {
                outputBufferId == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) return DrainState(started, trackIndex)
                }
                outputBufferId == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (started) throw IllegalStateException("Encoder output format changed after muxer started.")
                    trackIndex = muxer.addTrack(encoder.outputFormat)
                    muxer.start()
                    started = true
                }
                outputBufferId >= 0 -> {
                    val encodedData = encoder.getOutputBuffer(outputBufferId)
                        ?: throw IllegalStateException("Encoder output buffer $outputBufferId was null.")
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }
                    if (bufferInfo.size > 0) {
                        if (!started || trackIndex < 0) throw IllegalStateException("Muxer was not started before encoded data arrived.")
                        encodedData.position(bufferInfo.offset)
                        encodedData.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(trackIndex, encodedData, bufferInfo)
                    }
                    val eos = bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                    encoder.releaseOutputBuffer(outputBufferId, false)
                    if (eos) return DrainState(started, trackIndex)
                }
            }
        }
    }

    private fun defaultBitrate(width: Int, height: Int, frameRate: Int): Int {
        val pixels = width.toLong() * height.toLong()
        val bps = pixels * frameRate.toLong() / 2L
        return bps.coerceIn(4_000_000L, 60_000_000L).toInt()
    }
}

private data class DrainState(
    val muxerStarted: Boolean,
    val trackIndex: Int,
)

internal class NleExportCancellationToken {
    @Volatile var cancelled: Boolean = false
}

internal class NleExportCancelledException : RuntimeException("Export cancelled")

internal fun Map<String, Any?>.exportInt(key: String): Int? {
    val value = this[key] ?: return null
    return when (value) {
        is Int -> value
        is Long -> value.toInt()
        is Double -> value.toInt()
        is Float -> value.toInt()
        is Number -> value.toInt()
        is String -> value.toIntOrNull()
        else -> null
    }
}
