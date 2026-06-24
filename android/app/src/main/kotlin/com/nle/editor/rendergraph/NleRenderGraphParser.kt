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

        require(schema == "nle.render_graph") { "Invalid RenderGraph schema: $schema" }
        require(version >= 2) { "RenderGraph version $version is too old. Expected v2+." }

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
                val originalPath = json.optNullableString("originalPath")
                    ?: json.optNullableString("sourcePath")
                    ?: json.optNullableString("filePath")
                    ?: json.optNullableString("path")
                    ?: json.optNullableString("uri")
                val projectPath = json.optNullableString("projectPath")
                val proxyPath = json.optNullableString("proxyPath")
                val resolvedPath = json.optNullableString("resolvedPath")
                    ?: json.optNullableString("selectedMediaPath")
                    ?: json.optNullableString("exportPath")
                    ?: originalPath
                    ?: proxyPath
                add(
                    NleRenderAsset(
                        id = json.optString("id", ""),
                        type = json.optString("type", "unknown"),
                        originalPath = originalPath,
                        projectPath = projectPath,
                        proxyPath = proxyPath,
                        resolvedPath = resolvedPath,
                        sourcePolicy = json.optString("sourcePolicy", "automatic"),
                        usedProxy = json.optBoolean("usedProxy", resolvedPath != null && resolvedPath == proxyPath),
                        thumbnailPath = json.optNullableString("thumbnailPath"),
                        displayName = json.optNullableString("displayName") ?: json.optNullableString("fileName"),
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

    private fun parseTracks(array: JSONArray?, topLevelClips: JSONArray?): List<NleRenderTrack> {
        if (array == null) return emptyList()
        val clipsByTrack = groupClipsByTrack(topLevelClips)
        return buildList {
            for (i in 0 until array.length()) {
                val json = array.optJSONObject(i) ?: continue
                val trackId = json.optString("id", "")
                val trackType = json.optString("trackType", json.optString("type", ""))
                val nestedClips = json.optJSONArray("clips")
                val clips = if (nestedClips != null) parseClips(nestedClips) else parseClips(clipsByTrack[trackId])
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
                        height = json.optDouble("height", 72.0),
                        colorHex = json.optNullableString("colorHex"),
                        isVisual = json.optBoolean("isVisual", trackType != "audio"),
                        isAudio = json.optBoolean("isAudio", trackType == "audio"),
                        layerOrder = json.optInt("layerOrder", json.optInt("sortOrder", i)),
                        clips = clips,
                        effectChain = parseEffectChain(json.optJSONObject("effectChain")),
                    )
                )
            }
        }
    }

    private fun groupClipsByTrack(array: JSONArray?): Map<String, JSONArray> {
        val result = mutableMapOf<String, JSONArray>()
        if (array == null) return result
        for (i in 0 until array.length()) {
            val clip = array.optJSONObject(i) ?: continue
            val trackId = clip.optString("trackId", "")
            if (trackId.isBlank()) continue
            val bucket = result.getOrPut(trackId) { JSONArray() }
            bucket.put(clip)
        }
        return result
    }

    private fun parseClips(array: JSONArray?): List<NleRenderClip> {
        if (array == null) return emptyList()
        return buildList {
            for (i in 0 until array.length()) {
                val json = array.optJSONObject(i) ?: continue
                val lutStack = NleRenderGraphLutParser.parseClipStack(json.optJSONObject("lutStack") ?: JSONObject())
                val secondaryGrades = NleRenderGraphSecondaryGradeParser.parseClipStack(json.optJSONObject("secondaryGrades") ?: JSONObject())
                add(
                    NleRenderClip(
                        id = json.optString("id", ""),
                        projectId = json.optString("projectId", ""),
                        trackId = json.optString("trackId", ""),
                        assetId = json.optNullableString("assetId"),
                        type = json.optString("type", json.optString("clipType", "video")),
                        clipType = json.optString("clipType", json.optString("type", "video")),
                        name = json.optString("name", ""),
                        timelineStartUs = json.optLong("timelineStartMicros", 0L),
                        timelineEndUs = json.optLong("timelineEndMicros", 0L),
                        sourceStartUs = json.optLong("sourceStartMicros", json.optLong("sourceInMicros", 0L)),
                        sourceEndUs = json.optLong("sourceEndMicros", json.optLong("sourceOutMicros", 0L)),
                        durationUs = json.optLong("durationMicros", 0L),
                        speed = json.optDouble("speed", 1.0),
                        transform = parseTransform(json.optJSONObject("transform"), json),
                        crop = parseCrop(json.optJSONObject("crop"), json),
                        color = parseColor(json.optJSONObject("color"), json),
                        audio = parseAudio(json.optJSONObject("audio"), json),
                        text = parseText(json.optJSONObject("text"), json),
                        lutStack = lutStack,
                        secondaryGrades = secondaryGrades,
                        effectChain = parseEffectChain(json.optJSONObject("effectChain")),
                        isDisabled = json.optBoolean("isDisabled", false),
                        zIndex = json.optInt("zIndex", json.optInt("layerOrder", i)),
                    )
                )
            }
        }
    }

    private fun parseTransform(json: JSONObject?, fallback: JSONObject): NleRenderTransform {
        return NleRenderTransform(
            positionX = json?.optDouble("positionX") ?: fallback.optDouble("positionX", 0.0),
            positionY = json?.optDouble("positionY") ?: fallback.optDouble("positionY", 0.0),
            scale = json?.optDouble("scale") ?: fallback.optDouble("scale", 1.0),
            rotation = json?.optDouble("rotation") ?: fallback.optDouble("rotation", 0.0),
            opacity = json?.optDouble("opacity") ?: fallback.optDouble("opacity", 1.0),
        )
    }

    private fun parseCrop(json: JSONObject?, fallback: JSONObject): NleRenderCrop {
        return NleRenderCrop(
            fitMode = json?.optString("fitMode") ?: fallback.optString("fitMode", "fit"),
            left = json?.optDouble("left") ?: fallback.optDouble("cropLeft", 0.0),
            top = json?.optDouble("top") ?: fallback.optDouble("cropTop", 0.0),
            right = json?.optDouble("right") ?: fallback.optDouble("cropRight", 0.0),
            bottom = json?.optDouble("bottom") ?: fallback.optDouble("cropBottom", 0.0),
        )
    }

    private fun parseColor(json: JSONObject?, fallback: JSONObject): NleRenderColor {
        return NleRenderColor(
            brightness = json?.optDouble("brightness") ?: fallback.optDouble("brightness", 0.0),
            contrast = json?.optDouble("contrast") ?: fallback.optDouble("contrast", 1.0),
            saturation = json?.optDouble("saturation") ?: fallback.optDouble("saturation", 1.0),
        )
    }

    private fun parseAudio(json: JSONObject?, fallback: JSONObject): NleRenderAudio {
        return NleRenderAudio(
            volume = json?.optDouble("volume") ?: fallback.optDouble("volume", 1.0),
            fadeInUs = json?.optLong("fadeInUs") ?: fallback.optLong("fadeInMicros", 0L),
            fadeOutUs = json?.optLong("fadeOutUs") ?: fallback.optLong("fadeOutMicros", 0L),
        )
    }

    private fun parseText(json: JSONObject?, fallback: JSONObject): NleRenderText? {
        val content = json?.optNullableString("content") ?: fallback.optNullableString("textContent") ?: return null
        return NleRenderText(
            content = content,
            styleJson = json?.optNullableString("styleJson") ?: fallback.optNullableString("textStyleJson"),
            colorHex = json?.optNullableString("colorHex") ?: fallback.optNullableString("colorHex"),
        )
    }

    private fun parseComposition(json: JSONObject?): NleRenderComposition {
        return NleRenderComposition(
            durationUs = json?.optLong("durationMicros") ?: 0L,
            videoTrackCount = json?.optInt("videoTrackCount") ?: 0,
            audioTrackCount = json?.optInt("audioTrackCount") ?: 0,
            clipCount = json?.optInt("clipCount") ?: 0,
            hasOverlays = json?.optBoolean("hasOverlays") ?: false,
            hasText = json?.optBoolean("hasText") ?: false,
            hasAudio = json?.optBoolean("hasAudio") ?: false,
        )
    }

    private fun parseAudioMix(json: JSONObject?): NleRenderAudioMix {
        return NleRenderAudioMix(
            enabled = json?.optBoolean("enabled") ?: true,
            hasSoloAudio = json?.optBoolean("hasSoloAudio") ?: false,
            soloAudioTrackIds = json.optStringArray("soloAudioTrackIds"),
            mutedAudioTrackIds = json.optStringArray("mutedAudioTrackIds"),
            activeAudioTrackIds = json.optStringArray("activeAudioTrackIds"),
            sampleRate = json?.optInt("sampleRate") ?: 48_000,
            channels = json?.optInt("channels") ?: 2,
            masterEffectChain = parseEffectChain(json?.optJSONObject("masterEffectChain")),
        )
    }

    private fun parseExportHints(json: JSONObject?): NleRenderExportHints {
        return NleRenderExportHints(
            requiresCompositing = json?.optBoolean("requiresCompositing") ?: false,
            requiresAudioMixdown = json?.optBoolean("requiresAudioMixdown") ?: false,
            requiresColorPipeline = json?.optBoolean("requiresColorPipeline") ?: false,
            requiresTextLayout = json?.optBoolean("requiresTextLayout") ?: false,
            useOriginalForExport = json?.optBoolean("useOriginalForExport") ?: true,
        )
    }

    private fun parseEffectChain(json: JSONObject?): NleRenderEffectChain? {
        if (json == null) return null
        val nodes = mutableListOf<Map<String, Any?>>()
        val array = json.optJSONArray("nodes") ?: JSONArray()
        for (i in 0 until array.length()) {
            val node = array.optJSONObject(i) ?: continue
            nodes.add(node.toMap())
        }
        return NleRenderEffectChain(enabled = json.optBoolean("enabled", true), nodes = nodes)
    }
}

private fun JSONObject?.optStringArray(name: String): List<String> {
    if (this == null) return emptyList()
    val array = optJSONArray(name) ?: return emptyList()
    return buildList {
        for (i in 0 until array.length()) {
            val value = array.optString(i, "")
            if (value.isNotBlank()) add(value)
        }
    }
}

private fun JSONObject.optNullableString(name: String): String? {
    if (!has(name) || isNull(name)) return null
    val value = optString(name, "")
    return value.ifBlank { null }
}

private fun JSONObject.optNullableDouble(name: String): Double? {
    if (!has(name) || isNull(name)) return null
    return optDouble(name)
}

private fun JSONObject.toMap(): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>()
    val keys = keys()
    while (keys.hasNext()) {
        val key = keys.next()
        result[key] = opt(key)
    }
    return result
}
