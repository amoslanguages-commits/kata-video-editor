package com.nle.editor.export

class NleExportProgressCombiner {

    @Volatile
    private var videoProgress: Double = 0.0

    @Volatile
    private var audioProgress: Double = 0.0

    fun updateVideo(value: Double): Double {
        videoProgress = value.coerceIn(0.0, 1.0)
        return combined()
    }

    fun updateAudio(value: Double): Double {
        audioProgress = value.coerceIn(0.0, 1.0)
        return combined()
    }

    fun combined(): Double {
        // Video is heavier. Audio still matters for final mux.
        return (videoProgress * 0.82 + audioProgress * 0.18).coerceIn(0.0, 1.0)
    }
}
