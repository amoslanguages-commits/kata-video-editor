package com.nle.editor.color

class NleColorPipelineFallbackResolver {

    fun resolve(
        requested: NleColorManagementPipeline,
        capability: NleDeviceColorCapability,
        forExport: Boolean,
    ): NleResolvedColorPipeline {
        if (!requested.enabled) {
            return NleResolvedColorPipeline.disabled()
        }

        val quality = when {
            requested.forceCompatibilityMode ->
                NleColorPipelineQuality.COMPATIBILITY_8BIT

            requested.quality != NleColorPipelineQuality.AUTO ->
                requested.quality

            else -> capability.recommendedQuality
        }

        val safeQuality = when (quality) {
            NleColorPipelineQuality.HIGH_PRECISION_32F -> when {
                capability.supportsFloatRenderTarget -> NleColorPipelineQuality.HIGH_PRECISION_32F
                capability.supportsHalfFloatRenderTarget -> NleColorPipelineQuality.STANDARD_16F
                else -> NleColorPipelineQuality.COMPATIBILITY_8BIT
            }
            NleColorPipelineQuality.STANDARD_16F -> when {
                capability.supportsHalfFloatRenderTarget -> NleColorPipelineQuality.STANDARD_16F
                else -> NleColorPipelineQuality.COMPATIBILITY_8BIT
            }
            NleColorPipelineQuality.COMPATIBILITY_8BIT -> NleColorPipelineQuality.COMPATIBILITY_8BIT
            NleColorPipelineQuality.AUTO -> capability.recommendedQuality
        }

        val requestedOutput = if (forExport) requested.exportOutput else requested.previewOutput

        val safeOutput = if (
            requestedOutput.transferCurve == NleOutputTransferCurve.HLG ||
            requestedOutput.transferCurve == NleOutputTransferCurve.PQ
        ) {
            val hdrAllowed = if (forExport) {
                capability.supportsHdrExport
            } else {
                capability.supportsHdrPreview
            }
            if (hdrAllowed) requestedOutput else requestedOutput.sdrFallback()
        } else {
            requestedOutput
        }

        return NleResolvedColorPipeline(
            enabled = true,
            quality = safeQuality,
            defaultInput = requested.defaultInput,
            working = requested.working,
            output = safeOutput,
            assetInputTransforms = requested.assetInputTransforms,
        )
    }
}

data class NleResolvedColorPipeline(
    val enabled: Boolean,
    val quality: NleColorPipelineQuality,
    val defaultInput: NleInputColorTransform,
    val working: NleWorkingColorTransform,
    val output: NleOutputColorTransform,
    val assetInputTransforms: Map<String, NleInputColorTransform>,
) {
    companion object {
        fun disabled(): NleResolvedColorPipeline {
            val input = NleInputColorTransform(
                colorSpace = NleColorSpace.REC709,
                transferCurve = NleTransferCurve.REC709,
                fullRange = true,
                exposureBias = 0f,
                inputBlackLevel = 0f,
                inputWhiteLevel = 1f,
            )
            return NleResolvedColorPipeline(
                enabled = false,
                quality = NleColorPipelineQuality.COMPATIBILITY_8BIT,
                defaultInput = input,
                working = NleWorkingColorTransform(
                    workingSpace = NleWorkingColorSpace.LINEAR_REC709,
                    sceneLinear = false,
                    clampNegative = true,
                    allowSuperWhites = false,
                ),
                output = NleOutputColorTransform(
                    colorSpace = NleOutputColorSpace.REC709,
                    transferCurve = NleOutputTransferCurve.REC709,
                    toneMapMode = NleToneMapMode.NONE,
                    outputBlackLevel = 0f,
                    outputWhiteLevel = 1f,
                    dither = false,
                    legalRange = false,
                ),
                assetInputTransforms = emptyMap(),
            )
        }
    }

    fun inputForAsset(assetId: String?): NleInputColorTransform {
        if (assetId == null) return defaultInput
        return assetInputTransforms[assetId] ?: defaultInput
    }
}

private fun NleOutputColorTransform.sdrFallback(): NleOutputColorTransform {
    return copy(
        colorSpace = NleOutputColorSpace.REC709,
        transferCurve = NleOutputTransferCurve.REC709,
        toneMapMode = NleToneMapMode.ACES_APPROX,
        outputBlackLevel = 0f,
        outputWhiteLevel = 1f,
        dither = true,
        legalRange = false,
    )
}
