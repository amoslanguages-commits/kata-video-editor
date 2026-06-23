package com.nle.editor.hdr

enum class NleOutputColorMode {
    rec709Sdr,
    srgbSdr,
    displayP3Sdr,
    rec2020Sdr,
    rec2020HlgHdr,
    rec2020PqHdr
}

enum class NleHdrTransferFunction {
    sdr,
    hlg,
    pq
}

enum class NleHdrMetadataMode {
    none,
    hdr10Static,
    auto
}

enum class NleToneMapOperator {
    none,
    reinhard,
    acesApprox,
    hable,
    mobileFilmSafe
}

enum class NleColorRangeMode {
    auto,
    full,
    limited
}

enum class NleOutputBitDepth {
    eightBit,
    tenBit
}

enum class NleWideColorPreviewMode {
    auto,
    forceSdrPreview,
    wideColorPreview,
    hdrPreview
}

data class NleHdrMasteringDisplayMetadata(
    val maxDisplayMasteringLuminance: Double = 1000.0,
    val minDisplayMasteringLuminance: Double = 0.005,
    val maxContentLightLevel: Double = 1000.0,
    val maxFrameAverageLightLevel: Double = 400.0,
    val primaryRedX: Double = 0.708,
    val primaryRedY: Double = 0.292,
    val primaryGreenX: Double = 0.170,
    val primaryGreenY: Double = 0.797,
    val primaryBlueX: Double = 0.131,
    val primaryBlueY: Double = 0.046,
    val whitePointX: Double = 0.3127,
    val whitePointY: Double = 0.3290
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "maxDisplayMasteringLuminance" to maxDisplayMasteringLuminance,
            "minDisplayMasteringLuminance" to minDisplayMasteringLuminance,
            "maxContentLightLevel" to maxContentLightLevel,
            "maxFrameAverageLightLevel" to maxFrameAverageLightLevel,
            "primaryRedX" to primaryRedX,
            "primaryRedY" to primaryRedY,
            "primaryGreenX" to primaryGreenX,
            "primaryGreenY" to primaryGreenY,
            "primaryBlueX" to primaryBlueX,
            "primaryBlueY" to primaryBlueY,
            "whitePointX" to whitePointX,
            "whitePointY" to whitePointY
        )
    }
}

data class NleHdrOutputSettings(
    val colorMode: NleOutputColorMode = NleOutputColorMode.rec709Sdr,
    val transferFunction: NleHdrTransferFunction = NleHdrTransferFunction.sdr,
    val toneMapOperator: NleToneMapOperator = NleToneMapOperator.none,
    val metadataMode: NleHdrMetadataMode = NleHdrMetadataMode.none,
    val colorRange: NleColorRangeMode = NleColorRangeMode.auto,
    val bitDepth: NleOutputBitDepth = NleOutputBitDepth.eightBit,
    val previewMode: NleWideColorPreviewMode = NleWideColorPreviewMode.auto,
    val targetPeakNits: Double = 1000.0,
    val masteringMetadata: NleHdrMasteringDisplayMetadata = NleHdrMasteringDisplayMetadata()
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "colorMode" to colorMode.name,
            "transferFunction" to transferFunction.name,
            "toneMapOperator" to toneMapOperator.name,
            "metadataMode" to metadataMode.name,
            "colorRange" to colorRange.name,
            "bitDepth" to bitDepth.name,
            "previewMode" to previewMode.name,
            "targetPeakNits" to targetPeakNits,
            "masteringMetadata" to masteringMetadata.toMap()
        )
    }
}

data class NleHdrDeviceCapability(
    val displaySupportsHdr: Boolean,
    val displaySupportsWideColor: Boolean,
    val displayMaxNits: Double,
    val encoderSupportsHdrHlg: Boolean,
    val encoderSupportsHdrPq: Boolean,
    val encoderSupportsWideColorP3: Boolean,
    val encoderSupportsTenBit: Boolean
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "displaySupportsHdr" to displaySupportsHdr,
            "displaySupportsWideColor" to displaySupportsWideColor,
            "displayMaxNits" to displayMaxNits,
            "encoderSupportsHdrHlg" to encoderSupportsHdrHlg,
            "encoderSupportsHdrPq" to encoderSupportsHdrPq,
            "encoderSupportsWideColorP3" to encoderSupportsWideColorP3,
            "encoderSupportsTenBit" to encoderSupportsTenBit
        )
    }
}

data class NleHdrExportValidation(
    val isHdrSafe: Boolean,
    val warnings: List<String>,
    val errors: List<String>,
    val suggestedColorMode: NleOutputColorMode,
    val suggestedBitDepth: NleOutputBitDepth,
    val suggestedTransferFunction: NleHdrTransferFunction
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "isHdrSafe" to isHdrSafe,
            "warnings" to warnings,
            "errors" to errors,
            "suggestedColorMode" to suggestedColorMode.name,
            "suggestedBitDepth" to suggestedBitDepth.name,
            "suggestedTransferFunction" to suggestedTransferFunction.name
        )
    }
}
