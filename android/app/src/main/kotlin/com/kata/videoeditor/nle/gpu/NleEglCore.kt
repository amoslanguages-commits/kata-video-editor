package com.kata.videoeditor.nle.gpu

import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLExt
import android.opengl.EGLSurface
import android.opengl.GLES20

class NleEglCore {
    private var eglDisplay: EGLDisplay = EGL14.EGL_NO_DISPLAY
    private var eglContext: EGLContext = EGL14.EGL_NO_CONTEXT
    private var eglConfig: EGLConfig? = null
    
    private var sharedContext: EGLContext = EGL14.EGL_NO_CONTEXT
    private var flags: Int = 0

    constructor()

    constructor(sharedContext: EGLContext, flags: Int) {
        this.sharedContext = sharedContext
        this.flags = flags
        initialize()
    }

    fun initialize() {
        if (eglDisplay != EGL14.EGL_NO_DISPLAY) {
            return
        }

        eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)

        if (eglDisplay == EGL14.EGL_NO_DISPLAY) {
            throw RuntimeException("Unable to get EGL display.")
        }

        val version = IntArray(2)

        if (!EGL14.eglInitialize(eglDisplay, version, 0, version, 1)) {
            throw RuntimeException("Unable to initialize EGL.")
        }

        eglConfig = chooseConfig()

        val attribList = intArrayOf(
            EGL14.EGL_CONTEXT_CLIENT_VERSION,
            2,
            EGL14.EGL_NONE
        )

        eglContext = EGL14.eglCreateContext(
            eglDisplay,
            eglConfig,
            sharedContext,
            attribList,
            0
        )

        checkEglError("eglCreateContext")

        if (eglContext == EGL14.EGL_NO_CONTEXT) {
            throw RuntimeException("Failed to create EGL context.")
        }
    }

    fun createWindowSurface(nativeWindow: Any): EGLSurface {
        initialize()

        val surfaceAttribs = intArrayOf(
            EGL14.EGL_NONE
        )

        val surface = EGL14.eglCreateWindowSurface(
            eglDisplay,
            eglConfig,
            nativeWindow,
            surfaceAttribs,
            0
        )

        checkEglError("eglCreateWindowSurface")

        if (surface == null || surface == EGL14.EGL_NO_SURFACE) {
            throw RuntimeException("Failed to create EGL window surface.")
        }

        return surface
    }

    fun makeCurrent(surface: EGLSurface) {
        if (!EGL14.eglMakeCurrent(
                eglDisplay,
                surface,
                surface,
                eglContext
            )
        ) {
            throw RuntimeException("eglMakeCurrent failed.")
        }
    }

    fun swapBuffers(surface: EGLSurface) {
        if (!EGL14.eglSwapBuffers(eglDisplay, surface)) {
            throw RuntimeException("eglSwapBuffers failed.")
        }
    }

    fun setPresentationTime(
        surface: EGLSurface,
        presentationTimeNanos: Long,
    ) {
        EGLExt.eglPresentationTimeANDROID(
            eglDisplay,
            surface,
            presentationTimeNanos
        )
    }

    fun destroySurface(surface: EGLSurface?) {
        if (surface == null || surface == EGL14.EGL_NO_SURFACE) {
            return
        }

        EGL14.eglDestroySurface(eglDisplay, surface)
    }

    fun release() {
        if (eglDisplay == EGL14.EGL_NO_DISPLAY) {
            return
        }

        EGL14.eglMakeCurrent(
            eglDisplay,
            EGL14.EGL_NO_SURFACE,
            EGL14.EGL_NO_SURFACE,
            EGL14.EGL_NO_CONTEXT
        )

        EGL14.eglDestroyContext(eglDisplay, eglContext)
        EGL14.eglReleaseThread()
        EGL14.eglTerminate(eglDisplay)

        eglDisplay = EGL14.EGL_NO_DISPLAY
        eglContext = EGL14.EGL_NO_CONTEXT
        eglConfig = null
    }

    private fun chooseConfig(): EGLConfig {
        val attribList = if ((flags and FLAG_RECORDABLE) != 0) {
            intArrayOf(
                EGL14.EGL_RENDERABLE_TYPE,
                EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_RED_SIZE,
                8,
                EGL14.EGL_GREEN_SIZE,
                8,
                EGL14.EGL_BLUE_SIZE,
                8,
                EGL14.EGL_ALPHA_SIZE,
                8,
                EGL14.EGL_DEPTH_SIZE,
                0,
                EGL14.EGL_STENCIL_SIZE,
                0,
                EGL_RECORDABLE_ANDROID,
                1,
                EGL14.EGL_NONE
            )
        } else {
            intArrayOf(
                EGL14.EGL_RENDERABLE_TYPE,
                EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_RED_SIZE,
                8,
                EGL14.EGL_GREEN_SIZE,
                8,
                EGL14.EGL_BLUE_SIZE,
                8,
                EGL14.EGL_ALPHA_SIZE,
                8,
                EGL14.EGL_DEPTH_SIZE,
                0,
                EGL14.EGL_STENCIL_SIZE,
                0,
                EGL14.EGL_NONE
            )
        }

        val configs = arrayOfNulls<EGLConfig>(1)
        val numConfigs = IntArray(1)

        if (!EGL14.eglChooseConfig(
                eglDisplay,
                attribList,
                0,
                configs,
                0,
                configs.size,
                numConfigs,
                0
            )
        ) {
            throw RuntimeException("eglChooseConfig failed.")
        }

        return configs[0] ?: throw RuntimeException("No EGL config found.")
    }

    private fun checkEglError(label: String) {
        val error = EGL14.eglGetError()

        if (error != EGL14.EGL_SUCCESS) {
            throw RuntimeException("$label EGL error: 0x${Integer.toHexString(error)}")
        }
    }

    companion object {
        const val FLAG_RECORDABLE = 0x01
        private const val EGL_RECORDABLE_ANDROID = 0x3142
    }
}
