package com.nle.editor.deviceqa

data class NleExportRecoverySuggestion(
    val canRetry: Boolean,
    val retryWithProxy: Boolean,
    val retryWidth: Int,
    val retryHeight: Int,
    val retryFrameRate: Double,
    val disable4k: Boolean,
    val message: String,
)

/**
 * Suggests safe retry settings after an export failure.
 *
 * Inspects the failure message and current device thermal/capability state
 * to produce a [NleExportRecoverySuggestion].
 */
class NleExportRecoveryPolicy {

    fun suggest(
        report: NleDeviceCapabilityReport,
        failureMessage: String,
    ): NleExportRecoverySuggestion {
        val lower = failureMessage.lowercase()

        val memoryFailure = lower.contains("memory")  ||
                            lower.contains("oom")      ||
                            lower.contains("outofmemory")

        val codecFailure  = lower.contains("codec")   ||
                            lower.contains("encoder")  ||
                            lower.contains("configure")

        val thermalFailure = report.thermalReport.shouldBlockLongExport

        if (thermalFailure) {
            return NleExportRecoverySuggestion(
                canRetry       = false,
                retryWithProxy = true,
                retryWidth     = report.recommendation.maxExportWidth,
                retryHeight    = report.recommendation.maxExportHeight,
                retryFrameRate = report.recommendation.maxFrameRate,
                disable4k      = true,
                message        = "Device is too hot. Wait before retrying export.",
            )
        }

        if (memoryFailure) {
            return NleExportRecoverySuggestion(
                canRetry       = true,
                retryWithProxy = true,
                retryWidth     = 720,
                retryHeight    = 1280,
                retryFrameRate = 30.0,
                disable4k      = true,
                message        = "Retry with proxy media and 720p export.",
            )
        }

        if (codecFailure) {
            return NleExportRecoverySuggestion(
                canRetry       = true,
                retryWithProxy = true,
                retryWidth     = 1080.coerceAtMost(report.recommendation.maxExportWidth),
                retryHeight    = 1920.coerceAtMost(report.recommendation.maxExportHeight),
                retryFrameRate = 30.0.coerceAtMost(report.recommendation.maxFrameRate),
                disable4k      = true,
                message        = "Retry with safer H.264 1080p/30 settings.",
            )
        }

        return NleExportRecoverySuggestion(
            canRetry       = true,
            retryWithProxy = true,
            retryWidth     = report.recommendation.maxExportWidth,
            retryHeight    = report.recommendation.maxExportHeight,
            retryFrameRate = report.recommendation.maxFrameRate,
            disable4k      = !report.recommendation.allow4kExport,
            message        = "Retry with recommended device-safe settings.",
        )
    }
}
