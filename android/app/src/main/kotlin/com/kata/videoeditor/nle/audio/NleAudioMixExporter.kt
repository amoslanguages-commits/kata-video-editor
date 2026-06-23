package com.kata.videoeditor.nle.audio

import com.kata.videoeditor.nle.NleExportProfile
import java.util.concurrent.atomic.AtomicBoolean

class NleAudioMixExporter {
    private val parser = NleRenderGraphAudioParser()
    private val mixer = NleAudioTimelineMixer()
    private val encoder = NleAacEncoder()

    fun exportAudioMix(
        projectId: String,
        renderGraphJson: String,
        durationMicros: Long,
        outputM4aPath: String,
        profile: NleExportProfile,
        cancelled: AtomicBoolean,
        onProgress: (Int, String) -> Unit,
    ): String? {
        val timeline = parser.parse(
            projectId = projectId,
            renderGraphJson = renderGraphJson,
            fallbackDurationMicros = durationMicros
        )

        if (!timeline.hasAudio) {
            return null
        }

        onProgress(3, "Audio timeline resolved")

        val mixed = mixer.mix(
            timeline = timeline,
            profile = profile,
            cancelled = cancelled,
            onProgress = onProgress
        )

        return encoder.encodeToM4a(
            pcm = mixed,
            outputPath = outputM4aPath,
            profile = profile,
            cancelled = cancelled,
            onProgress = onProgress
        )
    }
}
