package com.nle.editor.deviceqa

import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import kotlin.math.max

class NleCodecCapabilityCollector {

    fun collect(): NleCodecCapabilityReport {
        val codecList = MediaCodecList(MediaCodecList.ALL_CODECS)
        val codecs    = codecList.codecInfos.toList()

        val decoders = codecs.filter { !it.isEncoder }
        val encoders = codecs.filter { it.isEncoder }

        val h264Decoders = decoders.filter { it.supportsMime(MediaFormat.MIMETYPE_VIDEO_AVC) }
        val h264Encoders = encoders.filter { it.supportsMime(MediaFormat.MIMETYPE_VIDEO_AVC) }
        val hevcDecoders = decoders.filter { it.supportsMime(MediaFormat.MIMETYPE_VIDEO_HEVC) }
        val hevcEncoders = encoders.filter { it.supportsMime(MediaFormat.MIMETYPE_VIDEO_HEVC) }
        val aacDecoders  = decoders.filter { it.supportsMime(MediaFormat.MIMETYPE_AUDIO_AAC) }
        val aacEncoders  = encoders.filter { it.supportsMime(MediaFormat.MIMETYPE_AUDIO_AAC) }

        val maxH264 = maxVideoSizeForMime(h264Encoders, MediaFormat.MIMETYPE_VIDEO_AVC)

        return NleCodecCapabilityReport(
            hasH264Decoder       = h264Decoders.isNotEmpty(),
            hasH264Encoder       = h264Encoders.isNotEmpty(),
            hasHevcDecoder       = hevcDecoders.isNotEmpty(),
            hasHevcEncoder       = hevcEncoders.isNotEmpty(),
            hasAacDecoder        = aacDecoders.isNotEmpty(),
            hasAacEncoder        = aacEncoders.isNotEmpty(),
            maxH264EncodeWidth   = maxH264.first,
            maxH264EncodeHeight  = maxH264.second,
            supports1080pExport  = (maxH264.first >= 1080 && maxH264.second >= 1920) ||
                                   (maxH264.first >= 1920 && maxH264.second >= 1080),
            supports4kExport     = (maxH264.first >= 2160 && maxH264.second >= 3840) ||
                                   (maxH264.first >= 3840 && maxH264.second >= 2160),
            decoderNames         = decoders.map { it.name },
            encoderNames         = encoders.map { it.name },
        )
    }

    private fun MediaCodecInfo.supportsMime(mime: String): Boolean =
        supportedTypes.any { it.equals(mime, ignoreCase = true) }

    private fun maxVideoSizeForMime(
        codecs: List<MediaCodecInfo>,
        mime: String,
    ): Pair<Int, Int> {
        var maxWidth  = 0
        var maxHeight = 0

        for (codec in codecs) {
            try {
                val caps      = codec.getCapabilitiesForType(mime)
                val videoCaps = caps.videoCapabilities ?: continue
                maxWidth  = max(maxWidth,  videoCaps.supportedWidths.upper)
                maxHeight = max(maxHeight, videoCaps.supportedHeights.upper)
            } catch (_: Throwable) {
                // Some codecs throw on capability query — skip them safely.
            }
        }

        return maxWidth to maxHeight
    }
}
