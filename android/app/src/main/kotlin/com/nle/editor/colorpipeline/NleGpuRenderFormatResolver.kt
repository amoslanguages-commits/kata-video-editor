package com.nle.editor.colorpipeline

import com.nle.editor.color.NleColorPipelineQuality
import com.nle.editor.color.NleDeviceColorCapability
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_FLOAT
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_HALF_FLOAT
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_RGBA
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_RGBA16F
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_RGBA32F
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_RGBA8
import com.nle.editor.colorpipeline.NleGlFormatConstants.GL_UNSIGNED_BYTE

class NleGpuRenderFormatResolver {

    fun resolve(
        requestedQuality: NleColorPipelineQuality,
        capability: NleDeviceColorCapability,
        width: Int,
        height: Int,
        mode: NleGpuPipelineMode,
    ): NleColorPipelineResolvedConfig {
        val safeWidth = width.coerceAtLeast(2)
        val safeHeight = height.coerceAtLeast(2)

        val requested = when (requestedQuality) {
            NleColorPipelineQuality.HIGH_PRECISION_32F -> NleGpuRenderFormat.RGBA32F
            NleColorPipelineQuality.STANDARD_16F -> NleGpuRenderFormat.RGBA16F
            NleColorPipelineQuality.COMPATIBILITY_8BIT -> NleGpuRenderFormat.RGBA8
            NleColorPipelineQuality.AUTO -> {
                when {
                    capability.supportsFloatRenderTarget -> NleGpuRenderFormat.RGBA32F
                    capability.supportsHalfFloatRenderTarget -> NleGpuRenderFormat.RGBA16F
                    else -> NleGpuRenderFormat.RGBA8
                }
            }
        }

        val resolved = when (requested) {
            NleGpuRenderFormat.RGBA32F -> {
                if (capability.supportsFloatRenderTarget) {
                    NleGpuRenderFormat.RGBA32F to null
                } else if (capability.supportsHalfFloatRenderTarget) {
                    NleGpuRenderFormat.RGBA16F to "RGBA32F not supported. Falling back to RGBA16F."
                } else {
                    NleGpuRenderFormat.RGBA8 to "Floating-point render targets not supported. Falling back to RGBA8."
                }
            }

            NleGpuRenderFormat.RGBA16F -> {
                if (capability.supportsHalfFloatRenderTarget) {
                    NleGpuRenderFormat.RGBA16F to null
                } else {
                    NleGpuRenderFormat.RGBA8 to "RGBA16F not supported. Falling back to RGBA8."
                }
            }

            NleGpuRenderFormat.RGBA8 -> {
                NleGpuRenderFormat.RGBA8 to null
            }
        }

        val precision = when (resolved.first) {
            NleGpuRenderFormat.RGBA32F -> NleColorPassPrecision.FULL_FLOAT_32F
            NleGpuRenderFormat.RGBA16F -> NleColorPassPrecision.HALF_FLOAT_16F
            NleGpuRenderFormat.RGBA8 -> NleColorPassPrecision.COMPATIBILITY_8BIT
        }

        return NleColorPipelineResolvedConfig(
            mode = mode,
            workingFormat = resolved.first,
            precision = precision,
            width = safeWidth,
            height = safeHeight,
            usePingPong = true,
            enableDither = resolved.first == NleGpuRenderFormat.RGBA8,
            enableBandingProtection = true,
            fallbackReason = resolved.second,
        )
    }

    fun formatInfo(format: NleGpuRenderFormat): NleGpuRenderFormatInfo {
        return when (format) {
            NleGpuRenderFormat.RGBA8 -> NleGpuRenderFormatInfo(
                format = format,
                internalFormat = GL_RGBA8,
                formatEnum = GL_RGBA,
                typeEnum = GL_UNSIGNED_BYTE,
                precision = NleColorPassPrecision.COMPATIBILITY_8BIT,
                supportsLinearFiltering = true,
                description = "8-bit RGBA fallback",
            )

            NleGpuRenderFormat.RGBA16F -> NleGpuRenderFormatInfo(
                format = format,
                internalFormat = GL_RGBA16F,
                formatEnum = GL_RGBA,
                typeEnum = GL_HALF_FLOAT,
                precision = NleColorPassPrecision.HALF_FLOAT_16F,
                supportsLinearFiltering = true,
                description = "16-bit half-float RGBA working buffer",
            )

            NleGpuRenderFormat.RGBA32F -> NleGpuRenderFormatInfo(
                format = format,
                internalFormat = GL_RGBA32F,
                formatEnum = GL_RGBA,
                typeEnum = GL_FLOAT,
                precision = NleColorPassPrecision.FULL_FLOAT_32F,
                supportsLinearFiltering = false,
                description = "32-bit float RGBA high precision working buffer",
            )
        }
    }
}
