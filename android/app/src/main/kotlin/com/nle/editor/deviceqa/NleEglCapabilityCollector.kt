package com.nle.editor.deviceqa

import android.opengl.EGL14
import android.opengl.GLES20

class NleEglCapabilityCollector {

    fun collect(): NleEglCapabilityReport {
        var eglAvailable  = false
        var glesVersion   = "unknown"
        var renderer      = "unknown"
        var vendor        = "unknown"
        var maxTextureSize = 0
        var supportsFbo   = false

        val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)

        if (display != EGL14.EGL_NO_DISPLAY) {
            val version = IntArray(2)

            if (EGL14.eglInitialize(display, version, 0, version, 1)) {
                eglAvailable = true
                val config   = chooseConfig(display)

                if (config != null) {
                    val contextAttribs = intArrayOf(
                        EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
                        EGL14.EGL_NONE,
                    )
                    val context = EGL14.eglCreateContext(
                        display, config, EGL14.EGL_NO_CONTEXT, contextAttribs, 0,
                    )

                    val surfaceAttribs = intArrayOf(
                        EGL14.EGL_WIDTH, 1,
                        EGL14.EGL_HEIGHT, 1,
                        EGL14.EGL_NONE,
                    )
                    val surface = EGL14.eglCreatePbufferSurface(
                        display, config, surfaceAttribs, 0,
                    )

                    if (context != EGL14.EGL_NO_CONTEXT && surface != EGL14.EGL_NO_SURFACE) {
                        EGL14.eglMakeCurrent(display, surface, surface, context)

                        glesVersion = GLES20.glGetString(GLES20.GL_VERSION)  ?: "unknown"
                        renderer    = GLES20.glGetString(GLES20.GL_RENDERER) ?: "unknown"
                        vendor      = GLES20.glGetString(GLES20.GL_VENDOR)   ?: "unknown"

                        val maxTex = IntArray(1)
                        GLES20.glGetIntegerv(GLES20.GL_MAX_TEXTURE_SIZE, maxTex, 0)
                        maxTextureSize = maxTex[0]

                        supportsFbo = checkFramebufferSupport()

                        EGL14.eglMakeCurrent(
                            display,
                            EGL14.EGL_NO_SURFACE,
                            EGL14.EGL_NO_SURFACE,
                            EGL14.EGL_NO_CONTEXT,
                        )
                    }

                    if (surface  != EGL14.EGL_NO_SURFACE)  EGL14.eglDestroySurface(display, surface)
                    if (context  != EGL14.EGL_NO_CONTEXT)  EGL14.eglDestroyContext(display, context)
                }

                EGL14.eglTerminate(display)
            }
        }

        return NleEglCapabilityReport(
            eglAvailable             = eglAvailable,
            glesVersion              = glesVersion,
            glRenderer               = renderer,
            glVendor                 = vendor,
            maxTextureSize           = maxTextureSize,
            supportsExternalOes      = true,
            supportsFramebufferObject = supportsFbo,
        )
    }

    private fun chooseConfig(
        display: android.opengl.EGLDisplay,
    ): android.opengl.EGLConfig? {
        val attribs = intArrayOf(
            EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
            EGL14.EGL_RED_SIZE,    8,
            EGL14.EGL_GREEN_SIZE,  8,
            EGL14.EGL_BLUE_SIZE,   8,
            EGL14.EGL_ALPHA_SIZE,  8,
            EGL14.EGL_NONE,
        )
        val configs = arrayOfNulls<android.opengl.EGLConfig>(1)
        val count   = IntArray(1)

        val ok = EGL14.eglChooseConfig(display, attribs, 0, configs, 0, configs.size, count, 0)
        if (!ok || count[0] <= 0) return null
        return configs[0]
    }

    private fun checkFramebufferSupport(): Boolean {
        val fbos = IntArray(1)
        GLES20.glGenFramebuffers(1, fbos, 0)
        val ok = fbos[0] > 0
        if (ok) GLES20.glDeleteFramebuffers(1, fbos, 0)
        return ok
    }
}
