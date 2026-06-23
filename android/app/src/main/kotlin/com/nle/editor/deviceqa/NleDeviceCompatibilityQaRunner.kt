package com.nle.editor.deviceqa

import android.content.Context

class NleDeviceCompatibilityQaRunner(context: Context) {

    private val capabilityCollector = NleDeviceCapabilityCollector(context)

    fun run(): NleDeviceQaReport {
        val capability = capabilityCollector.collect()
        val issues     = mutableListOf<NleDeviceQaIssue>()

        checkAndroidVersion(capability, issues)
        checkCodecSupport(capability, issues)
        checkEglSupport(capability, issues)
        checkMemory(capability, issues)
        checkThermal(capability, issues)
        checkRecommendations(capability, issues)

        val passCount    = issues.count { it.severity == NleDeviceQaSeverity.PASS }
        val warningCount = issues.count { it.severity == NleDeviceQaSeverity.WARNING }
        val failCount    = issues.count { it.severity == NleDeviceQaSeverity.FAIL }

        return NleDeviceQaReport(
            generatedAtMs    = System.currentTimeMillis(),
            passed           = failCount == 0,
            passCount        = passCount,
            warningCount     = warningCount,
            failCount        = failCount,
            capabilityReport = capability,
            issues           = issues,
        )
    }

    // ── Check methods ─────────────────────────────────────────────────────────

    private fun checkAndroidVersion(r: NleDeviceCapabilityReport, out: MutableList<NleDeviceQaIssue>) {
        if (r.androidSdk < 26) {
            out.fail("android.version", "Android 8.0+ is required.", mapOf("sdk" to r.androidSdk))
        } else {
            out.pass("android.version", "Android version is supported.", mapOf("sdk" to r.androidSdk, "release" to r.androidRelease))
        }
    }

    private fun checkCodecSupport(r: NleDeviceCapabilityReport, out: MutableList<NleDeviceQaIssue>) {
        val codec = r.codecReport

        if (codec.hasH264Decoder) out.pass("codec.h264.decoder", "H.264 decoder is available.")
        else                       out.fail("codec.h264.decoder", "H.264 decoder is missing.")

        if (codec.hasH264Encoder) out.pass("codec.h264.encoder", "H.264 encoder is available.")
        else                       out.fail("codec.h264.encoder", "H.264 encoder is missing. MP4 export cannot run safely.")

        if (codec.hasAacDecoder) out.pass("codec.aac.decoder", "AAC decoder is available.")
        else                      out.warning("codec.aac.decoder", "AAC decoder not detected. Some audio files may fail.")

        if (codec.hasAacEncoder) out.pass("codec.aac.encoder", "AAC encoder is available.")
        else                      out.fail("codec.aac.encoder", "AAC encoder is missing. Audio export cannot run safely.")

        if (codec.supports1080pExport) {
            out.pass("codec.1080p", "1080p export is supported.")
        } else {
            out.warning("codec.1080p", "1080p export support is not guaranteed.", mapOf("maxW" to codec.maxH264EncodeWidth, "maxH" to codec.maxH264EncodeHeight))
        }

        if (codec.supports4kExport) out.pass("codec.4k", "4K export appears supported.")
        else                         out.warning("codec.4k", "4K export is not supported on this device.")
    }

    private fun checkEglSupport(r: NleDeviceCapabilityReport, out: MutableList<NleDeviceQaIssue>) {
        val egl = r.eglReport

        if (egl.eglAvailable) {
            out.pass("egl.available", "EGL is available.", mapOf("glesVersion" to egl.glesVersion, "renderer" to egl.glRenderer))
        } else {
            out.fail("egl.available", "EGL is unavailable. GPU preview/export cannot run.")
        }

        if (egl.maxTextureSize >= 2048) {
            out.pass("egl.maxTexture", "Max texture size is acceptable.", mapOf("maxTextureSize" to egl.maxTextureSize))
        } else {
            out.warning("egl.maxTexture", "Max texture size is low. Large content may need downscaling.", mapOf("maxTextureSize" to egl.maxTextureSize))
        }

        if (egl.supportsFramebufferObject) out.pass("egl.fbo", "Framebuffer support is available.")
        else                                out.fail("egl.fbo", "Framebuffer objects are not available.")
    }

    private fun checkMemory(r: NleDeviceCapabilityReport, out: MutableList<NleDeviceQaIssue>) {
        when {
            r.totalMemoryMb < 2048 -> out.fail("memory.total",    "Device memory is too low for stable video editing.",      mapOf("totalMemoryMb" to r.totalMemoryMb))
            r.totalMemoryMb < 4096 -> out.warning("memory.total", "Device memory is low. Use proxy preview and limit export.", mapOf("totalMemoryMb" to r.totalMemoryMb))
            else                   -> out.pass("memory.total",    "Device memory is acceptable.",                            mapOf("totalMemoryMb" to r.totalMemoryMb))
        }

        if (r.availableMemoryMb < 512) {
            out.warning("memory.available", "Available memory is low. Preview/export may fail.", mapOf("availableMemoryMb" to r.availableMemoryMb))
        } else {
            out.pass("memory.available", "Available memory is acceptable.", mapOf("availableMemoryMb" to r.availableMemoryMb))
        }
    }

    private fun checkThermal(r: NleDeviceCapabilityReport, out: MutableList<NleDeviceQaIssue>) {
        val t = r.thermalReport
        when {
            t.shouldBlockLongExport  -> out.fail("thermal.export",    "Thermal status is severe. Long export should be blocked.", mapOf("status" to t.currentStatus))
            t.shouldThrottlePreview  -> out.warning("thermal.preview", "Thermal status suggests preview should be throttled.",     mapOf("status" to t.currentStatus))
            else                     -> out.pass("thermal.status",    "Thermal status is acceptable.",                           mapOf("status" to t.currentStatus))
        }
    }

    private fun checkRecommendations(r: NleDeviceCapabilityReport, out: MutableList<NleDeviceQaIssue>) {
        val rec = r.recommendation
        out.pass("recommendation.preview", "Preview quality: ${rec.previewQuality}.", mapOf("previewQuality" to rec.previewQuality, "preferProxy" to rec.preferProxyPreview))
        out.pass("recommendation.export",  "Max export: ${rec.maxExportWidth}x${rec.maxExportHeight} @ ${rec.maxFrameRate}fps.",
            mapOf("maxExportWidth" to rec.maxExportWidth, "maxExportHeight" to rec.maxExportHeight, "maxFrameRate" to rec.maxFrameRate, "allow4k" to rec.allow4kExport))
    }
}

// ── List extension helpers ────────────────────────────────────────────────────

private fun MutableList<NleDeviceQaIssue>.pass(id: String, message: String, details: Map<String, Any?> = emptyMap()) =
    add(NleDeviceQaIssue(id = id, severity = NleDeviceQaSeverity.PASS, message = message, details = details))

private fun MutableList<NleDeviceQaIssue>.warning(id: String, message: String, details: Map<String, Any?> = emptyMap()) =
    add(NleDeviceQaIssue(id = id, severity = NleDeviceQaSeverity.WARNING, message = message, details = details))

private fun MutableList<NleDeviceQaIssue>.fail(id: String, message: String, details: Map<String, Any?> = emptyMap()) =
    add(NleDeviceQaIssue(id = id, severity = NleDeviceQaSeverity.FAIL, message = message, details = details))
