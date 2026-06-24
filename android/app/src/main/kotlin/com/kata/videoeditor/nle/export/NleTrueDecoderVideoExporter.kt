package com.kata.videoeditor.nle.export

import android.opengl.EGL14
import com.kata.videoeditor.nle.NleExportProfile
import com.kata.videoeditor.nle.NleNativeErrorCode
import com.kata.videoeditor.nle.gpu.NleEglCore
import com.kata.videoeditor.nle.gpu.NleEglWindowSurface
import com.nle.editor.rendergraph.NleRenderGraphParser
import com.nle.editor.compositor.NleMultilayerCompositor
import com.nle.editor.compositor.NleDefaultLayerTextureProvider
import com.nle.editor.export.NleDecoderPoolVideoTextureSource
import com.nle.editor.export.NleExportMuxerCoordinator
import com.nle.editor.export.NleExportProgressCombiner
import com.nle.editor.color.*
import com.nle.editor.colorpipeline.*
import com.kata.videoeditor.nle.NleContextHolder
import org.json.JSONObject
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Top-level orchestrator for the V2 true-decoder video export pipeline.
 *
 * It initializes the EGL context, creates a MediaCodec encoder + decoder pool,
 * and runs a timestamp-driven loop from 0 to timeline duration, rendering
 * composited frames to the encoder surface.
 */
class NleTrueDecoderVideoExporter {

    /**
     * Render [renderGraphJson] to [outputPath] using [profile] settings.
     *
     * @param cancelled  Shared flag; set to `true` by another thread to abort.
     * @param onProgress Callback with [0, 100] progress values.
     */
    fun export(
        renderGraphJson: String,
        outputPath: String,
        profile: NleExportProfile,
        cancelled: AtomicBoolean,
        onProgress: (Int) -> Unit
    ) {
        val parser = NleRenderGraphParser()
        val graph = parser.parse(renderGraphJson)

        val hasAudio = graph.composition.hasAudio && graph.audioMix.enabled

        val muxerCoordinator = NleExportMuxerCoordinator(outputPath)
        muxerCoordinator.setExpectsAudio(hasAudio)

        val progressCombiner = NleExportProgressCombiner()

        // Ensure even dimensions (H.264 requirement)
        val outW = (profile.width / 2) * 2
        val outH = (profile.height / 2) * 2

        val frameDurationUs = 1_000_000L / profile.frameRate
        val totalFrames = (graph.project.durationUs / frameDurationUs).toInt().coerceAtLeast(1)

        val encoder = NleSurfaceVideoEncoder(
            outputPath = outputPath,
            width = outW,
            height = outH,
            frameRate = profile.frameRate,
            bitrate = profile.bitrateBps,
            iFrameIntervalSeconds = profile.gopInterval,
            muxerCoordinator = muxerCoordinator
        )

        var eglCore: NleEglCore? = null
        var eglSurface: NleEglWindowSurface? = null
        var compositor: NleMultilayerCompositor? = null
        var textureProvider: NleDefaultLayerTextureProvider? = null
        val decoderPool = NleVideoDecoderPool()

        val audioError = AtomicReference<Throwable?>(null)
        val audioThread = if (hasAudio) {
            Thread {
                try {
                    val audioTrackExporter = com.nle.editor.audio.NleAudioTrackExporter()
                    audioTrackExporter.exportAudio(
                        graph = graph,
                        useOriginalForExport = true,
                        onOutputFormat = { format ->
                            muxerCoordinator.addAudioFormat(format)
                        },
                        onEncodedSample = { buffer, info ->
                            muxerCoordinator.writeAudioSample(buffer, info)
                        },
                        onProgress = { audioProgress ->
                            val combined = progressCombiner.updateAudio(audioProgress)
                            onProgress((combined * 98).toInt().coerceIn(0, 98))
                        }
                    )
                } catch (e: Throwable) {
                    audioError.set(e)
                }
            }.apply { start() }
        } else {
            null
        }

        try {
            encoder.prepare()

            // 1. Create EGL Core with FLAG_RECORDABLE
            eglCore = NleEglCore(EGL14.EGL_NO_CONTEXT, NleEglCore.FLAG_RECORDABLE)

            // 2. Create EGL window surface on encoder input surface
            eglSurface = NleEglWindowSurface(eglCore, encoder.inputSurface, releaseSurface = false)
            eglSurface.makeCurrent()

            // 3. Create Compositor and Provider
            val videoTextureSource = NleDecoderPoolVideoTextureSource(graph, decoderPool)
            textureProvider = NleDefaultLayerTextureProvider(videoTextureSource, outW, outH)
            val activeCompositor = NleMultilayerCompositor(textureProvider)
            compositor = activeCompositor

            val root = JSONObject(renderGraphJson)
            val requestedColorPipeline = NleColorPipelineParser.parse(root)
            val capabilityScanner = NleDeviceColorCapabilityScanner(NleContextHolder.context!!)
            val capability = capabilityScanner.scan()
            val colorFallbackResolver = NleColorPipelineFallbackResolver()
            val resolvedColorPipeline = colorFallbackResolver.resolve(
                requested = requestedColorPipeline,
                capability = capability,
                forExport = true,
            )

            activeCompositor.prepareColorPipeline(
                width = outW,
                height = outH,
                mode = NleGpuPipelineMode.EXPORT,
                requestedQuality = resolvedColorPipeline.quality,
                deviceCapability = capability,
            )

            var frameIndex = 0

            for (f in 0 until totalFrames) {
                if (cancelled.get()) break
                audioError.get()?.let { throw it }

                val timelineTimeUs = f * frameDurationUs

                // Render frame
                activeCompositor.renderFrame(
                    graph = graph,
                    timelineTimeUs = timelineTimeUs,
                    outputWidth = outW,
                    outputHeight = outH,
                    resolvedColorPipeline = resolvedColorPipeline,
                )

                // Set presentation time on encoder surface
                val presentationTimeNanos = timelineTimeUs * 1000L
                eglSurface.setPresentationTime(presentationTimeNanos)
                eglSurface.swapBuffers()

                // Drain encoded data to muxer
                encoder.drain(endOfStream = false)

                frameIndex++
                val videoProgress = frameIndex.toFloat() / totalFrames
                val combined = progressCombiner.updateVideo(videoProgress.toDouble())
                onProgress((combined * 98).toInt().coerceIn(0, 98))
            }

            if (!cancelled.get()) {
                encoder.drain(endOfStream = true)
                audioThread?.join()
                audioError.get()?.let { throw it }
                onProgress(100)
            }
        } catch (e: Exception) {
            if (cancelled.get()) {
                throw InterruptedException("Export cancelled")
            }
            // Propagate exception with appropriate code
            val errorMsg = e.message ?: ""
            if (errorMsg.startsWith("android_")) {
                throw e
            } else {
                throw RuntimeException("${NleNativeErrorCode.EXPORT_RENDER_FAILED}: ${e.localizedMessage}", e)
            }
        } finally {
            try { compositor?.release() } catch (_: Throwable) {}
            try { textureProvider?.release() } catch (_: Throwable) {}
            try { eglSurface?.release() } catch (_: Throwable) {}
            try { eglCore?.release() } catch (_: Throwable) {}
            try { decoderPool.releaseAll() } catch (_: Throwable) {}
            try { encoder.release() } catch (_: Throwable) {}
            try { muxerCoordinator.release() } catch (_: Throwable) {}
            try { audioThread?.interrupt(); audioThread?.join(1000) } catch (_: Throwable) {}

            if (cancelled.get()) {
                try { File(outputPath).takeIf { it.exists() }?.delete() } catch (_: Throwable) {}
            }
        }
    }
}
