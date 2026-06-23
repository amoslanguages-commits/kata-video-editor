package com.kata.videoeditor.nle

data class NleExportProfile(
    val width: Int,
    val height: Int,
    val frameRate: Int,
    val videoBitrate: Int,
    val iFrameIntervalSeconds: Int,
    val codec: String,
    val container: String,

    val includeAudio: Boolean,
    val audioSampleRate: Int,
    val audioChannels: Int,
    val audioBitrate: Int,
) {
    // Computed properties for legacy field backward compatibility
    val bitrateBps: Int get() = videoBitrate
    val gopInterval: Int get() = iFrameIntervalSeconds
    val containerFormat: String get() = container

    companion object {
        fun fromPayload(payload: Map<String, Any?>): NleExportProfile {
            val requestedWidth = payload.intOrDefault("width", 1920)
            val requestedHeight = payload.intOrDefault("height", 1080)

            val width = makeEven(requestedWidth.coerceIn(360, 3840))
            val height = makeEven(requestedHeight.coerceIn(360, 2160))

            val frameRate = payload.intOrDefault("frameRate", 30).coerceIn(15, 60)

            val bitrate = payload.intOrDefault(
                "videoBitrate",
                payload.intOrDefault("bitrateBps", defaultBitrateForHeight(height))
            )

            val iFrameInterval = payload.intOrDefault(
                "iFrameIntervalSeconds",
                payload.intOrDefault("gopInterval", 30)
            )

            val container = payload["container"]?.toString()
                ?: payload["containerFormat"]?.toString()
                ?: "video/mp4"

            return NleExportProfile(
                width = width,
                height = height,
                frameRate = frameRate,
                videoBitrate = bitrate,
                iFrameIntervalSeconds = iFrameInterval,
                codec = payload["codec"]?.toString() ?: "video/avc",
                container = container,

                includeAudio = payload.boolOrDefault("includeAudio", true),
                audioSampleRate = payload.intOrDefault("audioSampleRate", 48000)
                    .coerceIn(8000, 96000),
                audioChannels = payload.intOrDefault("audioChannels", 2)
                    .coerceIn(1, 2),
                audioBitrate = payload.intOrDefault("audioBitrate", 192000)
                    .coerceIn(64000, 320000),
            )
        }

        private fun defaultBitrateForHeight(height: Int): Int {
            return when {
                height <= 720 -> 4_000_000
                height <= 1080 -> 8_000_000
                else -> 24_000_000
            }
        }

        private fun makeEven(value: Int): Int {
            return if (value % 2 == 0) value else value + 1
        }

        private fun Map<String, Any?>.intOrDefault(
            key: String,
            default: Int,
        ): Int {
            val value = this[key]

            return when (value) {
                is Int -> value
                is Long -> value.toInt()
                is Double -> value.toInt()
                is Float -> value.toInt()
                else -> default
            }
        }

        private fun Map<String, Any?>.boolOrDefault(
            key: String,
            default: Boolean,
        ): Boolean {
            val value = this[key]

            return when (value) {
                is Boolean -> value
                is String -> value.equals("true", ignoreCase = true)
                else -> default
            }
        }
    }

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "width" to width,
            "height" to height,
            "frameRate" to frameRate,
            "videoBitrate" to videoBitrate,
            "iFrameIntervalSeconds" to iFrameIntervalSeconds,
            "codec" to codec,
            "container" to container,
            "includeAudio" to includeAudio,
            "audioSampleRate" to audioSampleRate,
            "audioChannels" to audioChannels,
            "audioBitrate" to audioBitrate
        )
    }
}
