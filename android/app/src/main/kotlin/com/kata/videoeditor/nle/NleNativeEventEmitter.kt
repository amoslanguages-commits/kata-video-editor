package com.kata.videoeditor.nle

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Bridges native engine events to Flutter's EventChannel.
 *
 * Events emitted before the Dart side has subscribed are buffered and
 * flushed in-order the moment [onListen] is called.
 */
class NleNativeEventEmitter : EventChannel.StreamHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private val pendingEvents = mutableListOf<NleNativeEvent>()

    // ── StreamHandler ────────────────────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (pendingEvents.isNotEmpty()) {
            val copy = pendingEvents.toList()
            pendingEvents.clear()
            copy.forEach { emit(it) }
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ── Public API ───────────────────────────────────────────────────────────

    fun emit(event: NleNativeEvent) {
        val sink = eventSink
        if (sink == null) {
            pendingEvents.add(event)
            return
        }
        mainHandler.post { sink.success(event.toMap()) }
    }

    fun emitError(
        projectId: String?,
        sessionId: String?,
        commandId: String?,
        code: String,
        message: String,
        technicalMessage: String? = null,
        payload: Map<String, Any?> = emptyMap()
    ) {
        emit(
            NleNativeEvent(
                type      = NleNativeEventType.ENGINE_ERROR,
                projectId = projectId,
                sessionId = sessionId,
                commandId = commandId,
                payload   = mapOf(
                    "code"             to code,
                    "message"          to message,
                    "technicalMessage" to technicalMessage
                ) + payload
            )
        )
    }
}
