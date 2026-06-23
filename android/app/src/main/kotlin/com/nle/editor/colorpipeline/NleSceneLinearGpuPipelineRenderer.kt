package com.nle.editor.colorpipeline

import com.nle.editor.color.NleColorPipelineQuality
import com.nle.editor.color.NleDeviceColorCapability
import com.nle.editor.color.NleResolvedColorPipeline
import com.nle.editor.lut.NleGpuLutCache
import com.nle.editor.lut.NleGpuLutPass
import com.nle.editor.lut.NleLutStack
import com.nle.editor.grade.NlePrimaryGrade
import com.nle.editor.grade.NlePrimaryGradePass
import com.nle.editor.grade.NleSecondaryGradeStack
import com.nle.editor.grade.NleSecondaryGradePass
import com.nle.editor.curves.NleColorCurveStack
import com.nle.editor.curves.NleColorCurvesPass

class NleSceneLinearGpuPipelineRenderer(
    private val colorManagementGlsl: String,
    private val formatResolver: NleGpuRenderFormatResolver = NleGpuRenderFormatResolver(),
) {
    private var config: NleColorPipelineResolvedConfig? = null
    private var targets: NlePingPongRenderTargets? = null

    private val passChain = NleColorPassChain()

    private val inputToLinearPass by lazy {
        NleInputToSceneLinearPass(colorManagementGlsl)
    }

    private val outputTransformPass by lazy {
        NleOutputDisplayTransformPass(colorManagementGlsl)
    }

    private val finalPass by lazy {
        NleSurfaceOutputPass(colorManagementGlsl)
    }

    private var prepared = false

    // 30C-PRO: LUT Cache and Pass Management
    private val lutGlsl by lazy {
        com.kata.videoeditor.nle.NleContextHolder.loadLutGlsl()
    }
    private val lutCache = NleGpuLutCache()
    private val activePassesCache = HashMap<String, NleGpuLutPass>()
    private val activeLutPasses = mutableListOf<NleGpuLutPass>()

    private val primaryGradeGlsl by lazy {
        com.kata.videoeditor.nle.NleContextHolder.loadPrimaryGradeGlsl()
    }
    private var activePrimaryGradePass: NlePrimaryGradePass? = null

    private val colorCurvesGlsl by lazy {
        com.kata.videoeditor.nle.NleContextHolder.loadColorCurvesGlsl()
    }
    private var activeColorCurvesPass: NleColorCurvesPass? = null

    private val secondaryGradeGlsl by lazy {
        com.kata.videoeditor.nle.NleContextHolder.loadSecondaryGradeGlsl()
    }
    private val activeSecondaryGradePasses = mutableListOf<NleSecondaryGradePass>()
    private val secondaryGradePassCache = HashMap<String, NleSecondaryGradePass>()

    fun prepare(
        width: Int,
        height: Int,
        mode: NleGpuPipelineMode,
        requestedQuality: NleColorPipelineQuality,
        capability: NleDeviceColorCapability,
    ): NleColorPipelineResolvedConfig {
        release()

        val resolved = formatResolver.resolve(
            requestedQuality = requestedQuality,
            capability = capability,
            width = width,
            height = height,
            mode = mode,
        )

        val pingPong = NlePingPongRenderTargets(formatResolver)
        pingPong.create(resolved)

        targets = pingPong
        config = resolved

        inputToLinearPass.prepare()
        outputTransformPass.prepare()
        finalPass.prepare()

        rebuildPassChain()

        prepared = true

        return resolved
    }

    fun updateActiveLutStack(
        stack: NleLutStack?,
        capability: NleDeviceColorCapability,
    ) {
        activeLutPasses.clear()
        if (stack == null || !stack.hasEnabledLuts) {
            rebuildPassChain()
            return
        }

        for (layer in stack.layers) {
            if (!layer.enabled || layer.intensity <= 0f) continue

            var pass = activePassesCache[layer.id]
            if (pass == null) {
                pass = NleGpuLutPass(
                    layer = layer,
                    capability = capability,
                    lutCache = lutCache,
                    lutGlsl = lutGlsl,
                )
                pass.prepare()
                activePassesCache[layer.id] = pass
            }
            activeLutPasses.add(pass)
        }

        rebuildPassChain()
    }

    fun updateActivePrimaryGrade(grade: NlePrimaryGrade?) {
        activePrimaryGradePass?.release()
        activePrimaryGradePass = null

        if (grade != null && grade.enabled && grade.intensity > 0f) {
            val pass = NlePrimaryGradePass(
                grade = grade,
                primaryGradeGlsl = primaryGradeGlsl,
            )
            pass.prepare()
            activePrimaryGradePass = pass
        }

        rebuildPassChain()
    }

    fun updateActiveColorCurves(stack: NleColorCurveStack?) {
        activeColorCurvesPass?.release()
        activeColorCurvesPass = null

        if (stack != null && stack.enabled && !stack.isIdentity) {
            val pass = NleColorCurvesPass(
                stack = stack,
                colorCurvesGlsl = colorCurvesGlsl,
            )
            pass.prepare()
            activeColorCurvesPass = pass
        }

        rebuildPassChain()
    }

    fun updateActiveSecondaryGrades(stack: NleSecondaryGradeStack?) {
        val nextIds = stack?.layers?.filter { it.enabled && !it.isIdentity() }?.map { it.id }?.toSet() ?: emptySet()
        val iterator = secondaryGradePassCache.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (!nextIds.contains(entry.key)) {
                entry.value.release()
                iterator.remove()
            }
        }

        activeSecondaryGradePasses.clear()
        if (stack == null || !stack.enabled || stack.layers.isEmpty()) {
            rebuildPassChain()
            return
        }

        for (layer in stack.layers) {
            if (!layer.enabled || layer.isIdentity()) continue

            var pass = secondaryGradePassCache[layer.id]
            if (pass == null) {
                pass = NleSecondaryGradePass(
                    layer = layer,
                    secondaryGradeGlsl = secondaryGradeGlsl,
                )
                pass.prepare()
                secondaryGradePassCache[layer.id] = pass
            } else {
                pass.updateLayer(layer)
            }
            activeSecondaryGradePasses.add(pass)
        }

        rebuildPassChain()
    }

    private fun rebuildPassChain() {
        val passes = mutableListOf<NleColorPass>()
        passes.add(inputToLinearPass)
        activePrimaryGradePass?.let { passes.add(it) }
        activeColorCurvesPass?.let { passes.add(it) }
        passes.addAll(activeSecondaryGradePasses)
        passes.addAll(activeLutPasses)
        passes.add(outputTransformPass)
        passChain.setPassesDirectly(passes)
    }

    var lastDisplayReferredTextureId: Int = 0
        private set

    fun getLastSceneLinearTextureId(): Int {
        return passChain.lastSceneLinearTextureId
    }

    fun renderToTexture(
        inputTextureId: Int,
        pipeline: NleResolvedColorPipeline,
    ): Int {
        check(prepared) {
            "NleSceneLinearGpuPipelineRenderer.prepare() must be called before render."
        }

        val pingPong = requireNotNull(targets)
        pingPong.resetSourceToA()

        val outputTexture = passChain.render(
            initialTextureId = inputTextureId,
            targets = pingPong,
            pipeline = pipeline,
        )
        lastDisplayReferredTextureId = outputTexture
        return outputTexture
    }

    fun renderToCurrentSurface(
        inputTextureId: Int,
        pipeline: NleResolvedColorPipeline,
        surfaceWidth: Int,
        surfaceHeight: Int,
    ): NleColorPipelineStats {
        val finalTexture = renderToTexture(
            inputTextureId = inputTextureId,
            pipeline = pipeline,
        )

        finalPass.renderToCurrentSurface(
            inputTextureId = finalTexture,
            surfaceWidth = surfaceWidth,
            surfaceHeight = surfaceHeight,
        )

        val cfg = requireNotNull(config)

        return NleColorPipelineStats(
            passCount = passChain.passCount,
            format = cfg.workingFormat,
            precision = cfg.precision,
            width = cfg.width,
            height = cfg.height,
            usedFallback = cfg.fallbackReason != null,
            fallbackReason = cfg.fallbackReason,
        )
    }

    fun release() {
        passChain.release()
        inputToLinearPass.release()
        outputTransformPass.release()
        finalPass.release()

        for (pass in activePassesCache.values) {
            pass.release()
        }
        activePassesCache.clear()
        activeLutPasses.clear()
        lutCache.releaseAll()

        for (pass in secondaryGradePassCache.values) {
            pass.release()
        }
        secondaryGradePassCache.clear()
        activeSecondaryGradePasses.clear()

        activePrimaryGradePass?.release()
        activePrimaryGradePass = null

        activeColorCurvesPass?.release()
        activeColorCurvesPass = null

        targets?.release()
        targets = null
        config = null
        prepared = false
        lastDisplayReferredTextureId = 0
    }
}
