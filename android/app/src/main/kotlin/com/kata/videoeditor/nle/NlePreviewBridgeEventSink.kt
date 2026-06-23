package com.kata.videoeditor.nle

import android.util.Log
import com.nle.editor.preview.NlePreviewEventSink

/**
 * 29F: Monitor-aware event sink.
 * Every event now carries [monitorId] ("source" | "program") so Flutter
 * can route events to the correct controller.
 */
class NlePreviewBridgeEventSink(
    private val monitorId: String,
    private val sendEvent: (String, Map<String, Any?>) -> Unit,
) : NlePreviewEventSink {

    override fun onPreviewTextureReady(
        textureId: Long,
        width: Int,
        height: Int,
    ) {
        Log.d("NlePreview", "texture_ready monitor=$monitorId textureId=$textureId size=${width}x$height")
        sendEvent(
            "preview_texture_ready",
            mapOf(
                "monitorId" to monitorId,
                "textureId" to textureId,
                "width" to width,
                "height" to height,
            ),
        )
    }

    override fun onPreviewFrameRendered(
        timelineTimeUs: Long,
    ) {
        sendEvent(
            "preview_frame_rendered",
            mapOf(
                "monitorId" to monitorId,
                "timelineTimeUs" to timelineTimeUs,
            ),
        )
    }

    override fun onPreviewDroppedFrame(
        timelineTimeUs: Long,
        reason: String,
    ) {
        Log.w("NlePreview", "dropped monitor=$monitorId timeUs=$timelineTimeUs reason=$reason")
        sendEvent(
            "preview_dropped_frame",
            mapOf(
                "monitorId" to monitorId,
                "timelineTimeUs" to timelineTimeUs,
                "reason" to reason,
            ),
        )
    }

    override fun onPreviewEnded() {
        sendEvent(
            "preview_ended",
            mapOf("monitorId" to monitorId),
        )
    }

    override fun onPreviewError(
        message: String,
    ) {
        Log.e("NlePreview", "error monitor=$monitorId message=$message")
        sendEvent(
            "preview_error",
            mapOf(
                "monitorId" to monitorId,
                "message" to message,
            ),
        )
    }

    override fun onColorPipelineStats(
        passCount: Int,
        format: String,
        precision: String,
        usedFallback: Boolean,
        fallbackReason: String?,
    ) {
        sendEvent(
            "color_pipeline_stats",
            mapOf(
                "monitorId" to monitorId,
                "passCount" to passCount,
                "format" to format,
                "precision" to precision,
                "usedFallback" to usedFallback,
                "fallbackReason" to fallbackReason,
            ),
        )
    }
}
