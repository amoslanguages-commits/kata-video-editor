package com.nle.editor.hdr

import android.app.Activity
import android.content.Context
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import com.nle.editor.color.NleDeviceColorCapabilityScanner

class NleHdrOutputScanner(private val context: Context) {

    fun scanCapability(): NleHdrDeviceCapability {
        val baseScanner = NleDeviceColorCapabilityScanner(context)
        val baseCapability = baseScanner.scan()

        var displayMaxNits = 300.0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as? android.hardware.display.DisplayManager
                displayManager?.getDisplay(android.view.Display.DEFAULT_DISPLAY)
            } else {
                (context as? Activity)?.windowManager?.defaultDisplay
            }
            val hdrCapabilities = display?.hdrCapabilities
            if (hdrCapabilities != null) {
                val maxLuminance = hdrCapabilities.desiredMaxLuminance
                if (maxLuminance > 0f) {
                    displayMaxNits = maxLuminance.toDouble()
                } else if (baseCapability.supportsHdrPreview) {
                    displayMaxNits = 1000.0
                }
            }
        }

        var encoderSupportsHdrHlg = false
        var encoderSupportsHdrPq = false
        var encoderSupportsWideColorP3 = false
        var encoderSupportsTenBit = false

        try {
            val codecList = MediaCodecList(MediaCodecList.ALL_CODECS)
            val codecInfos = codecList.codecInfos
            for (info in codecInfos) {
                if (!info.isEncoder) continue
                val types = info.supportedTypes
                for (type in types) {
                    if (type.equals(MediaFormat.MIMETYPE_VIDEO_HEVC, ignoreCase = true) ||
                        type.equals("video/hevc", ignoreCase = true)) {
                        encoderSupportsWideColorP3 = true
                        val capabilities = info.getCapabilitiesForType(type)
                        for (profilePair in capabilities.profileLevels) {
                            if (profilePair.profile == MediaCodecInfo.CodecProfileLevel.HEVCProfileMain10) {
                                encoderSupportsTenBit = true
                                encoderSupportsHdrHlg = true
                                encoderSupportsHdrPq = true
                            }
                        }
                    }
                    if (type.equals(MediaFormat.MIMETYPE_VIDEO_AVC, ignoreCase = true) ||
                        type.equals("video/avc", ignoreCase = true)) {
                        val capabilities = info.getCapabilitiesForType(type)
                        for (profilePair in capabilities.profileLevels) {
                            if (profilePair.profile == MediaCodecInfo.CodecProfileLevel.AVCProfileHigh10) {
                                encoderSupportsTenBit = true
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Suppress and fallback
        }

        // Align with base capability scan results.
        if (baseCapability.supportsHdrExport) {
            encoderSupportsHdrHlg = true
            encoderSupportsHdrPq = true
            encoderSupportsTenBit = true
            encoderSupportsWideColorP3 = true
        }

        return NleHdrDeviceCapability(
            displaySupportsHdr = baseCapability.supportsHdrPreview,
            displaySupportsWideColor = baseCapability.supportsWideColorPreview,
            displayMaxNits = displayMaxNits,
            encoderSupportsHdrHlg = encoderSupportsHdrHlg,
            encoderSupportsHdrPq = encoderSupportsHdrPq,
            encoderSupportsWideColorP3 = encoderSupportsWideColorP3,
            encoderSupportsTenBit = encoderSupportsTenBit
        )
    }

    fun validateExport(settings: NleHdrOutputSettings): NleHdrExportValidation {
        val capability = scanCapability()
        val warnings = mutableListOf<String>()
        val errors = mutableListOf<String>()
        var isHdrSafe = true

        val mode = settings.colorMode

        if (mode == NleOutputColorMode.rec2020HlgHdr) {
            if (!capability.encoderSupportsHdrHlg) {
                errors.add("Encoder does not support HLG HDR export.")
                isHdrSafe = false
            }
            if (!capability.encoderSupportsTenBit) {
                errors.add("HLG HDR requires 10-bit encoding, which is not supported by this device.")
                isHdrSafe = false
            }
            if (!capability.displaySupportsHdr) {
                warnings.add("Display does not support HDR preview; editing will occur in simulated SDR mode.")
            }
        } else if (mode == NleOutputColorMode.rec2020PqHdr) {
            if (!capability.encoderSupportsHdrPq) {
                errors.add("Encoder does not support PQ HDR export.")
                isHdrSafe = false
            }
            if (!capability.encoderSupportsTenBit) {
                errors.add("PQ HDR requires 10-bit encoding, which is not supported by this device.")
                isHdrSafe = false
            }
            if (!capability.displaySupportsHdr) {
                warnings.add("Display does not support HDR preview; editing will occur in simulated SDR mode.")
            }
        } else if (mode == NleOutputColorMode.displayP3Sdr) {
            if (!capability.encoderSupportsWideColorP3) {
                errors.add("Encoder does not support Display P3 wide color gamut tagging.")
                isHdrSafe = false
            }
            if (!capability.displaySupportsWideColor) {
                warnings.add("Display does not support Wide Color Gamut preview.")
            }
        }

        var suggestedColorMode = settings.colorMode
        var suggestedBitDepth = settings.bitDepth
        var suggestedTransferFunction = settings.transferFunction

        if (!isHdrSafe) {
            if (capability.displaySupportsWideColor && capability.encoderSupportsWideColorP3) {
                suggestedColorMode = NleOutputColorMode.displayP3Sdr
                suggestedBitDepth = NleOutputBitDepth.eightBit
                suggestedTransferFunction = NleHdrTransferFunction.sdr
            } else {
                suggestedColorMode = NleOutputColorMode.rec709Sdr
                suggestedBitDepth = NleOutputBitDepth.eightBit
                suggestedTransferFunction = NleHdrTransferFunction.sdr
            }
        }

        return NleHdrExportValidation(
            isHdrSafe = isHdrSafe,
            warnings = warnings,
            errors = errors,
            suggestedColorMode = suggestedColorMode,
            suggestedBitDepth = suggestedBitDepth,
            suggestedTransferFunction = suggestedTransferFunction
        )
    }
}
