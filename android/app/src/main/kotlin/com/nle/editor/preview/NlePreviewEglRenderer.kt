package com.nle.editor.preview

import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLExt
import android.opengl.EGLSurface
import android.view.Surface

class NlePreviewEglRenderer {

    private var display: EGLDisplay = EGL14.EGL_NO_DISPLAY
    private var context: EGLContext = EGL14.EGL_NO_CONTEXT
    private var surface: EGLSurface = EGL14.EGL_NO_SURFACE

    fun initialize(
        outputSurface: Surface,
    ) {
        display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)

        check(display != EGL14.EGL_NO_DISPLAY) {
            "Unable to get EGL display."
        }

        val version = IntArray(2)

        check(EGL14.eglInitialize(display, version, 0, version, 1)) {
            "Unable to initialize EGL."
        }

        val config = chooseConfig()

        val contextAttribs = intArrayOf(
            EGL14.EGL_CONTEXT_CLIENT_VERSION,
            2,
            EGL14.EGL_NONE,
        )

        context = EGL14.eglCreateContext(
            display,
            config,
            EGL14.EGL_NO_CONTEXT,
            contextAttribs,
            0,
        )

        check(context != EGL14.EGL_NO_CONTEXT) {
            "Unable to create EGL context."
        }

        val surfaceAttribs = intArrayOf(EGL14.EGL_NONE)

        surface = EGL14.eglCreateWindowSurface(
            display,
            config,
            outputSurface,
            surfaceAttribs,
            0,
        )

        check(surface != EGL14.EGL_NO_SURFACE) {
            "Unable to create EGL window surface."
        }
    }

    fun makeCurrent() {
        if (display == EGL14.EGL_NO_DISPLAY) return

        EGL14.eglMakeCurrent(
            display,
            surface,
            surface,
            context,
        )
    }

    fun setPresentationTimeNanos(timestampNanos: Long) {
        if (display == EGL14.EGL_NO_DISPLAY || surface == EGL14.EGL_NO_SURFACE) return
        EGLExt.eglPresentationTimeANDROID(display, surface, timestampNanos)
    }

    fun swapBuffers() {
        if (display == EGL14.EGL_NO_DISPLAY) return
        EGL14.eglSwapBuffers(display, surface)
    }

    fun release() {
        if (display != EGL14.EGL_NO_DISPLAY) {
            EGL14.eglMakeCurrent(
                display,
                EGL14.EGL_NO_SURFACE,
                EGL14.EGL_NO_SURFACE,
                EGL14.EGL_NO_CONTEXT,
            )

            if (surface != EGL14.EGL_NO_SURFACE) {
                EGL14.eglDestroySurface(display, surface)
            }

            if (context != EGL14.EGL_NO_CONTEXT) {
                EGL14.eglDestroyContext(display, context)
            }

            EGL14.eglTerminate(display)
        }

        display = EGL14.EGL_NO_DISPLAY
        context = EGL14.EGL_NO_CONTEXT
        surface = EGL14.EGL_NO_SURFACE
    }

    private fun chooseConfig(): EGLConfig {
        val attribs = intArrayOf(
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
            EGL14.EGL_NONE,
        )

        val configs = arrayOfNulls<EGLConfig>(1)
        val numConfigs = IntArray(1)

        check(
            EGL14.eglChooseConfig(
                display,
                attribs,
                0,
                configs,
                0,
                configs.size,
                numConfigs,
                0,
            )
        ) {
            "Unable to choose EGL config."
        }

        return configs[0] ?: error("No EGL config found.")
    }
}
