package com.kata.videoeditor.nle

import android.app.ActivityManager
import android.content.Context
import android.media.MediaCodecList
import android.os.Build

/**
 * Probes hardware capabilities using only public Android APIs.
 *
 * This is a V1 placeholder — GPU / HDR / 10-bit detection
 * will be filled in when the real media pipeline is connected.
 */
class NleDeviceCapabilityProbe(private val context: Context) {

    fun probe(): Map<String, Any?> {
        val am            = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val cpuCores      = Runtime.getRuntime().availableProcessors()
        val memClassMb    = am?.memoryClass
        val largeMemClassMb = am?.largeMemoryClass

        val tier = estimateTier(cpuCores, largeMemClassMb ?: memClassMb)

        return mapOf(
            "source"              to "android_native_v1",
            "manufacturer"        to Build.MANUFACTURER,
            "model"               to Build.MODEL,
            "device"              to Build.DEVICE,
            "brand"               to Build.BRAND,
            "sdkInt"              to Build.VERSION.SDK_INT,
            "release"             to Build.VERSION.RELEASE,
            "cpuCores"            to cpuCores,
            "memoryClassMb"       to memClassMb,
            "largeMemoryClassMb"  to largeMemClassMb,
            "tier"                to tier,
            "codecSupport"        to mapOf(
                "h264Decode"   to hasDecoder("video/avc"),
                "h264Encode"   to hasEncoder("video/avc"),
                "hevcDecode"   to hasDecoder("video/hevc"),
                "hevcEncode"   to hasEncoder("video/hevc"),
                "tenBitDecode" to false,
                "tenBitEncode" to false,
                "hdrPreview"   to false,
                "hdrExport"    to false
            ),
            "limits"              to limitsForTier(tier)
        )
    }

    // ── Tier estimation ──────────────────────────────────────────────────────

    private fun estimateTier(cores: Int, memMb: Int?): String {
        val mem = memMb ?: 0
        return when {
            cores <= 4 || mem in 1..192  -> "low_end"
            cores <= 6 || mem in 193..256 -> "mid_range"
            cores <= 8 || mem in 257..384 -> "high_end"
            else                          -> "flagship"
        }
    }

    private fun limitsForTier(tier: String): Map<String, Any?> = when (tier) {
        "low_end"  -> mapOf(
            "safePreviewHeight"       to 540,
            "recommendedProxyHeight"  to 540,
            "maxExportHeight"         to 1080,
            "maxExportFrameRate"      to 30,
            "maxRealtimeVideoTracks"  to 1,
            "maxRealtimeAudioTracks"  to 2,
            "allow4kExport"           to false
        )
        "mid_range" -> mapOf(
            "safePreviewHeight"       to 720,
            "recommendedProxyHeight"  to 720,
            "maxExportHeight"         to 1080,
            "maxExportFrameRate"      to 60,
            "maxRealtimeVideoTracks"  to 2,
            "maxRealtimeAudioTracks"  to 4,
            "allow4kExport"           to false
        )
        "high_end" -> mapOf(
            "safePreviewHeight"       to 1080,
            "recommendedProxyHeight"  to 960,
            "maxExportHeight"         to 2160,
            "maxExportFrameRate"      to 60,
            "maxRealtimeVideoTracks"  to 3,
            "maxRealtimeAudioTracks"  to 6,
            "allow4kExport"           to true
        )
        else -> mapOf(
            "safePreviewHeight"       to 1080,
            "recommendedProxyHeight"  to 1080,
            "maxExportHeight"         to 2160,
            "maxExportFrameRate"      to 60,
            "maxRealtimeVideoTracks"  to 4,
            "maxRealtimeAudioTracks"  to 8,
            "allow4kExport"           to true
        )
    }

    // ── Codec helpers ────────────────────────────────────────────────────────

    private fun hasEncoder(mime: String) = hasCodec(mime, encoder = true)
    private fun hasDecoder(mime: String) = hasCodec(mime, encoder = false)

    private fun hasCodec(mime: String, encoder: Boolean): Boolean = try {
        MediaCodecList(MediaCodecList.ALL_CODECS).codecInfos.any { info ->
            info.isEncoder == encoder &&
                info.supportedTypes.any { it.equals(mime, ignoreCase = true) }
        }
    } catch (_: Throwable) { false }
}
