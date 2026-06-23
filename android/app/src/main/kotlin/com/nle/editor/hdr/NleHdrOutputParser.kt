package com.nle.editor.hdr

object NleHdrOutputParser {
    @Suppress("UNCHECKED_CAST")
    fun parseSettings(map: Map<String, Any?>): NleHdrOutputSettings {
        val colorModeStr = map["colorMode"] as? String
        val colorMode = NleOutputColorMode.values().firstOrNull { it.name == colorModeStr }
            ?: NleOutputColorMode.rec709Sdr

        val tfStr = map["transferFunction"] as? String
        val transferFunction = NleHdrTransferFunction.values().firstOrNull { it.name == tfStr }
            ?: NleHdrTransferFunction.sdr

        val tmoStr = map["toneMapOperator"] as? String
        val toneMapOperator = NleToneMapOperator.values().firstOrNull { it.name == tmoStr }
            ?: NleToneMapOperator.none

        val metadataModeStr = map["metadataMode"] as? String
        val metadataMode = NleHdrMetadataMode.values().firstOrNull { it.name == metadataModeStr }
            ?: NleHdrMetadataMode.none

        val rangeStr = map["colorRange"] as? String
        val colorRange = NleColorRangeMode.values().firstOrNull { it.name == rangeStr }
            ?: NleColorRangeMode.auto

        val bitDepthStr = map["bitDepth"] as? String
        val bitDepth = NleOutputBitDepth.values().firstOrNull { it.name == bitDepthStr }
            ?: NleOutputBitDepth.eightBit

        val previewModeStr = map["previewMode"] as? String
        val previewMode = NleWideColorPreviewMode.values().firstOrNull { it.name == previewModeStr }
            ?: NleWideColorPreviewMode.auto

        val targetPeakNits = when (val peak = map["targetPeakNits"]) {
            is Double -> peak
            is Float -> peak.toDouble()
            is Number -> peak.toDouble()
            else -> 1000.0
        }

        val masteringMap = map["masteringMetadata"] as? Map<String, Any?>
        val masteringMetadata = if (masteringMap != null) {
            parseMasteringMetadata(masteringMap)
        } else {
            NleHdrMasteringDisplayMetadata()
        }

        return NleHdrOutputSettings(
            colorMode = colorMode,
            transferFunction = transferFunction,
            toneMapOperator = toneMapOperator,
            metadataMode = metadataMode,
            colorRange = colorRange,
            bitDepth = bitDepth,
            previewMode = previewMode,
            targetPeakNits = targetPeakNits,
            masteringMetadata = masteringMetadata
        )
    }

    private fun parseDouble(value: Any?, default: Double): Double {
        return when (value) {
            is Double -> value
            is Float -> value.toDouble()
            is Number -> value.toDouble()
            is String -> value.toDoubleOrNull() ?: default
            else -> default
        }
    }

    private fun parseMasteringMetadata(map: Map<String, Any?>): NleHdrMasteringDisplayMetadata {
        return NleHdrMasteringDisplayMetadata(
            maxDisplayMasteringLuminance = parseDouble(map["maxDisplayMasteringLuminance"], 1000.0),
            minDisplayMasteringLuminance = parseDouble(map["minDisplayMasteringLuminance"], 0.005),
            maxContentLightLevel = parseDouble(map["maxContentLightLevel"], 1000.0),
            maxFrameAverageLightLevel = parseDouble(map["maxFrameAverageLightLevel"], 400.0),
            primaryRedX = parseDouble(map["primaryRedX"], 0.708),
            primaryRedY = parseDouble(map["primaryRedY"], 0.292),
            primaryGreenX = parseDouble(map["primaryGreenX"], 0.170),
            primaryGreenY = parseDouble(map["primaryGreenY"], 0.797),
            primaryBlueX = parseDouble(map["primaryBlueX"], 0.131),
            primaryBlueY = parseDouble(map["primaryBlueY"], 0.046),
            whitePointX = parseDouble(map["whitePointX"], 0.3127),
            whitePointY = parseDouble(map["whitePointY"], 0.3290)
        )
    }
}
