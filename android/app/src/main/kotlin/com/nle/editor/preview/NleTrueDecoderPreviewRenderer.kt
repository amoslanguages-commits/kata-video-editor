package com.nle.editor.preview

import com.nle.editor.compositor.NleDefaultLayerTextureProvider
import com.nle.editor.compositor.NleMultilayerCompositor
import com.kata.videoeditor.nle.export.NleVideoDecoderPool
import com.nle.editor.rendergraph.NleRenderGraph
import com.nle.editor.rendergraph.NleRenderGraphParser
import io.flutter.view.TextureRegistry
import com.nle.editor.color.*
import com.nle.editor.colorpipeline.*
import com.kata.videoeditor.nle.NleContextHolder
import com.nle.editor.scopes.NleScopeManager
import org.json.JSONObject

class NleTrueDecoderPreviewRenderer(
    textureRegistry: TextureRegistry,
    val monitorId: String
) {
    private val parser = NleRenderGraphParser()
    private val sizeResolver = NlePreviewSizeResolver()
    private val decoderPreparer = NlePreviewDecoderPreparer()

    private val flutterTexture = NleFlutterPreviewTexture(textureRegistry)
    private val eglRenderer = NlePreviewEglRenderer()
    private val decoderPool = NleVideoDecoderPool()

    private var textureProvider: NleDefaultLayerTextureProvider? = null
    private var compositor: NleMultilayerCompositor? = null

    @Volatile
    var scopeManager: NleScopeManager? = null

    @Volatile
    private var graph: NleRenderGraph? = null

    @Volatile
    private var state: NlePreviewState = NlePreviewState.IDLE

    @Volatile
    private var outputSize: NlePreviewOutputSize = NlePreviewOutputSize(720, 1280)

    @Volatile
    var eventSink: NlePreviewEventSink? = null

    private val colorCapabilityScanner by lazy {
        NleDeviceColorCapabilityScanner(NleContextHolder.context!!)
    }
    private val colorFallbackResolver = NleColorPipelineFallbackResolver()

    private var resolvedColorPipeline: NleResolvedColorPipeline? = null
    private var colorCapability: NleDeviceColorCapability? = null

    val textureId: Long
        get() = flutterTexture.textureId

    fun prepareFlutterSurface(config: NlePreviewConfig): Long {
        state = NlePreviewState.PREPARING
        val parsedGraph = parser.parse(config.renderGraphJson)
        graph = parsedGraph

        val root = JSONObject(config.renderGraphJson)
        val requestedColorPipeline = NleColorPipelineParser.parse(root)
        val capability = colorCapability ?: colorCapabilityScanner.scan().also { colorCapability = it }
        resolvedColorPipeline = colorFallbackResolver.resolve(
            requested = requestedColorPipeline,
            capability = capability,
            forExport = false,
        )

        outputSize = sizeResolver.resolve(
            graph = parsedGraph,
            qualityMode = config.qualityMode,
            maxPreviewWidth = config.maxPreviewWidth,
            maxPreviewHeight = config.maxPreviewHeight,
        )

        flutterTexture.createOrResize(width = outputSize.width, height = outputSize.height)
        return textureId
    }

    fun prepareDecoderPipeline(config: NlePreviewConfig) {
        val parsedGraph = graph ?: error("Preview graph must be prepared before the decoder pipeline.")
        val surface = flutterTexture.currentSurface()

        eglRenderer.release()
        eglRenderer.initialize(surface)
        eglRenderer.makeCurrent()
        decoderPool.releaseAll()
        rebuildTextureProviderAndCompositor(parsedGraph, config.preferProxy)
        state = NlePreviewState.READY
    }

    fun updateRenderGraph(renderGraphJson: String, preferProxy: Boolean = true) {
        val parsedGraph = parser.parse(renderGraphJson)
        graph = parsedGraph

        val root = JSONObject(renderGraphJson)
        val requestedColorPipeline = NleColorPipelineParser.parse(root)
        val capability = colorCapability ?: colorCapabilityScanner.scan().also { colorCapability = it }
        val resolved = colorFallbackResolver.resolve(
            requested = requestedColorPipeline,
            capability = capability,
            forExport = false,
        )
        resolvedColorPipeline = resolved

        eglRenderer.makeCurrent()
        // Keep decoderPool warm, but rebuild the texture provider because it owns an immutable asset map.
        rebuildTextureProviderAndCompositor(parsedGraph, preferProxy)
    }

    private fun rebuildTextureProviderAndCompositor(parsedGraph: NleRenderGraph, preferProxy: Boolean) {
        textureProvider?.release()
        textureProvider = NleDefaultLayerTextureProvider(
            videoTextureSource = NlePreviewVideoTextureSource(
                graph = parsedGraph,
                decoderPool = decoderPool,
                preferProxy = preferProxy,
            ),
            outputWidth = outputSize.width,
            outputHeight = outputSize.height,
        )

        compositor?.release()
        compositor = NleMultilayerCompositor(
            textureProvider = textureProvider ?: error("Preview texture provider missing."),
            scopeManager = scopeManager,
            monitorId = monitorId,
        )

        val resolved = resolvedColorPipeline
        val capability = colorCapability
        if (resolved != null && capability != null) {
            compositor?.prepareColorPipeline(
                width = outputSize.width,
                height = outputSize.height,
                mode = NleGpuPipelineMode.PREVIEW,
                requestedQuality = resolved.quality,
                deviceCapability = capability,
            )
        }
    }

    fun renderFrame(timelineTimeUs: Long): NlePreviewFrameResult {
        val currentGraph = graph ?: return NlePreviewFrameResult(
            rendered = false,
            timelineTimeUs = timelineTimeUs,
            dropped = true,
            reason = "RenderGraph not prepared.",
        )
        val activeCompositor = compositor ?: return NlePreviewFrameResult(
            rendered = false,
            timelineTimeUs = timelineTimeUs,
            dropped = true,
            reason = "Compositor not prepared.",
        )

        return try {
            eglRenderer.makeCurrent()
            val stats = activeCompositor.renderFrame(
                graph = currentGraph,
                timelineTimeUs = timelineTimeUs.coerceIn(0L, currentGraph.project.durationUs),
                outputWidth = outputSize.width,
                outputHeight = outputSize.height,
                resolvedColorPipeline = resolvedColorPipeline,
            )
            if (stats != null) {
                eventSink?.onColorPipelineStats(
                    passCount = stats.passCount,
                    format = stats.format.name,
                    precision = stats.precision.name,
                    usedFallback = stats.usedFallback,
                    fallbackReason = stats.fallbackReason,
                )
            }
            eglRenderer.swapBuffers()
            NlePreviewFrameResult(rendered = true, timelineTimeUs = timelineTimeUs)
        } catch (error: Throwable) {
            state = NlePreviewState.ERROR
            NlePreviewFrameResult(
                rendered = false,
                timelineTimeUs = timelineTimeUs,
                dropped = true,
                reason = error.message ?: error.toString(),
            )
        }
    }

    fun setPlaying() { state = NlePreviewState.PLAYING }
    fun setPaused() { state = NlePreviewState.PAUSED }
    fun state(): NlePreviewState = state
    fun outputSize(): NlePreviewOutputSize = outputSize
    fun currentGraph(): NleRenderGraph? = graph

    fun release() {
        state = NlePreviewState.STOPPED
        compositor?.release()
        compositor = null
        textureProvider?.release()
        textureProvider = null
        decoderPool.releaseAll()
        eglRenderer.release()
        flutterTexture.release()
        graph = null
    }
}
