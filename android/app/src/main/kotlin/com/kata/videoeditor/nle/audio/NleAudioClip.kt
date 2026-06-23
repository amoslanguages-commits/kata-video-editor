package com.kata.videoeditor.nle.audio

data class NleAudioTrackState(
    val trackId: String,
    val volume: Float = 1f,
    val muted: Boolean = false,
    val solo: Boolean = false,
)

data class NleAudioClip(
    val clipId: String,
    val assetId: String,
    val trackId: String,
    val inputPath: String,
    val timelineStartMicros: Long,
    val timelineEndMicros: Long,
    val sourceInMicros: Long,
    val sourceOutMicros: Long,
    val clipVolume: Float,
    val trackVolume: Float,
    val fadeInMicros: Long,
    val fadeOutMicros: Long,
    val speed: Double,
) {
    val durationMicros: Long
        get() = (timelineEndMicros - timelineStartMicros).coerceAtLeast(0L)

    fun gainAtTimelineTime(timeMicros: Long): Float {
        if (timeMicros < timelineStartMicros || timeMicros >= timelineEndMicros) {
            return 0f
        }

        var gain = clipVolume * trackVolume

        if (fadeInMicros > 0L) {
            val local = (timeMicros - timelineStartMicros).coerceAtLeast(0L)
            if (local < fadeInMicros) {
                gain *= local.toFloat() / fadeInMicros.toFloat()
            }
        }

        if (fadeOutMicros > 0L) {
            val remaining = (timelineEndMicros - timeMicros).coerceAtLeast(0L)
            if (remaining < fadeOutMicros) {
                gain *= remaining.toFloat() / fadeOutMicros.toFloat()
            }
        }

        return gain.coerceIn(0f, 4f)
    }
}

data class NleAudioTimeline(
    val projectId: String,
    val durationMicros: Long,
    val clips: List<NleAudioClip>,
) {
    val hasAudio: Boolean
        get() = clips.isNotEmpty()
}
