package com.nle.editor.scopes

import android.opengl.GLES20
import com.nle.editor.colorpipeline.NleFullscreenQuad
import com.nle.editor.colorpipeline.NleShaderProgram
import com.nle.editor.colorpipeline.NleGlError
import java.nio.ByteBuffer
import java.nio.ByteOrder

class NleScopeDownsampler {
    private var framebufferId = 0
    private var textureId = 0
    private var sampleWidth = 0
    private var sampleHeight = 0
    
    private val quad = NleFullscreenQuad()
    private val program = NleShaderProgram(
        vertexShaderSource = """
            attribute vec2 aPosition;
            attribute vec2 aTexCoord;
            varying vec2 vTexCoord;
            void main() {
                vTexCoord = aTexCoord;
                gl_Position = vec4(aPosition, 0.0, 1.0);
            }
        """.trimIndent(),
        fragmentShaderSource = """
            precision highp float;
            varying vec2 vTexCoord;
            uniform sampler2D uTexture;
            void main() {
                gl_FragColor = texture2D(uTexture, vTexCoord);
            }
        """.trimIndent()
    )
    
    private var prepared = false
    private var pixelBuffer: ByteBuffer? = null
    
    fun prepare(width: Int, height: Int) {
        if (prepared && sampleWidth == width && sampleHeight == height) {
            return
        }
        
        release()
        
        sampleWidth = width
        sampleHeight = height
        
        // Compile shader program
        program.compile()
        
        // Generate texture
        val texIds = IntArray(1)
        GLES20.glGenTextures(1, texIds, 0)
        textureId = texIds[0]
        
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA,
            sampleWidth, sampleHeight, 0, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null
        )
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        
        // Generate framebuffer
        val fboIds = IntArray(1)
        GLES20.glGenFramebuffers(1, fboIds, 0)
        framebufferId = fboIds[0]
        
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, framebufferId)
        GLES20.glFramebufferTexture2D(
            GLES20.GL_FRAMEBUFFER,
            GLES20.GL_COLOR_ATTACHMENT0,
            GLES20.GL_TEXTURE_2D,
            textureId,
            0
        )
        
        val status = GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        
        if (status != GLES20.GL_FRAMEBUFFER_COMPLETE) {
            release()
            throw IllegalStateException("Scope downsample framebuffer incomplete: $status")
        }
        
        pixelBuffer = ByteBuffer.allocateDirect(sampleWidth * sampleHeight * 4).order(ByteOrder.nativeOrder())
        prepared = true
    }
    
    fun downsample(inputTextureId: Int): ByteBuffer? {
        if (!prepared) return null
        val buffer = pixelBuffer ?: return null
        buffer.clear()
        
        // Bind FBO
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, framebufferId)
        
        // Save current viewport
        val originalViewport = IntArray(4)
        GLES20.glGetIntegerv(GLES20.GL_VIEWPORT, originalViewport, 0)
        
        GLES20.glViewport(0, 0, sampleWidth, sampleHeight)
        
        GLES20.glDisable(GLES20.GL_BLEND)
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        
        program.use()
        
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, inputTextureId)
        val textureLoc = GLES20.glGetUniformLocation(program.programId, "uTexture")
        if (textureLoc >= 0) {
            GLES20.glUniform1i(textureLoc, 0)
        }
        
        quad.draw(program.programId)
        
        GLES20.glReadPixels(
            0, 0, sampleWidth, sampleHeight,
            GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buffer
        )
        
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        
        // Restore viewport
        GLES20.glViewport(originalViewport[0], originalViewport[1], originalViewport[2], originalViewport[3])
        
        NleGlError.check("NleScopeDownsampler.downsample")
        
        buffer.rewind()
        return buffer
    }
    
    fun release() {
        if (framebufferId != 0) {
            GLES20.glDeleteFramebuffers(1, intArrayOf(framebufferId), 0)
            framebufferId = 0
        }
        if (textureId != 0) {
            GLES20.glDeleteTextures(1, intArrayOf(textureId), 0)
            textureId = 0
        }
        program.release()
        pixelBuffer = null
        prepared = false
    }
}
