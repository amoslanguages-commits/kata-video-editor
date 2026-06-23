package com.nle.editor.deviceqa

import android.content.Context
import android.os.Build
import android.os.PowerManager

class NleThermalStatusCollector(
    private val context: Context,
) {
    fun collect(): NleThermalStatusReport {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return NleThermalStatusReport(
                thermalApiAvailable  = false,
                currentStatus        = "unavailable",
                shouldThrottlePreview = false,
                shouldBlockLongExport = false,
            )
        }

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val status       = powerManager.currentThermalStatus

        val statusName = when (status) {
            PowerManager.THERMAL_STATUS_NONE      -> "none"
            PowerManager.THERMAL_STATUS_LIGHT     -> "light"
            PowerManager.THERMAL_STATUS_MODERATE  -> "moderate"
            PowerManager.THERMAL_STATUS_SEVERE    -> "severe"
            PowerManager.THERMAL_STATUS_CRITICAL  -> "critical"
            PowerManager.THERMAL_STATUS_EMERGENCY -> "emergency"
            PowerManager.THERMAL_STATUS_SHUTDOWN  -> "shutdown"
            else                                  -> "unknown"
        }

        return NleThermalStatusReport(
            thermalApiAvailable   = true,
            currentStatus         = statusName,
            shouldThrottlePreview = status >= PowerManager.THERMAL_STATUS_MODERATE,
            shouldBlockLongExport = status >= PowerManager.THERMAL_STATUS_SEVERE,
        )
    }
}
