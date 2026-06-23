package com.kata.videoeditor.nle

data class NleProxyProfile(
    val targetHeight: Int,
    val frameRate: Int,
    val videoBitrate: Int,
    val iFrameIntervalSeconds: Int,
    val codec: String,
) {
    companion object {
        fun fromPayload(payload: Map<String, Any?>): NleProxyProfile {
            val targetHeight = payload.intOrDefault("targetHeight", 720).coerceIn(360, 1080)
            val frameRate    = payload.intOrDefault("frameRate", 30).coerceIn(15, 60)
            val bitrate      = payload.intOrDefault("videoBitrate", bitrateForHeight(targetHeight))

            return NleProxyProfile(
                targetHeight          = targetHeight,
                frameRate             = frameRate,
                videoBitrate          = bitrate,
                iFrameIntervalSeconds = payload.intOrDefault("iFrameIntervalSeconds", 2),
                codec                 = payload["codec"]?.toString() ?: "video/avc"
            )
        }

        private fun bitrateForHeight(height: Int): Int = when {
            height <= 540 -> 1_200_000
            height <= 720 -> 2_500_000
            else          -> 4_500_000
        }

        private fun Map<String, Any?>.intOrDefault(key: String, default: Int): Int =
            when (val v = this[key]) {
                is Int    -> v
                is Long   -> v.toInt()
                is Double -> v.toInt()
                is Float  -> v.toInt()
                else      -> default
            }
    }

    fun toMap(): Map<String, Any?> = mapOf(
        "targetHeight"          to targetHeight,
        "frameRate"             to frameRate,
        "videoBitrate"          to videoBitrate,
        "iFrameIntervalSeconds" to iFrameIntervalSeconds,
        "codec"                 to codec
    )
}
