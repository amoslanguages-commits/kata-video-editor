package com.nle.editor.sync

/**
 * Detects cumulative audio/video drift over a session.
 *
 * For each rendered frame, call [recordSample] with the current video
 * presentation time and the corresponding audio playback time.
 * Call [validate] at the end to get a [NleDriftReport].
 */
class NleAudioVideoDriftDetector {

    data class DriftSample(
        val index: Int,
        val videoPtsUs: Long,
        val audioPtsUs: Long,
        val driftUs: Long,
    )

    private val samples = mutableListOf<DriftSample>()

    fun recordSample(
        index: Int,
        videoPtsUs: Long,
        audioPtsUs: Long,
    ) {
        val drift = videoPtsUs - audioPtsUs
        samples.add(
            DriftSample(
                index      = index,
                videoPtsUs = videoPtsUs,
                audioPtsUs = audioPtsUs,
                driftUs    = drift,
            )
        )
    }

    fun validate(): NleDriftReport {
        val issues = mutableListOf<NleSyncIssue>()

        if (samples.isEmpty()) {
            return NleDriftReport(
                sampleCount        = 0,
                cumulativeDriftUs  = 0L,
                maxInstantDriftUs  = 0L,
                passed             = true,
                issues             = emptyList(),
            )
        }

        val cumulativeDriftUs = samples.sumOf { kotlin.math.abs(it.driftUs) }
        val maxInstantDriftUs = samples.maxOf { kotlin.math.abs(it.driftUs) }

        if (cumulativeDriftUs > NleSyncThresholds.MAX_CUMULATIVE_DRIFT_US) {
            issues.add(
                NleSyncIssue(
                    id      = "drift.cumulative",
                    message = "Cumulative A/V drift ${cumulativeDriftUs}µs exceeds " +
                              "${NleSyncThresholds.MAX_CUMULATIVE_DRIFT_US}µs threshold.",
                )
            )
        }

        val problematicSamples = samples.filter {
            kotlin.math.abs(it.driftUs) > NleSyncThresholds.MAX_START_SYNC_US
        }

        for (sample in problematicSamples.take(5)) {
            issues.add(
                NleSyncIssue(
                    id      = "drift.sample.${sample.index}",
                    message = "A/V drift of ${sample.driftUs}µs at sample ${sample.index} " +
                              "(video=${sample.videoPtsUs}µs audio=${sample.audioPtsUs}µs).",
                    severity = "warning",
                )
            )
        }

        return NleDriftReport(
            sampleCount       = samples.size,
            cumulativeDriftUs = cumulativeDriftUs,
            maxInstantDriftUs = maxInstantDriftUs,
            passed            = issues.none { it.severity == "fail" },
            issues            = issues,
        )
    }

    fun clear() = samples.clear()
}

data class NleDriftReport(
    val sampleCount: Int,
    val cumulativeDriftUs: Long,
    val maxInstantDriftUs: Long,
    val passed: Boolean,
    val issues: List<NleSyncIssue>,
)
