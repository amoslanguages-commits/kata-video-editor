package com.kata.videoeditor.nle

data class NleNativeEvent(
    val type: String,
    val projectId: String? = null,
    val sessionId: String? = null,
    val commandId: String? = null,
    val jobId: String? = null,
    val payload: Map<String, Any?> = emptyMap()
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "type"            to type,
        "projectId"       to projectId,
        "sessionId"       to sessionId,
        "commandId"       to commandId,
        "jobId"           to jobId,
        "payload"         to payload,
        "timestampMicros" to (System.currentTimeMillis() * 1_000L)
    )
}
