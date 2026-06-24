package com.kata.videoeditor.nle

import org.json.JSONObject

object NleNativeBridgeContract {
    const val METHOD_CHANNEL = "nle.native_bridge"
    const val PROTOCOL_VERSION = 1
    const val MIN_PROTOCOL_VERSION = 1
    const val MAX_PROTOCOL_VERSION = 1

    const val RENDER_GRAPH_SCHEMA = "nle.render_graph"
    const val RENDER_GRAPH_VERSION = 2
    const val MIN_RENDER_GRAPH_VERSION = 2
    const val MAX_RENDER_GRAPH_VERSION = 2

    const val KEY_PROTOCOL_VERSION = "protocolVersion"
    const val KEY_RENDER_GRAPH_JSON = "renderGraphJson"
    const val KEY_RENDER_GRAPH_SCHEMA = "renderGraphSchema"
    const val KEY_RENDER_GRAPH_VERSION = "renderGraphVersion"

    private val renderGraphMethods = setOf(
        "load_render_graph",
        "update_render_graph",
        "validate_render_graph",
        "render_gpu_preview_frame",
        "start_export_job",
        "validate_export_graph",
        "qa_validate_render_graph",
        "qa_probe_visual",
        "qa_probe_audio",
        "prepare_true_preview"
    )

    fun requireCompatibleArgs(method: String, args: Map<String, Any?>) {
        val protocolVersion = optionalInt(args[KEY_PROTOCOL_VERSION])
        if (protocolVersion != null && protocolVersion !in MIN_PROTOCOL_VERSION..MAX_PROTOCOL_VERSION) {
            throw IllegalArgumentException(
                "${NleNativeErrorCode.INVALID_ARGUMENTS}: unsupported native bridge protocol $protocolVersion"
            )
        }

        if (method !in renderGraphMethods) return

        val renderGraphJson = args[KEY_RENDER_GRAPH_JSON] as? String ?: return
        val declaredSchema = args[KEY_RENDER_GRAPH_SCHEMA] as? String
        val declaredVersion = optionalInt(args[KEY_RENDER_GRAPH_VERSION])

        if (declaredSchema != null && declaredSchema != RENDER_GRAPH_SCHEMA) {
            throw IllegalArgumentException(
                "${NleNativeErrorCode.GRAPH_VALIDATION_FAILED}: unsupported render graph schema $declaredSchema"
            )
        }
        if (declaredVersion != null && declaredVersion !in MIN_RENDER_GRAPH_VERSION..MAX_RENDER_GRAPH_VERSION) {
            throw IllegalArgumentException(
                "${NleNativeErrorCode.GRAPH_VALIDATION_FAILED}: unsupported render graph version $declaredVersion"
            )
        }

        val root = JSONObject(renderGraphJson)
        val schema = root.optString("schema", "")
        val version = root.optInt("version", -1)

        if (schema != RENDER_GRAPH_SCHEMA) {
            throw IllegalArgumentException(
                "${NleNativeErrorCode.GRAPH_VALIDATION_FAILED}: render graph schema mismatch $schema"
            )
        }
        if (version !in MIN_RENDER_GRAPH_VERSION..MAX_RENDER_GRAPH_VERSION) {
            throw IllegalArgumentException(
                "${NleNativeErrorCode.GRAPH_VALIDATION_FAILED}: render graph version mismatch $version"
            )
        }
    }

    private fun optionalInt(value: Any?): Int? {
        return when (value) {
            is Int -> value
            is Long -> value.toInt()
            is Double -> value.toInt()
            is Float -> value.toInt()
            is String -> value.toIntOrNull()
            else -> null
        }
    }
}
