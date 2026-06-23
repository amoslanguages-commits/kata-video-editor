package com.kata.videoeditor.nle.gpu

import android.opengl.EGL14
import android.opengl.EGLSurface
import android.view.Surface

class NleEglWindowSurface(
    private val eglCore: NleEglCore,
    private val surface: Surface,
    private val releaseSurface: Boolean = false,
) {
    private var eglSurface: EGLSurface? = null

    init {
        create()
    }

    fun create() {
        if (eglSurface != null && eglSurface != EGL14.EGL_NO_SURFACE) {
            return
        }

        eglSurface = eglCore.createWindowSurface(surface)
    }

    fun makeCurrent() {
        val target = eglSurface
            ?: throw IllegalStateException("EGL surface has not been created.")

        eglCore.makeCurrent(target)
    }

    fun swapBuffers() {
        val target = eglSurface
            ?: throw IllegalStateException("EGL surface has not been created.")

        eglCore.swapBuffers(target)
    }

    fun setPresentationTime(presentationTimeNanos: Long) {
        val target = eglSurface
            ?: throw IllegalStateException("EGL surface has not been created.")

        eglCore.setPresentationTime(
            surface = target,
            presentationTimeNanos = presentationTimeNanos
        )
    }

    fun release() {
        eglCore.destroySurface(eglSurface)
        eglSurface = null
        if (releaseSurface) {
            try {
                surface.release()
            } catch (_: Throwable) {}
        }
    }
}
