package com.nle.editor.colorpipeline

import android.opengl.GLES20

object NleGlError {
    fun check(label: String) {
        val error = GLES20.glGetError()
        if (error != GLES20.GL_NO_ERROR) {
            throw IllegalStateException("$label GL error: 0x${error.toString(16)}")
        }
    }
}
