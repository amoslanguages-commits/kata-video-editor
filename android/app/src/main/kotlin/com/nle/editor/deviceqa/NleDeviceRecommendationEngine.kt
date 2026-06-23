package com.nle.editor.deviceqa

class NleDeviceRecommendationEngine {

    fun recommend(
        basic:   NleDeviceInfoCollector.BasicDeviceInfo,
        codec:   NleCodecCapabilityReport,
        egl:     NleEglCapabilityReport,
        thermal: NleThermalStatusReport,
    ): NleDeviceRecommendation {
        val notes = mutableListOf<String>()

        val previewQuality = when (basic.deviceTier) {
            NleDeviceTier.LOW_END  -> { notes.add("Use performance preview on low-end device."); "performance" }
            NleDeviceTier.MID_RANGE -> { notes.add("Use balanced preview on mid-range device."); "balanced" }
            NleDeviceTier.HIGH_END  -> { notes.add("Use quality preview on high-end device.");   "quality"     }
            NleDeviceTier.UNKNOWN   -> { notes.add("Unknown device tier. Use auto preview.");      "auto"        }
        }

        val maxExportWidth: Int
        val maxExportHeight: Int
        val maxFrameRate: Double

        when (basic.deviceTier) {
            NleDeviceTier.LOW_END -> {
                maxExportWidth  = 720
                maxExportHeight = 1280
                maxFrameRate    = 30.0
            }
            NleDeviceTier.MID_RANGE -> {
                maxExportWidth  = 1080
                maxExportHeight = 1920
                maxFrameRate    = 30.0
            }
            NleDeviceTier.HIGH_END -> {
                maxExportWidth  = if (codec.supports4kExport) 2160 else 1080
                maxExportHeight = if (codec.supports4kExport) 3840 else 1920
                maxFrameRate    = 60.0
            }
            NleDeviceTier.UNKNOWN -> {
                maxExportWidth  = 1080
                maxExportHeight = 1920
                maxFrameRate    = 30.0
            }
        }

        if (!codec.supports1080pExport) notes.add("Device codec does not clearly support 1080p export.")
        if (!codec.hasH264Encoder)       notes.add("H.264 encoder missing. Export must be blocked or fallback.")
        if (!codec.hasAacEncoder)        notes.add("AAC encoder missing. Audio export must fallback or be blocked.")
        if (!egl.eglAvailable)           notes.add("EGL unavailable. GPU compositor cannot run.")
        if (thermal.shouldThrottlePreview) notes.add("Thermal state suggests preview should be throttled.")
        if (thermal.shouldBlockLongExport) notes.add("Thermal state severe. Long export should be blocked.")

        return NleDeviceRecommendation(
            previewQuality    = previewQuality,
            maxExportWidth    = maxExportWidth,
            maxExportHeight   = maxExportHeight,
            maxFrameRate      = maxFrameRate,
            preferProxyPreview = true,
            requireProxyFor4k = basic.deviceTier != NleDeviceTier.HIGH_END,
            allow4kExport     = basic.deviceTier == NleDeviceTier.HIGH_END &&
                                codec.supports4kExport &&
                                !thermal.shouldBlockLongExport,
            notes             = notes,
        )
    }
}
