package com.nle.editor.rendergraph

import org.json.JSONArray
import org.json.JSONObject
import com.nle.editor.lut.NleLutStack
import com.nle.editor.lut.NleRenderGraphLutParser
import com.nle.editor.grade.NleRenderGraphSecondaryGradeParser

class NleRenderGraphParser {

    fun parse(jsonString: String): NleRenderGraph {
        val root = JSONObject(jsonString)

        val schema = root.optString("schema", "nle.render_graph")
        val version = root.optInt("version", root.optInt("graphVersion", 2))

        require(schema == "nle.render_graph") {
            "Invalid RenderGraph schema: $schema"
        }

        require(version >= 2) {
            "RenderGraph version $version is too old. Expected v2+."
        }

        return NleRenderGraph(
            schema = schema,
            version = version,
            project = parseProject(root.getJSONObject("project")),
            assets = parseAssets(root.optJSONArray("assets")),
            tracks = parseTracks(
                array = root.optJSONArray("tracks"),
                topLevelClips = root.optJSONArray("clips"),
            ),
            composition = parseComposition(root.optJSONObject("composition")),
            audioMix = parseAudioMix(root.optJSONObject("audioMix")),
            exportHints = parseExportHints(root.optJSONObject("exportHints")),
        )
    }

    private fun parseProject(json: JSONObject): NleRenderProject {
        return NleRenderProject(
            id = json.optString("id", ""),
            name = json.optString("name", "Untitled"),
            durationUs = json.optLong("durationMicros", 0L),
            width = json.optInt("width", json.optInt("targetWidth", 1080)),
            height = json.optInt("height", json.optInt("targetHeight", 1920)),
            frameRate = json.optDouble("frameRate", json.optDouble("targetFrameRate", 30.0)),
            aspectRatio = json.optString("aspectRatio", "9:16"),
            backgroundColor = json.optString("backgroundColor", "#000000"),
        )
    }

    private fun parseAssets(array: JSONArray?): List<NleRenderAsset> {
        if (array == null) return emptyList()

        return buildList {
            for (i in 0 until array.length()) {
                val json = array.optJSONObject(i) ?: continue

                add(
                    NleRenderAsset(
                        id = json.optString("id", ""),
                        type = json.optString("type", "unknown"),
                        originalPath = json.optNullableString("originalPath")
                            ?: json.optNullableString("exportPath")
                            ?: json.optNullableString("sourcePath")
                            ?: json.optNullableString("filePath")
                            ?: json.optNullableString("path")
                            ?: json.optNullableString("uri"),
                        proxyPath = json.optNullableString("proxyPath"),
                        thumbnailPath = json.optNullableString("thumbnailPath"),
                        displayName = json.optNullableString("displayName")
                            ?: json.optNullableString("fileName"),
                        durationUs = json.optLong("durationMicros", 0L),
                        width = json.optInt("width", 0),
                        height = json.optInt("height", 0),
                        hasVideo = json.optBoolean("hasVideo", false),
                        hasAudio = json.optBoolean("hasAudio", false),
                        codec = json.optNullableString("codec"),
                        frameRate = json.optNullableDouble("frameRate"),
                        rotationDegrees = json.optInt("rotationDegrees", 0),
                    )
                )
            }
        }
    }

    private fun parseTracks(
        array: JSONArray?,
        topLevelClips: JSONArray?,
    ): List<NleRenderTrack> {
        if (array == null) return emptyList()

        val clipsByTrack = groupClipsByTrack(topLevelClips)

        return buildList {
            for (i in 0 until array.length()) {
                val json = array.optJSONObject(i) ?: continue
                val trackId = json.optString("id", "")
                val trackType = json.optString("trackType", json.optString("type", ""))
                val nestedClips = json.optJSONArray("clips")
                val clips = if (nestedClips != null) {
                    parseClips(nestedClips)
                } else {
                    parseClips(clipsByTrack[trackId])
                }

                add(
                    NleRenderTrack(
                        id = trackId,
                        name = json.optString("name", ""),
                        type = json.optString("type", trackType),
                        trackType = trackType,
                        role = json.optString("role", ""),
                        trackRole = json.optString("trackRole", json.optString("role", "")),
                        sortOrder = json.optInt("sortOrder", json.optInt("index", i)),
                        isMuted = json.optBoolean("isMuted", false),
                        isSolo = json.optBoolean("isSolo", false),
                        isLocked = json.optBoolean("isLocked", false),
                        isHidden = json.optBoolean("isHidden", !json.optBoolean("isVisible", true)),
                        height = json.optDouble("height", 64.0),
                        colorHex = json.optNullableString("colorHex"),
                        isVisual = json.optBoolean("isVisual", isVisualTrackType(trackType)),
                        isAudio = json.optBoolean("isAudio", trackType == "audio"),
                        layerOrder = json.optInt("layerOrder", i),
                        clips = clips,
                        effectChain = parseEffectChain(json.optJSONObject("effectChain")),
                    )
                )
            }
        }
    }

    private fun groupClipsByTrack(array: JSONArray?): Map<String, JSONArray> {
        if (array == null) return emptyMap()

        val result = linkedMapOf<String, JSONArray>()
        for (i in 0 until array.length()) {
            val clip = array.optJSONObject(i) ?: continue
            val trackId = clip.optString("trackId", clip.optString("track_id", ""))
            if (trackId.isBlank()) continue
            result.getOrPut(trackId) { JSONArray() }.put(clip)
        }
        return result
    }

    private fun parseClips(array: JSONArray?): List<NleRenderClip> {
        if (array == null) return emptyList()

        return buildList {
            for (i in 0 until array.length()) {
                val json = array.optJSONObject(i) ?: continue

                val transformJson = json.optJSONObject("transform")
                val cropJson = json.optJSONObject("crop")
                val colorJson = json.optJSONObject("color")
                val audioJson = json.optJSONObject("audio")
                val textJson = json.optJSONObject("text")
                val lutStack = NleRenderGraphLutParser.parseClipStack(json)
                val primaryGrade = com.nle.editor.grade.NleRenderGraphPrimaryGradeParser.parseClipGrade(json)
                val colorCurveStack = com.nle.editor.curves.NleRenderGraphColorCurveParser.parseClipCurves(json)
                val secondaryGrades = NleRenderGraphSecondaryGradeParser.parseClipStack(json)

                add(
                    NleRenderClip(
                        id = json.optString("id", ""),
                        projectId = json.optString("projectId", ""),
                        trackId = json.optString("trackId", ""),
                        assetId = json.optNullableString("assetId"),
                        type = json.optString("type", json.optString("clipType", "unknown")),
                        clipType = json.optString("clipType", json.optString("type", "unknown")),
                        name = json.optString("name", ""),
                        timelineStartUs = json.optLong("timelineStartMicros", 0L),
                        timelineEndUs = json.optLong("timelineEndMicros", 0L),
                        sourceStartUs = json.optLong(
                            "sourceStartMicros",
                            json.optLong("sourceInMicros", 0L),
                        ),
                        sourceEndUs = json.optLong(
                            "sourceEndMicros",
                            json.optLong("sourceOutMicros", 0L),
                        ),
                        durationUs = json.optLong("durationMicros", 0L),
                        speed = json.optDouble("speed", 1.0),
                        transform = parseTransform(json, transformJson),
                        crop = parseCrop(json, cropJson),
                        color = parseColor(json, colorJson),
                        audio = parseAudio(json, audioJson),
                        text = parseText(json, textJson),
                        lutStack = lutStack,
                        primaryGrade = primaryGrade,
                        colorCurveStack = colorCurveStack,
                        secondaryGrades = secondaryGrades,
                        effectChain = parseEffectChain(json.optJSONObject("effectChain")),
                        isDisabled = json.optBoolean("isDisabled", false),
                        zIndex = json.optInt("zIndex", i),
                    )
                )
            }
        }
    }

    private fun isVisualTrackType(type: String): Boolean {
        return type == "video" ||
            type == "visual" ||
            type == "main" ||
            type == "overlay" ||
            type == "text" ||
            type == "adjustment"
    }

    private fun parseTransform(
        flat: JSONObject,
        nested: JSONObject?,
    ): NleRenderTransform {
        return NleRenderTransform(
            positionX = nested?.optDouble("positionX")
                ?: flat.optDouble("positionX", 0.0),
            positionY = nested?.optDouble("positionY")
                ?: flat.optDouble("positionY", 0.0),
            scale = nested?.optDouble("scale")
                ?: flat.optDouble("scale", 1.0),
            rotation = nested?.optDouble("rotation")
                ?: flat.optDouble("rotation", 0.0),
            opacity = nested?.optDouble("opacity")
                ?: flat.optDouble("opacity", 1.0),
        )
    }

    private fun parseCrop(
        flat: JSONObject,
        nested: JSONObject?,
    ): NleRenderCrop {
        return NleRenderCrop(
            fitMode = nested?.optString("fitMode")
                ?: flat.optString("fitMode", "fit"),
            left = nested?.optDouble("left")
                ?: flat.optDouble("cropLeft", 0.0),
            top = nested?.optDouble("top")
                ?: flat.optDouble("cropTop", 0.0),
            right = nested?.optDouble("right")
                ?: flat.optDouble("cropRight", 0.0),
            bottom = nested?.optDouble("bottom")
                ?: flat.optDouble("cropBottom", 0.0),
        )
    }

    private fun parseColor(
        flat: JSONObject,
        nested: JSONObject?,
    ): NleRenderColor {
        return NleRenderColor(
            brightness = nested?.optDouble("brightness")
                ?: flat.optDouble("brightness", 0.0),
            contrast = nested?.optDouble("contrast")
                ?: flat.optDouble("contrast", 1.0),
            saturation = nested?.optDouble("saturation")
                ?: flat.optDouble("saturation", 1.0),
        )
    }

    private fun parseAudio(
        flat: JSONObject,
        nested: JSONObject?,
    ): NleRenderAudio {
        return NleRenderAudio(
            volume = nested?.optDouble("volume")
                ?: flat.optDouble("volume", 1.0),
            fadeInUs = nested?.optLong("fadeInMicros")
                ?: flat.optLong("fadeInMicros", 0L),
            fadeOutUs = nested?.optLong("fadeOutMicros")
                ?: flat.optLong("fadeOutMicros", 0L),
        )
    }

    private fun parseText(
        flat: JSONObject,
        nested: JSONObject?,
    ): NleRenderText? {
        val content = nested?.optString("content")
            ?: flat.optNullableString("textContent")
            ?: return null

        return NleRenderText(
            content = content,
            styleJson = nested?.optNullableString("styleJson")
                ?: flat.optNullableString("textStyleJson"),
            colorHex = nested?.optNullableString("colorHex")
                ?: flat.optNullableString("colorHex"),
        )
    }

    private fun parseComposition(json: JSONObject?): NleRenderComposition {
        if (json == null) {
            return NleRenderComposition(
                visualTrackIdsBottomToTop = emptyList(),
                enabledVisualTrackIdsBottomToTop = emptyList(),
                audioTrackIds = emptyList(),
                enabledAudioTrackIds = emptyList(),
                hasSoloAudio = false,
                hasHiddenTracks = false,
                visualLayerCount = 0,
                audioLayerCount = 0,
            )
        }

        return NleRenderComposition(
            visualTrackIdsBottomToTop = json.optStringArray("visualTrackIdsBottomToTop"),
            enabledVisualTrackIdsBottomToTop = json.optStringArray("enabledVisualTrackIdsBottomToTop"),
            audioTrackIds = json.optStringArray("audioTrackIds"),
            enabledAudioTrackIds = json.optStringArray("enabledAudioTrackIds"),
            hasSoloAudio = json.optBoolean("hasSoloAudio", false),
            hasHiddenTracks = json.optBoolean("hasHiddenTracks", false),
            visualLayerCount = json.optInt("visualLayerCount", 0),
            audioLayerCount = json.optInt("audioLayerCount", 0),
        )
    }

    private fun parseExportHints(json: JSONObject?): NleRenderExportHints {
        if (json == null) {
            return NleRenderExportHints(
                useProxyForPreview = true,
                useOriginalForExport = true,
                requiresGpuCompositor = true,
                containsText = false,
                containsImage = false,
                containsVideo = false,
                containsAudio = false,
                containsAdjustment = false,
                containsColorAdjustments = false,
                containsCrop = false,
                containsSpeedChanges = false,
                containsFades = false,
                containsLut = false,
                containsColorCurves = false,
                containsSecondaryGrades = false,
            )
        }

        return NleRenderExportHints(
            useProxyForPreview = json.optBoolean("useProxyForPreview", true),
            useOriginalForExport = json.optBoolean("useOriginalForExport", true),
            requiresGpuCompositor = json.optBoolean("requiresGpuCompositor", true),
            containsText = json.optBoolean("containsText", false),
            containsImage = json.optBoolean("containsImage", false),
            containsVideo = json.optBoolean("containsVideo", false),
            containsAudio = json.optBoolean("containsAudio", false),
            containsAdjustment = json.optBoolean("containsAdjustment", false),
            containsColorAdjustments = json.optBoolean("containsColorAdjustments", false),
            containsCrop = json.optBoolean("containsCrop", false),
            containsSpeedChanges = json.optBoolean("containsSpeedChanges", false),
            containsFades = json.optBoolean("containsFades", false),
            containsLut = json.optBoolean("containsLut", false),
            containsColorCurves = json.optBoolean("containsColorCurves", false),
            containsSecondaryGrades = json.optBoolean("containsSecondaryGrades", false),
        )
    }

    private fun parseAudioMix(json: JSONObject?): NleRenderAudioMix {
        if (json == null) {
            return NleRenderAudioMix(
                enabled = true,
                hasSoloAudio = false,
                soloAudioTrackIds = emptyList(),
                mutedAudioTrackIds = emptyList(),
                activeAudioTrackIds = emptyList(),
                sampleRate = 48000,
                channels = 2,
            )
        }

        return NleRenderAudioMix(
            enabled = json.optBoolean("enabled", true),
            hasSoloAudio = json.optBoolean("hasSoloAudio", false),
            soloAudioTrackIds = json.optStringArray("soloAudioTrackIds"),
            mutedAudioTrackIds = json.optStringArray("mutedAudioTrackIds"),
            activeAudioTrackIds = json.optStringArray("activeAudioTrackIds"),
            sampleRate = json.optInt("sampleRate", 48000),
            channels = json.optInt("channels", 2),
            masterEffectChain = parseEffectChain(json.optJSONObject("masterEffectChain")),
        )
    }

    private fun parseEffectChain(json: JSONObject?): NleRenderEffectChain? {
        if (json == null) return null
        val ownerId = json.optString("ownerId", "")
        val ownerType = json.optString("ownerType", "")
        val enabled = json.optBoolean("enabled", true)
        val slotsArray = json.optJSONArray("slots") ?: return NleRenderEffectChain(ownerId, ownerType, emptyList(), enabled)

        val slots = buildList {
            for (i in 0 until slotsArray.length()) {
                val slotJson = slotsArray.optJSONObject(i) ?: continue
                val active = slotJson.optString("bypassMode", "active") == "active"
                val wetMix = slotJson.optDouble("wetMix", 1.0).toFloat()
                val type = slotJson.optString("type", "")

                add(
                    NleRenderEffectSlot(
                        id = slotJson.optString("id", ""),
                        type = type,
                        name = slotJson.optString("name", "Effect"),
                        order = slotJson.optInt("order", 0),
                        active = active,
                        wetMix = wetMix,
                        eq3Band = parseEq3BandSettings(slotJson.optJSONObject("eq3Band")),
                        compressor = parseCompressorSettings(slotJson.optJSONObject("compressor")),
                        limiter = parseLimiterSettings(slotJson.optJSONObject("limiter")),
                        noiseGate = parseNoiseGateSettings(slotJson.optJSONObject("noiseGate")),
                        noiseReduction = parseNoiseReductionSettings(slotJson.optJSONObject("noiseReduction")),
                        reverb = parseReverbSettings(slotJson.optJSONObject("reverb")),
                        pitchTempo = parsePitchTempoSettings(slotJson.optJSONObject("pitchTempo")),
                        voiceEnhancer = parseVoiceEnhancerSettings(slotJson.optJSONObject("voiceEnhancer")),
                    )
                )
            }
        }

        return NleRenderEffectChain(ownerId, ownerType, slots, enabled)
    }

    private fun parseEq3BandSettings(json: JSONObject?): NleEq3BandSettings? {
        if (json == null) return null
        return NleEq3BandSettings(
            lowGainDb = json.optDouble("lowGainDb", 0.0).toFloat(),
            midGainDb = json.optDouble("midGainDb", 0.0).toFloat(),
            highGainDb = json.optDouble("highGainDb", 0.0).toFloat(),
            lowFrequencyHz = json.optDouble("lowFrequencyHz", 220.0).toFloat(),
            highFrequencyHz = json.optDouble("highFrequencyHz", 4000.0).toFloat(),
        )
    }

    private fun parseCompressorSettings(json: JSONObject?): NleCompressorSettings? {
        if (json == null) return null
        return NleCompressorSettings(
            thresholdDb = json.optDouble("thresholdDb", -18.0).toFloat(),
            ratio = json.optDouble("ratio", 1.0).toFloat(),
            attackMs = json.optDouble("attackMs", 12.0).toFloat(),
            releaseMs = json.optDouble("releaseMs", 120.0).toFloat(),
            makeupGainDb = json.optDouble("makeupGainDb", 0.0).toFloat(),
            kneeDb = json.optDouble("kneeDb", 6.0).toFloat(),
        )
    }

    private fun parseLimiterSettings(json: JSONObject?): NleLimiterSettings? {
        if (json == null) return null
        return NleLimiterSettings(
            ceilingDb = json.optDouble("ceilingDb", -1.0).toFloat(),
            releaseMs = json.optDouble("releaseMs", 80.0).toFloat(),
            truePeakSafe = json.optBoolean("truePeakSafe", true),
        )
    }

    private fun parseNoiseGateSettings(json: JSONObject?): NleNoiseGateSettings? {
        if (json == null) return null
        return NleNoiseGateSettings(
            thresholdDb = json.optDouble("thresholdDb", -42.0).toFloat(),
            reductionDb = json.optDouble("reductionDb", -18.0).toFloat(),
            attackMs = json.optDouble("attackMs", 5.0).toFloat(),
            releaseMs = json.optDouble("releaseMs", 160.0).toFloat(),
        )
    }

    private fun parseNoiseReductionSettings(json: JSONObject?): NleNoiseReductionSettings? {
        if (json == null) return null
        return NleNoiseReductionSettings(
            amount = json.optDouble("amount", 0.0).toFloat(),
            voiceOptimized = json.optBoolean("voiceOptimized", true),
        )
    }

    private fun parseReverbSettings(json: JSONObject?): NleReverbSettings? {
        if (json == null) return null
        return NleReverbSettings(
            roomSize = json.optDouble("roomSize", 0.22).toFloat(),
            damping = json.optDouble("damping", 0.55).toFloat(),
            wet = json.optDouble("wet", 0.12).toFloat(),
            dry = json.optDouble("dry", 1.0).toFloat(),
        )
    }

    private fun parsePitchTempoSettings(json: JSONObject?): NlePitchTempoSettings? {
        if (json == null) return null
        return NlePitchTempoSettings(
            pitchSemitones = json.optDouble("pitchSemitones", 0.0).toFloat(),
            tempoMultiplier = json.optDouble("tempoMultiplier", 1.0).toFloat(),
            preserveFormants = json.optBoolean("preserveFormants", true),
        )
    }

    private fun parseVoiceEnhancerSettings(json: JSONObject?): NleVoiceEnhancerSettings? {
        if (json == null) return null
        return NleVoiceEnhancerSettings(
            clarity = json.optDouble("clarity", 0.55).toFloat(),
            body = json.optDouble("body", 0.35).toFloat(),
            air = json.optDouble("air", 0.40).toFloat(),
            deEss = json.optDouble("deEss", 0.25).toFloat(),
        )
    }
}

private fun JSONObject.optNullableString(key: String): String? {
    if (!has(key) || isNull(key)) return null

    val value = optString(key, "").trim()
    return value.ifEmpty { null }
}

private fun JSONObject.optNullableDouble(key: String): Double? {
    if (!has(key) || isNull(key)) return null
    return optDouble(key)
}

private fun JSONObject.optStringArray(key: String): List<String> {
    val array = optJSONArray(key) ?: return emptyList()

    return buildList {
        for (i in 0 until array.length()) {
            val value = array.optString(i, "").trim()
            if (value.isNotEmpty()) add(value)
        }
    }
}
