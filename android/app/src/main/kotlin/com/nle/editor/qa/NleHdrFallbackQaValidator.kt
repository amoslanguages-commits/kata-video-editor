package com.nle.editor.qa

import com.nle.editor.hdr.NleHdrOutputScanner
import com.nle.editor.hdr.NleHdrOutputSettings
import com.nle.editor.hdr.NleOutputColorMode
import android.content.Context

class NleHdrFallbackQaValidator(private val context: Context) {

    fun validateFallback(settings: NleHdrOutputSettings): List<NleColorQaIssue> {
        val issues = mutableListOf<NleColorQaIssue>()
        val scanner = NleHdrOutputScanner(context)
        val capability = scanner.scanCapability()
        val validation = scanner.validateExport(settings)

        // If the settings are not safe for the device, we check if the suggested settings fallback correctly.
        if (!validation.isHdrSafe) {
            val suggestedMode = validation.suggestedColorMode

            if (suggestedMode != NleOutputColorMode.rec709Sdr && suggestedMode != NleOutputColorMode.displayP3Sdr) {
                issues.add(
                    NleColorQaIssue(
                        id = "HDR_FALLBACK_UNSAFE_SUGGESTION",
                        severity = NleColorQaSeverity.RELEASE_BLOCKER,
                        area = NleColorQaArea.HDR_OUTPUT,
                        title = "Unsafe HDR fallback suggestion",
                        message = "Device lacks HDR encoder capability, but suggested fallback is still HDR/WCG: $suggestedMode.",
                        suggestedFix = "Force default fallback to Rec.709 SDR or Display P3 SDR."
                    )
                )
            }

            // Raise warning about fallback activation
            issues.add(
                NleColorQaIssue(
                    id = "HDR_FALLBACK_ACTIVE",
                    severity = NleColorQaSeverity.WARNING,
                    area = NleColorQaArea.DEVICE_FALLBACK,
                    title = "HDR fallback active for export",
                    message = "Target output mode (${settings.colorMode}) is unsupported. Falling back to $suggestedMode.",
                    suggestedFix = "Adjust export parameters to Rec.709 SDR for maximum compatibility."
                )
            )
        }

        // Validate baseline: Rec.709 SDR must ALWAYS be safe on all hardware configurations.
        if (settings.colorMode == NleOutputColorMode.rec709Sdr && !validation.isHdrSafe) {
            issues.add(
                NleColorQaIssue(
                    id = "HDR_BASELINE_UNSAFE",
                    severity = NleColorQaSeverity.RELEASE_BLOCKER,
                    area = NleColorQaArea.DEVICE_FALLBACK,
                    title = "Rec.709 SDR baseline is unsafe",
                    message = "Even Rec.709 SDR mode was flagged as unsafe on this device. This is a critical blocker.",
                    suggestedFix = "Check GLES20 compatibility settings and default format fallback configurations."
                )
            )
        }

        return issues
    }
}
