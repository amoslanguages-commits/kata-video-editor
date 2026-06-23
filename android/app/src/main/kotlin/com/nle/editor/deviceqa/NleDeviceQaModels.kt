package com.nle.editor.deviceqa

enum class NleDeviceTier {
    LOW_END,
    MID_RANGE,
    HIGH_END,
    UNKNOWN,
}

enum class NleDeviceQaSeverity {
    PASS,
    WARNING,
    FAIL,
}

data class NleDeviceCapabilityReport(
    val generatedAtMs: Long,
    val manufacturer: String,
    val brand: String,
    val model: String,
    val device: String,
    val hardware: String,
    val androidSdk: Int,
    val androidRelease: String,
    val supportedAbis: List<String>,
    val totalMemoryMb: Long,
    val availableMemoryMb: Long,
    val maxMemoryMb: Long,
    val cpuCoreCount: Int,
    val deviceTier: NleDeviceTier,
    val codecReport: NleCodecCapabilityReport,
    val eglReport: NleEglCapabilityReport,
    val thermalReport: NleThermalStatusReport,
    val recommendation: NleDeviceRecommendation,
)

data class NleCodecCapabilityReport(
    val hasH264Decoder: Boolean,
    val hasH264Encoder: Boolean,
    val hasHevcDecoder: Boolean,
    val hasHevcEncoder: Boolean,
    val hasAacDecoder: Boolean,
    val hasAacEncoder: Boolean,
    val maxH264EncodeWidth: Int,
    val maxH264EncodeHeight: Int,
    val supports1080pExport: Boolean,
    val supports4kExport: Boolean,
    val decoderNames: List<String>,
    val encoderNames: List<String>,
)

data class NleEglCapabilityReport(
    val eglAvailable: Boolean,
    val glesVersion: String,
    val glRenderer: String,
    val glVendor: String,
    val maxTextureSize: Int,
    val supportsExternalOes: Boolean,
    val supportsFramebufferObject: Boolean,
)

data class NleThermalStatusReport(
    val thermalApiAvailable: Boolean,
    val currentStatus: String,
    val shouldThrottlePreview: Boolean,
    val shouldBlockLongExport: Boolean,
)

data class NleDeviceRecommendation(
    val previewQuality: String,
    val maxExportWidth: Int,
    val maxExportHeight: Int,
    val maxFrameRate: Double,
    val preferProxyPreview: Boolean,
    val requireProxyFor4k: Boolean,
    val allow4kExport: Boolean,
    val notes: List<String>,
)

data class NleDeviceQaIssue(
    val id: String,
    val severity: NleDeviceQaSeverity,
    val message: String,
    val details: Map<String, Any?> = emptyMap(),
)

data class NleDeviceQaReport(
    val generatedAtMs: Long,
    val passed: Boolean,
    val passCount: Int,
    val warningCount: Int,
    val failCount: Int,
    val capabilityReport: NleDeviceCapabilityReport,
    val issues: List<NleDeviceQaIssue>,
)
