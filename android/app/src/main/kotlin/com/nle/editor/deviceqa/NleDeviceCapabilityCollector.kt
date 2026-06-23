package com.nle.editor.deviceqa

import android.content.Context

class NleDeviceCapabilityCollector(
    private val context: Context,
) {
    private val deviceInfoCollector    = NleDeviceInfoCollector(context)
    private val codecCollector         = NleCodecCapabilityCollector()
    private val eglCollector           = NleEglCapabilityCollector()
    private val thermalCollector       = NleThermalStatusCollector(context)
    private val recommendationEngine   = NleDeviceRecommendationEngine()

    fun collect(): NleDeviceCapabilityReport {
        val basic    = deviceInfoCollector.collectBasicInfo()
        val codec    = codecCollector.collect()
        val egl      = eglCollector.collect()
        val thermal  = thermalCollector.collect()
        val recommendation = recommendationEngine.recommend(
            basic   = basic,
            codec   = codec,
            egl     = egl,
            thermal = thermal,
        )

        return NleDeviceCapabilityReport(
            generatedAtMs     = System.currentTimeMillis(),
            manufacturer      = basic.manufacturer,
            brand             = basic.brand,
            model             = basic.model,
            device            = basic.device,
            hardware          = basic.hardware,
            androidSdk        = basic.androidSdk,
            androidRelease    = basic.androidRelease,
            supportedAbis     = basic.supportedAbis,
            totalMemoryMb     = basic.totalMemoryMb,
            availableMemoryMb = basic.availableMemoryMb,
            maxMemoryMb       = basic.maxMemoryMb,
            cpuCoreCount      = basic.cpuCoreCount,
            deviceTier        = basic.deviceTier,
            codecReport       = codec,
            eglReport         = egl,
            thermalReport     = thermal,
            recommendation    = recommendation,
        )
    }
}
