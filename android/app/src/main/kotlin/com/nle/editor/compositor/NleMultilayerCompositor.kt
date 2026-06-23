package com.nle.editor.compositor

import android.graphics.Color
import android.opengl.GLES20
import android.util.Log
import com.nle.editor.rendergraph.NleRenderGraph
import com.nle.editor.rendergraph.NleResolvedVisualLayer
import com.nle.editor.rendergraph.NleVisualLayerResolver
import com.nle.editor.color.*
import com.nle.editor.colorpipeline.*
import com.kata.videoeditor.nle.NleContextHolder
import com.nle.editor.scopes.NleScopeManager
import com.nle.editor.scopes.NleScopeColorSpace
import com.nle.editor.scopes.NleScopeDownsampler


class NleMultilayerCompositor(
    private val textureProvider: NleLayerTextureProvider,
    val scopeManager: NleScopeManager? = null,
    val monitorId: String = ""
) {
    private val resolver = NleVisualLayerResolver()
    private val cropFitResolver = NleCropFitResolver()
    private val matrixBuilder = NleLayerMatrixBuilder()

    private val program2d = NleGlLayerProgram(externalOes = false)
    private val programOes = NleGlLayerProgram(externalOes = true)

    private val sceneLinearPipeline by lazy {
        val glsl = NleContextHolder.loadColorManagementGlsl()
        NleSceneLinearGpuPipelineRenderer(glsl)
    }

    private var resolvedPipelineConfig: NleColorPipelineResolvedConfig? = null
    private var intermediateFbo: NleGpuFramebuffer? = null
    private var capability: NleDeviceColorCapability? = null
    private var scopeDownsampler: NleScopeDownsampler? = null

    fun prepareColorPipeline(
        width: Int,
        height: Int,
        mode: NleGpuPipelineMode,
        requestedQuality: NleColorPipelineQuality,
        deviceCapability: NleDeviceColorCapability,
    ) {
        capability = deviceCapability
        val config = sceneLinearPipeline.prepare(
            width = width,
            height = height,
            mode = mode,
            requestedQuality = requestedQuality,
            capability = deviceCapability,
        )
        resolvedPipelineConfig = config

        intermediateFbo?.texture?.release()
        intermediateFbo?.release()

        val formatResolver = NleGpuRenderFormatResolver()
        val info = formatResolver.formatInfo(config.workingFormat)
        val texture = NleGpuFloatTexture(
            width = config.width,
            height = config.height,
            info = info,
        )
        val fbo = NleGpuFramebuffer(texture)
        fbo.create()
        intermediateFbo = fbo
    }

    fun renderFrame(
        graph: NleRenderGraph,
        timelineTimeUs: Long,
        outputWidth: Int,
        outputHeight: Int,
        resolvedColorPipeline: NleResolvedColorPipeline? = null,
    ): NleColorPipelineStats? {
        val layers = resolver.resolve(
            graph = graph,
            timelineTimeUs = timelineTimeUs,
        )

        val fbo = intermediateFbo
        val config = resolvedPipelineConfig
        val usePipeline = fbo != null && config != null && resolvedColorPipeline != null && resolvedColorPipeline.enabled

        if (usePipeline) {
            fbo!!.bind()
            val activeLutStack = layers
                .map { it.clip }
                .firstOrNull { it.lutStack?.hasEnabledLuts == true }
                ?.lutStack

            val activePrimaryGrade = layers
                .map { it.clip }
                .firstOrNull { it.primaryGrade.enabled }
                ?.primaryGrade

            val activeColorCurves = layers
                .map { it.clip }
                .firstOrNull { it.colorCurveStack?.enabled == true && !it.colorCurveStack.isIdentity }
                ?.colorCurveStack

            val activeSecondaryGradeStack = layers
                .map { it.clip }
                .firstOrNull { it.secondaryGrades?.enabled == true && !it.secondaryGrades.isIdentity() }
                ?.secondaryGrades

            capability?.let { cap ->
                sceneLinearPipeline.updateActiveLutStack(activeLutStack, cap)
                sceneLinearPipeline.updateActivePrimaryGrade(activePrimaryGrade)
                sceneLinearPipeline.updateActiveColorCurves(activeColorCurves)
                sceneLinearPipeline.updateActiveSecondaryGrades(activeSecondaryGradeStack)
            }
        } else {
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
            GLES20.glViewport(0, 0, outputWidth, outputHeight)
        }

        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(
            GLES20.GL_SRC_ALPHA,
            GLES20.GL_ONE_MINUS_SRC_ALPHA,
        )

        clearBackground(graph.project.backgroundColor)

        if (layers.isEmpty()) {
            Log.w("NlePreview", "compositor no visual layers timeUs=$timelineTimeUs tracks=${graph.tracks.size}")
        }

        val renderWidth = if (usePipeline) config!!.width else outputWidth
        val renderHeight = if (usePipeline) config!!.height else outputHeight

        for (layer in layers) {
            renderLayer(
                layer = layer,
                outputWidth = renderWidth,
                outputHeight = renderHeight,
            )
        }

        GLES20.glDisable(GLES20.GL_BLEND)

        if (usePipeline) {
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
            val stats = sceneLinearPipeline.renderToCurrentSurface(
                inputTextureId = fbo.textureId,
                pipeline = resolvedColorPipeline!!,
                surfaceWidth = outputWidth,
                surfaceHeight = outputHeight,
            )

            // 30G-PRO: Downsample and compute scopes if active
            val manager = scopeManager
            if (manager != null && manager.shouldProcess(monitorId, timelineTimeUs)) {
                val sampleW = manager.sampleWidth
                val sampleH = manager.sampleHeight
                val targetTex = if (manager.colorSpace == NleScopeColorSpace.SCENE_LINEAR) {
                    sceneLinearPipeline.getLastSceneLinearTextureId()
                } else {
                    sceneLinearPipeline.lastDisplayReferredTextureId
                }

                if (targetTex != 0) {
                    val downsampler = getOrCreateDownsampler()
                    downsampler.prepare(sampleW, sampleH)
                    val rgbaBuffer = downsampler.downsample(targetTex)
                    if (rgbaBuffer != null) {
                        val bytes = ByteArray(rgbaBuffer.remaining())
                        rgbaBuffer.get(bytes)
                        rgbaBuffer.rewind()

                        manager.processFrame(
                            monitorId = monitorId,
                            rgbaBytes = bytes,
                            width = sampleW,
                            height = sampleH,
                            timestampMicros = timelineTimeUs
                        )
                    }
                }
            }

            return stats
        }

        return null
    }

    private fun getOrCreateDownsampler(): NleScopeDownsampler {
        var d = scopeDownsampler
        if (d == null) {
            d = NleScopeDownsampler()
            scopeDownsampler = d
        }
        return d
    }

    private fun renderLayer(
        layer: NleResolvedVisualLayer,
        outputWidth: Int,
        outputHeight: Int,
    ) {
        val texture = textureForLayer(layer)
        if (texture == null) {
            Log.w(
                "NlePreview",
                "compositor missing texture clip=${layer.clip.id} type=${layer.clip.type} asset=${layer.clip.assetId} sourceUs=${layer.sourceTimeUs}"
            )
            return
        }

        val crop = cropFitResolver.resolveCrop(layer.clip)
        val fitScale = cropFitResolver.resolveFitScale(
            clip = layer.clip,
            asset = layer.asset,
            outputWidth = outputWidth,
            outputHeight = outputHeight,
        )

        val mvp = matrixBuilder.buildMvpMatrix(
            layer = layer,
            fitScale = fitScale,
        )

        val program = if (texture.isExternalOes) {
            programOes
        } else {
            program2d
        }

        program.draw(
            texture = texture,
            mvpMatrix = mvp,
            texCoords = crop.textureCoords(),
            opacity = layer.clip.transform.opacity.toFloat(),
            brightness = layer.clip.color.brightness.toFloat(),
            contrast = layer.clip.color.contrast.toFloat(),
            saturation = layer.clip.color.saturation.toFloat(),
        )

        texture.releaseIfOwned()
    }

    private fun textureForLayer(
        layer: NleResolvedVisualLayer,
    ): NleLayerTexture? {
        return when (layer.clip.type.lowercase()) {
            "video" -> textureProvider.textureForVideoLayer(layer)
            "image" -> textureProvider.textureForImageLayer(layer)
            "text" -> textureProvider.textureForTextLayer(layer)
            else -> null
        }
    }

    private fun clearBackground(hex: String) {
        val color = try {
            Color.parseColor(hex)
        } catch (_: Throwable) {
            Color.BLACK
        }

        GLES20.glClearColor(
            Color.red(color) / 255f,
            Color.green(color) / 255f,
            Color.blue(color) / 255f,
            1f,
        )

        GLES20.glClear(
            GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT,
        )
    }

    fun release() {
        program2d.release()
        programOes.release()
        sceneLinearPipeline.release()
        intermediateFbo?.texture?.release()
        intermediateFbo?.release()
        intermediateFbo = null
        resolvedPipelineConfig = null
        scopeDownsampler?.release()
        scopeDownsampler = null
    }
}
