package com.nle.editor.sync

/**
 * Validates per-sample audio timing during export.
 *
 * Call [record] for every audio sample written to the muxer.
 * Call [validate] at the end to get an [NleAudioTimingReport].
 */
class NleAudioSampleTimingValidator {

    data class SampleRecord(
        val sampleIndex: Int,
        val presentationTimeUs: Long,
        val durationUs: Long,
    )

    private val records = mutableListOf<SampleRecord>()

    fun record(
        sampleIndex: Int,
        presentationTimeUs: Long,
        durationUs: Long,
    ) {
        records.add(
            SampleRecord(
                sampleIndex        = sampleIndex,
                presentationTimeUs = presentationTimeUs,
                durationUs         = durationUs,
            )
        )
    }

    fun validate(): NleAudioTimingReport {
        val issues = mutableListOf<NleSyncIssue>()
        var gapCount = 0
        var maxGapUs = 0L

        for (i in 1 until records.size) {
            val prev    = records[i - 1]
            val current = records[i]

            val expectedNextUs = prev.presentationTimeUs + prev.durationUs
            val gapUs = kotlin.math.abs(current.presentationTimeUs - expectedNextUs)

            if (gapUs > maxGapUs) maxGapUs = gapUs

            if (gapUs > NleSyncThresholds.MAX_AUDIO_GAP_US) {
                gapCount++
                issues.add(
                    NleSyncIssue(
                        id      = "audio.sample.${current.sampleIndex}.gap",
                        message = "Audio gap of ${gapUs}µs detected at sample ${current.sampleIndex} " +
                                  "(expected ${expectedNextUs}µs, got ${current.presentationTimeUs}µs).",
                    )
                )
            }
        }

        return NleAudioTimingReport(
            totalSamples = records.size,
            gapCount     = gapCount,
            maxGapUs     = maxGapUs,
            passed       = issues.isEmpty(),
            issues       = issues,
        )
    }

    fun clear() = records.clear()
}

data class NleAudioTimingReport(
    val totalSamples: Int,
    val gapCount: Int,
    val maxGapUs: Long,
    val passed: Boolean,
    val issues: List<NleSyncIssue>,
)
