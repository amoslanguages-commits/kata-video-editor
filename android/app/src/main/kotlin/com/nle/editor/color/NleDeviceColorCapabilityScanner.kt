package com.nle.editor.color

import android.app.Activity
import android.content.Context
import android.opengl.EGL14
import android.opengl.GLES20
import android.os.Build

data class NleDeviceColorCapability(
    val supportsGles3: Boolean,
    val supportsHalfFloatRenderTarget: Boolean,
    val supportsFloatRenderTarget: Boolean,
    val supportsWideColorPreview: Boolean,
    val supportsHdrPreview: Boolean,
    val supportsHdrExport: Boolean,
    val maxTextureSize: Int,
    val renderer: String,
    val vendor: String,
    val recommendedQuality: NleColorPipelineQuality,
)

class NleDeviceColorCapabilityScanner(
    private val context: Context,
) {
    fun scan(): NleDeviceColorCapability {
        val eglInfo = queryGlesInfo()

        val supportsWideColorPreview = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val activity = context as? Activity
            activity?.window?.colorMode ==
                android.content.pm.ActivityInfo.COLOR_MODE_WIDE_COLOR_GAMUT ||
                activity?.resources?.configuration?.isScreenWideColorGamut == true
        } else {
            false
        }

        val supportsHdrPreview = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as? android.hardware.display.DisplayManager
                displayManager?.getDisplay(android.view.Display.DEFAULT_DISPLAY)
            } else {
                @Suppress("DEPRECATION")
                (context as? Activity)?.windowManager?.defaultDisplay
            }
            display?.hdrCapabilities?.supportedHdrTypes?.isNotEmpty() == true
        } else {
            false
        }

        val supportsHalfFloat =
            eglInfo.extensions.contains("GL_EXT_color_buffer_half_float") ||
                eglInfo.extensions.contains("GL_EXT_color_buffer_float") ||
                eglInfo.extensions.contains("GL_OES_texture_half_float")

        val supportsFloat = eglInfo.extensions.contains("GL_EXT_color_buffer_float")

        val quality = when {
            supportsFloat && eglInfo.supportsGles3 -> NleColorPipelineQuality.HIGH_PRECISION_32F
            supportsHalfFloat && eglInfo.supportsGles3 -> NleColorPipelineQuality.STANDARD_16F
            else -> NleColorPipelineQuality.COMPATIBILITY_8BIT
        }

        return NleDeviceColorCapability(
            supportsGles3 = eglInfo.supportsGles3,
            supportsHalfFloatRenderTarget = supportsHalfFloat,
            supportsFloatRenderTarget = supportsFloat,
            supportsWideColorPreview = supportsWideColorPreview,
            supportsHdrPreview = supportsHdrPreview,
            supportsHdrExport = supportsHdrPreview,
            maxTextureSize = eglInfo.maxTextureSize,
            renderer = eglInfo.renderer,
            vendor = eglInfo.vendor,
            recommendedQuality = quality,
        )
    }

    private data class GlesInfo(
        val supportsGles3: Boolean,
        val maxTextureSize: Int,
        val renderer: String,
        val vendor: String,
        val version: String,
        val extensions: String,
    )

    private fun queryGlesInfo(): GlesInfo {
        var renderer = "unknown"
        var vendor = "unknown"
        var version = "unknown"
        var extensions = ""
        var maxTexture = 0
        var supportsGles3 = false

        val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        if (display == EGL14.EGL_NO_DISPLAY) {
            return GlesInfo(
                supportsGles3 = false,
                maxTextureSize = 0,
                renderer = renderer,
                vendor = vendor,
                version = version,
                extensions = extensions,
            )
        }

        val ver = IntArray(2)
        EGL14.eglInitialize(display, ver, 0, ver, 1)

        val config = chooseConfig(display)
        if (config != null) {
            // Try GLES 3 first, fall back to GLES 2
            val attrs3 = intArrayOf(
                EGL14.EGL_CONTEXT_CLIENT_VERSION, 3, EGL14.EGL_NONE,
            )
            var eglContext = EGL14.eglCreateContext(
                display, config, EGL14.EGL_NO_CONTEXT, attrs3, 0,
            )
            if (eglContext == EGL14.EGL_NO_CONTEXT) {
                val attrs2 = intArrayOf(
                    EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE,
                )
                eglContext = EGL14.eglCreateContext(
                    display, config, EGL14.EGL_NO_CONTEXT, attrs2, 0,
                )
            }

            val surfaceAttrs = intArrayOf(
                EGL14.EGL_WIDTH, 1, EGL14.EGL_HEIGHT, 1, EGL14.EGL_NONE,
            )
            val surface = EGL14.eglCreatePbufferSurface(
                display, config, surfaceAttrs, 0,
            )

            if (eglContext != EGL14.EGL_NO_CONTEXT && surface != EGL14.EGL_NO_SURFACE) {
                EGL14.eglMakeCurrent(display, surface, surface, eglContext)
                renderer = GLES20.glGetString(GLES20.GL_RENDERER) ?: "unknown"
                vendor = GLES20.glGetString(GLES20.GL_VENDOR) ?: "unknown"
                version = GLES20.glGetString(GLES20.GL_VERSION) ?: "unknown"
                extensions = GLES20.glGetString(GLES20.GL_EXTENSIONS) ?: ""
                val maxTex = IntArray(1)
                GLES20.glGetIntegerv(GLES20.GL_MAX_TEXTURE_SIZE, maxTex, 0)
                maxTexture = maxTex[0]
                supportsGles3 = version.contains("OpenGL ES 3") ||
                    version.contains("OpenGL ES 4")
                EGL14.eglMakeCurrent(
                    display,
                    EGL14.EGL_NO_SURFACE,
                    EGL14.EGL_NO_SURFACE,
                    EGL14.EGL_NO_CONTEXT,
                )
            }
            if (surface != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(display, surface)
            if (eglContext != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(display, eglContext)
        }
        EGL14.eglTerminate(display)

        return GlesInfo(
            supportsGles3 = supportsGles3,
            maxTextureSize = maxTexture,
            renderer = renderer,
            vendor = vendor,
            version = version,
            extensions = extensions,
        )
    }

    private fun chooseConfig(
        display: android.opengl.EGLDisplay,
    ): android.opengl.EGLConfig? {
        val attrs = intArrayOf(
            EGL14.EGL_RENDERABLE_TYPE,
            EGL14.EGL_OPENGL_ES2_BIT or 0x00000040, // ES3 bit
            EGL14.EGL_RED_SIZE, 8,
            EGL14.EGL_GREEN_SIZE, 8,
            EGL14.EGL_BLUE_SIZE, 8,
            EGL14.EGL_ALPHA_SIZE, 8,
            EGL14.EGL_NONE,
        )
        val configs = arrayOfNulls<android.opengl.EGLConfig>(1)
        val count = IntArray(1)
        val ok = EGL14.eglChooseConfig(display, attrs, 0, configs, 0, 1, count, 0)
        if (!ok || count[0] == 0) return null
        return configs[0]
    }
}
