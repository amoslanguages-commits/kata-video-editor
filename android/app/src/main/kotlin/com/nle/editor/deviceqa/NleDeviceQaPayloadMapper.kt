package com.nle.editor.deviceqa

fun NleDeviceQaReport.toPayload(): Map<String, Any?> = mapOf(
    "generatedAtMs"    to generatedAtMs,
    "passed"           to passed,
    "passCount"        to passCount,
    "warningCount"     to warningCount,
    "failCount"        to failCount,
    "capabilityReport" to capabilityReport.toPayload(),
    "issues"           to issues.map { it.toPayload() },
)

fun NleDeviceCapabilityReport.toPayload(): Map<String, Any?> = mapOf(
    "generatedAtMs"     to generatedAtMs,
    "manufacturer"      to manufacturer,
    "brand"             to brand,
    "model"             to model,
    "device"            to device,
    "hardware"          to hardware,
    "androidSdk"        to androidSdk,
    "androidRelease"    to androidRelease,
    "supportedAbis"     to supportedAbis,
    "totalMemoryMb"     to totalMemoryMb,
    "availableMemoryMb" to availableMemoryMb,
    "maxMemoryMb"       to maxMemoryMb,
    "cpuCoreCount"      to cpuCoreCount,
    "deviceTier"        to deviceTier.name.lowercase(),
    "codecReport"       to codecReport.toPayload(),
    "eglReport"         to eglReport.toPayload(),
    "thermalReport"     to thermalReport.toPayload(),
    "recommendation"    to recommendation.toPayload(),
)

fun NleCodecCapabilityReport.toPayload(): Map<String, Any?> = mapOf(
    "hasH264Decoder"      to hasH264Decoder,
    "hasH264Encoder"      to hasH264Encoder,
    "hasHevcDecoder"      to hasHevcDecoder,
    "hasHevcEncoder"      to hasHevcEncoder,
    "hasAacDecoder"       to hasAacDecoder,
    "hasAacEncoder"       to hasAacEncoder,
    "maxH264EncodeWidth"  to maxH264EncodeWidth,
    "maxH264EncodeHeight" to maxH264EncodeHeight,
    "supports1080pExport" to supports1080pExport,
    "supports4kExport"    to supports4kExport,
    "decoderNames"        to decoderNames,
    "encoderNames"        to encoderNames,
)

fun NleEglCapabilityReport.toPayload(): Map<String, Any?> = mapOf(
    "eglAvailable"             to eglAvailable,
    "glesVersion"              to glesVersion,
    "glRenderer"               to glRenderer,
    "glVendor"                 to glVendor,
    "maxTextureSize"           to maxTextureSize,
    "supportsExternalOes"      to supportsExternalOes,
    "supportsFramebufferObject" to supportsFramebufferObject,
)

fun NleThermalStatusReport.toPayload(): Map<String, Any?> = mapOf(
    "thermalApiAvailable"  to thermalApiAvailable,
    "currentStatus"        to currentStatus,
    "shouldThrottlePreview" to shouldThrottlePreview,
    "shouldBlockLongExport" to shouldBlockLongExport,
)

fun NleDeviceRecommendation.toPayload(): Map<String, Any?> = mapOf(
    "previewQuality"    to previewQuality,
    "maxExportWidth"    to maxExportWidth,
    "maxExportHeight"   to maxExportHeight,
    "maxFrameRate"      to maxFrameRate,
    "preferProxyPreview" to preferProxyPreview,
    "requireProxyFor4k" to requireProxyFor4k,
    "allow4kExport"     to allow4kExport,
    "notes"             to notes,
)

fun NleDeviceQaIssue.toPayload(): Map<String, Any?> = mapOf(
    "id"       to id,
    "severity" to severity.name.lowercase(),
    "message"  to message,
    "details"  to details,
)

fun NleMemoryPressureResult.toPayload(): Map<String, Any?> = mapOf(
    "beforeAvailableMb" to beforeAvailableMb,
    "afterAvailableMb"  to afterAvailableMb,
    "allocatedMb"       to allocatedMb,
    "survived"          to survived,
    "message"           to message,
)

fun NleExportRecoverySuggestion.toPayload(): Map<String, Any?> = mapOf(
    "canRetry"       to canRetry,
    "retryWithProxy" to retryWithProxy,
    "retryWidth"     to retryWidth,
    "retryHeight"    to retryHeight,
    "retryFrameRate" to retryFrameRate,
    "disable4k"      to disable4k,
    "message"        to message,
)
