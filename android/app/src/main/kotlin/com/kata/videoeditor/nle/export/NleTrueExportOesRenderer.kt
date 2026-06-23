package com.kata.videoeditor.nle.export

import android.opengl.GLES20
import android.opengl.Matrix
import com.kata.videoeditor.nle.gpu.NleExternalOesProgram
import com.kata.videoeditor.nle.gpu.NleTextBitmapRenderer
import com.kata.videoeditor.nle.gpu.NleTextOverlay
import com.kata.videoeditor.nle.gpu.NleTextStyleParser
import com.kata.videoeditor.nle.gpu.NleTextureProgram
import com.kata.videoeditor.nle.gpu.NleGlUtil
import kotlin.math.max

/**
 * Drives the per-frame GL render pipeline for the V2 true-decoder export.
 */
class NleTrueExportOesRenderer {

    private val oesProgram = NleExternalOesProgram()
    private val textProgram = NleTextureProgram()
    private val textBitmapRenderer = NleTextBitmapRenderer()

    private val vertexBuffer = NleGlUtil.createFloatBuffer(
        floatArrayOf(-1f, -1f,  1f, -1f,  -1f, 1f,  1f, 1f)
    )

    private val texCoordBuffer = NleGlUtil.createFloatBuffer(
        floatArrayOf(0f, 1f,  1f, 1f,  0f, 0f,  1f, 0f)
    )

    // ── Frame lifecycle ───────────────────────────────────────────────────────

    fun beginFrame(
        width: Int,
        height: Int,
        backgroundColor: FloatArray,
    ) {
        GLES20.glViewport(0, 0, width, height)

        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

        GLES20.glClearColor(
            backgroundColor.getOrElse(0) { 0f },
            backgroundColor.getOrElse(1) { 0f },
            backgroundColor.getOrElse(2) { 0f },
            backgroundColor.getOrElse(3) { 1f },
        )
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
    }

    fun drawLayer(
        layer: NleTrueExportLayer,
        frame: NleDecodedVideoFrame,
        outputWidth: Int,
        outputHeight: Int,
    ) {
        val asset = layer.asset ?: return
        val mvp = buildMvpMatrix(
            clip         = layer.clip,
            sourceWidth  = max(asset.width,  1),
            sourceHeight = max(asset.height, 1),
            outputWidth  = outputWidth,
            outputHeight = outputHeight,
        )

        oesProgram.draw(
            textureId     = frame.oesTextureId,
            textureMatrix = frame.textureTransform,
            mvpMatrix     = mvp,
            opacity       = layer.opacity,
            brightness    = layer.clip.brightness,
            contrast      = layer.clip.contrast,
            saturation    = layer.clip.saturation,
        )
    }

    fun drawTextOverlay(
        layer: NleTrueExportLayer,
        outputWidth: Int,
        outputHeight: Int,
    ) {
        val clip = layer.clip
        val text = clip.textContent ?: ""
        val style = NleTextStyleParser.parse(clip.textStyle)

        val overlay = NleTextOverlay(
            clipId = clip.id,
            text = text,
            timelineStartMicros = clip.timelineStartUs,
            timelineEndMicros = clip.timelineEndUs,
            positionX = clip.positionX,
            positionY = clip.positionY,
            scale = clip.scale,
            rotationDegrees = clip.rotation,
            opacity = clip.opacity,
            style = style
        )

        val bitmap = textBitmapRenderer.createTextBitmap(
            overlay = overlay,
            outputWidth = outputWidth,
            outputHeight = outputHeight
        )

        try {
            val textureId = NleGlUtil.createTextureFromBitmap(bitmap)
            try {
                val mvp = FloatArray(16)
                Matrix.setIdentityM(mvp, 0)
                Matrix.translateM(mvp, 0, overlay.positionX * 2f, -overlay.positionY * 2f, 0f)
                Matrix.rotateM(mvp, 0, overlay.rotationDegrees, 0f, 0f, 1f)
                Matrix.scaleM(mvp, 0, overlay.scale, overlay.scale, 1f)

                textProgram.draw(
                    textureId = textureId,
                    vertexBuffer = vertexBuffer,
                    texCoordBuffer = texCoordBuffer,
                    mvpMatrix = mvp,
                    opacity = overlay.opacity,
                    brightness = 0f,
                    contrast = 1f,
                    saturation = 1f
                )
            } finally {
                NleGlUtil.deleteTexture(textureId)
            }
        } finally {
            bitmap.recycle()
        }
    }

    fun endFrame() {
        GLES20.glFinish()
    }

    fun release() {
        try { oesProgram.release() } catch (_: Throwable) {}
        try { textProgram.release() } catch (_: Throwable) {}
    }

    // ── MVP matrix ────────────────────────────────────────────────────────────

    private fun buildMvpMatrix(
        clip: NleTrueExportClip,
        sourceWidth: Int,
        sourceHeight: Int,
        outputWidth: Int,
        outputHeight: Int,
    ): FloatArray {
        val matrix = FloatArray(16)
        Matrix.setIdentityM(matrix, 0)

        val sourceAspect = sourceWidth.toFloat()  / sourceHeight.toFloat()
        val outputAspect = outputWidth.toFloat()  / outputHeight.toFloat()

        var scaleX = 1f
        var scaleY = 1f

        when (clip.fitMode) {
            "fill", "crop" -> {
                if (sourceAspect > outputAspect) scaleX = sourceAspect / outputAspect
                else                             scaleY = outputAspect / sourceAspect
            }
            "stretch" -> {}
            else -> {
                if (sourceAspect > outputAspect) scaleY = outputAspect / sourceAspect
                else                             scaleX = sourceAspect / outputAspect
            }
        }

        Matrix.translateM(matrix, 0, clip.positionX * 2f, -clip.positionY * 2f, 0f)
        Matrix.rotateM   (matrix, 0, clip.rotation,        0f, 0f, 1f)
        Matrix.scaleM    (matrix, 0, scaleX * clip.scale, scaleY * clip.scale, 1f)

        return matrix
    }
}
