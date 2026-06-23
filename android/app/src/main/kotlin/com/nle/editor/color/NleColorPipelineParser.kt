package com.nle.editor.color

import org.json.JSONObject

object NleColorPipelineParser {

    fun parse(root: JSONObject): NleColorManagementPipeline {
        val json = root.optJSONObject("colorPipeline")
            ?: return defaultPipeline()

        val defaultInput = parseInput(json.optJSONObject("defaultInput"))
        val working = parseWorking(json.optJSONObject("working"))
        val previewOutput = parseOutput(json.optJSONObject("previewOutput"))
        val exportOutput = parseOutput(json.optJSONObject("exportOutput"))

        val assetInputs = mutableMapOf<String, NleInputColorTransform>()
        val assetJson = json.optJSONObject("assetInputTransforms")
        if (assetJson != null) {
            val keys = assetJson.keys()
            while (keys.hasNext()) {
                val assetId = keys.next()
                assetInputs[assetId] = parseInput(assetJson.optJSONObject(assetId))
            }
        }

        return NleColorManagementPipeline(
            enabled = json.optBoolean("enabled", true),
            quality = NleColorPipelineQuality.parse(json.optString("quality")),
            defaultInput = defaultInput,
            working = working,
            previewOutput = previewOutput,
            exportOutput = exportOutput,
            forceCompatibilityMode = json.optBoolean("forceCompatibilityMode", false),
            previewMatchesExport = json.optBoolean("previewMatchesExport", true),
            assetInputTransforms = assetInputs,
        )
    }

    private fun parseInput(json: JSONObject?): NleInputColorTransform {
        if (json == null) {
            return NleInputColorTransform(
                colorSpace = NleColorSpace.AUTO,
                transferCurve = NleTransferCurve.AUTO,
                fullRange = true,
                exposureBias = 0f,
                inputBlackLevel = 0f,
                inputWhiteLevel = 1f,
            )
        }
        return NleInputColorTransform(
            colorSpace = NleColorSpace.parse(json.optString("colorSpace")),
            transferCurve = NleTransferCurve.parse(json.optString("transferCurve")),
            fullRange = json.optBoolean("fullRange", true),
            exposureBias = json.optDouble("exposureBias", 0.0).toFloat(),
            inputBlackLevel = json.optDouble("inputBlackLevel", 0.0).toFloat(),
            inputWhiteLevel = json.optDouble("inputWhiteLevel", 1.0).toFloat(),
        )
    }

    private fun parseWorking(json: JSONObject?): NleWorkingColorTransform {
        if (json == null) {
            return NleWorkingColorTransform(
                workingSpace = NleWorkingColorSpace.LINEAR_REC709,
                sceneLinear = true,
                clampNegative = true,
                allowSuperWhites = true,
            )
        }
        return NleWorkingColorTransform(
            workingSpace = NleWorkingColorSpace.parse(json.optString("workingSpace")),
            sceneLinear = json.optBoolean("sceneLinear", true),
            clampNegative = json.optBoolean("clampNegative", true),
            allowSuperWhites = json.optBoolean("allowSuperWhites", true),
        )
    }

    private fun parseOutput(json: JSONObject?): NleOutputColorTransform {
        if (json == null) {
            return NleOutputColorTransform(
                colorSpace = NleOutputColorSpace.REC709,
                transferCurve = NleOutputTransferCurve.REC709,
                toneMapMode = NleToneMapMode.NONE,
                outputBlackLevel = 0f,
                outputWhiteLevel = 1f,
                dither = true,
                legalRange = false,
            )
        }
        return NleOutputColorTransform(
            colorSpace = NleOutputColorSpace.parse(json.optString("colorSpace")),
            transferCurve = NleOutputTransferCurve.parse(json.optString("transferCurve")),
            toneMapMode = NleToneMapMode.parse(json.optString("toneMapMode")),
            outputBlackLevel = json.optDouble("outputBlackLevel", 0.0).toFloat(),
            outputWhiteLevel = json.optDouble("outputWhiteLevel", 1.0).toFloat(),
            dither = json.optBoolean("dither", true),
            legalRange = json.optBoolean("legalRange", false),
        )
    }

    private fun defaultPipeline(): NleColorManagementPipeline {
        val input = NleInputColorTransform(
            colorSpace = NleColorSpace.AUTO,
            transferCurve = NleTransferCurve.AUTO,
            fullRange = true,
            exposureBias = 0f,
            inputBlackLevel = 0f,
            inputWhiteLevel = 1f,
        )
        val output = NleOutputColorTransform(
            colorSpace = NleOutputColorSpace.REC709,
            transferCurve = NleOutputTransferCurve.REC709,
            toneMapMode = NleToneMapMode.NONE,
            outputBlackLevel = 0f,
            outputWhiteLevel = 1f,
            dither = true,
            legalRange = false,
        )
        return NleColorManagementPipeline(
            enabled = true,
            quality = NleColorPipelineQuality.AUTO,
            defaultInput = input,
            working = NleWorkingColorTransform(
                workingSpace = NleWorkingColorSpace.LINEAR_REC709,
                sceneLinear = true,
                clampNegative = true,
                allowSuperWhites = true,
            ),
            previewOutput = output,
            exportOutput = output,
            forceCompatibilityMode = false,
            previewMatchesExport = true,
            assetInputTransforms = emptyMap(),
        )
    }
}
