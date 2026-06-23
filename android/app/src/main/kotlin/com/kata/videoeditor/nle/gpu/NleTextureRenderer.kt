package com.kata.videoeditor.nle.gpu

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.opengl.GLES20
import android.opengl.Matrix
import android.os.Build

/**
 * OpenGL ES 2.0 renderer that composites one [NleCompositorFrame] onto the
 * currently-bound EGL window surface.
 *
 * Step 19 capabilities:
 *  - Multiple visual layers (base video + transition cross-fade)
 *  - Per-layer colour grading (brightness / contrast / saturation)
 *  - Text overlay rendering via [NleTextBitmapRenderer] → GL texture
 *  - Alpha blending enabled (required for text and transparent overlays)
 */
class NleTextureRenderer {

    private val program          = NleTextureProgram()
    private val textBitmapRenderer = NleTextBitmapRenderer()

    // ── Full-viewport quad geometry ───────────────────────────────────────────

    private val vertexBuffer = NleGlUtil.createFloatBuffer(
        floatArrayOf(-1f, -1f,  1f, -1f,  -1f, 1f,  1f, 1f)
    )

    private val texCoordBuffer = NleGlUtil.createFloatBuffer(
        floatArrayOf(0f, 1f,  1f, 1f,  0f, 0f,  1f, 0f)
    )

    private val mvpMatrix = FloatArray(16)

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    fun initialize() {
        program.initialize()

        // Enable alpha blending — required for text overlays and transitions.
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
    }

    fun release() {
        program.release()
    }

    // ── Clear ─────────────────────────────────────────────────────────────────

    fun clear(width: Int, height: Int, color: Int) {
        GLES20.glViewport(0, 0, width, height)

        val a = ((color shr 24) and 0xFF) / 255f
        val r = ((color shr 16) and 0xFF) / 255f
        val g = ((color shr  8) and 0xFF) / 255f
        val b = ( color         and 0xFF) / 255f

        GLES20.glClearColor(r, g, b, a)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
    }

    // ── Frame dispatch ────────────────────────────────────────────────────────

    /**
     * Draws all layers in [frame] onto the currently-bound EGL surface.
     *
     * Draw order:
     *  1. Visual layers (bottom → top, e.g. outgoing then incoming for a dissolve)
     *  2. Text overlays (always on top of video)
     */
    fun drawFrame(frame: NleCompositorFrame, outputWidth: Int, outputHeight: Int) {
        frame.visualLayers.forEach { layer ->
            drawVisualLayer(layer, outputWidth, outputHeight)
        }

        frame.textOverlays.forEach { overlay ->
            drawTextOverlay(overlay, outputWidth, outputHeight)
        }
    }

    // ── Visual layer ──────────────────────────────────────────────────────────

    private fun drawVisualLayer(
        layer: NleCompositorVisualLayer,
        outputWidth: Int,
        outputHeight: Int,
    ) {
        val inputPath = layer.inputPath ?: return

        val bitmap = extractBitmap(inputPath, layer.sourceTimeMicros) ?: return

        try {
            val textureId = NleGlUtil.createTextureFromBitmap(bitmap)
            try {
                buildMvpMatrix(
                    sourceWidth  = bitmap.width,
                    sourceHeight = bitmap.height,
                    outputWidth  = outputWidth,
                    outputHeight = outputHeight,
                    transform    = layer.transform
                )

                val opacity = layer.opacityOverride ?: layer.transform.opacity

                program.draw(
                    textureId      = textureId,
                    vertexBuffer   = vertexBuffer,
                    texCoordBuffer = texCoordBuffer,
                    mvpMatrix      = mvpMatrix,
                    opacity        = opacity,
                    brightness     = layer.effects.brightness,
                    contrast       = layer.effects.contrast,
                    saturation     = layer.effects.saturation
                )
            } finally {
                NleGlUtil.deleteTexture(textureId)
            }
        } finally {
            bitmap.recycle()
        }
    }

    // ── Text overlay ──────────────────────────────────────────────────────────

    private fun drawTextOverlay(
        overlay: NleTextOverlay,
        outputWidth: Int,
        outputHeight: Int,
    ) {
        val bitmap = textBitmapRenderer.createTextBitmap(
            overlay      = overlay,
            outputWidth  = outputWidth,
            outputHeight = outputHeight
        )

        try {
            val textureId = NleGlUtil.createTextureFromBitmap(bitmap)
            try {
                buildTextMvpMatrix(overlay)

                program.draw(
                    textureId      = textureId,
                    vertexBuffer   = vertexBuffer,
                    texCoordBuffer = texCoordBuffer,
                    mvpMatrix      = mvpMatrix,
                    opacity        = overlay.opacity,
                    brightness     = 0f,
                    contrast       = 1f,
                    saturation     = 1f
                )
            } finally {
                NleGlUtil.deleteTexture(textureId)
            }
        } finally {
            bitmap.recycle()
        }
    }

    // ── MVP matrix builders ───────────────────────────────────────────────────

    /**
     * Builds an MVP matrix that:
     *  1. Scales the quad to maintain the source aspect ratio in the chosen fit mode
     *  2. Applies position, rotation, and scale transforms from [transform]
     */
    private fun buildMvpMatrix(
        sourceWidth: Int,
        sourceHeight: Int,
        outputWidth: Int,
        outputHeight: Int,
        transform: NleCompositorTransform,
    ) {
        Matrix.setIdentityM(mvpMatrix, 0)

        val srcAspect = sourceWidth.toFloat()  / sourceHeight.toFloat()
        val outAspect = outputWidth.toFloat()  / outputHeight.toFloat()

        val scaleX: Float
        val scaleY: Float

        when (transform.fitMode) {
            "fill", "crop" -> {
                if (srcAspect > outAspect) { scaleX = srcAspect / outAspect; scaleY = 1f }
                else                       { scaleX = 1f;                    scaleY = outAspect / srcAspect }
            }
            "stretch" -> { scaleX = 1f; scaleY = 1f }
            else /* fit */ -> {
                if (srcAspect > outAspect) { scaleX = 1f;                    scaleY = outAspect / srcAspect }
                else                       { scaleX = srcAspect / outAspect; scaleY = 1f }
            }
        }

        Matrix.translateM(mvpMatrix, 0,  transform.positionX * 2f, -transform.positionY * 2f, 0f)
        Matrix.rotateM(  mvpMatrix, 0,  transform.rotationDegrees, 0f, 0f, 1f)
        Matrix.scaleM(   mvpMatrix, 0,  scaleX * transform.scale, scaleY * transform.scale, 1f)
    }

    /**
     * Builds an MVP matrix for a text overlay.
     *
     * The text bitmap already covers the full output resolution, so only
     * position / rotation / scale transforms are applied here (no aspect
     * correction — the GPU draws the quad full-screen and the text is
     * already positioned inside the bitmap).
     */
    private fun buildTextMvpMatrix(overlay: NleTextOverlay) {
        Matrix.setIdentityM(mvpMatrix, 0)
        Matrix.translateM(mvpMatrix, 0,  overlay.positionX * 2f, -overlay.positionY * 2f, 0f)
        Matrix.rotateM(  mvpMatrix, 0,  overlay.rotationDegrees, 0f, 0f, 1f)
        Matrix.scaleM(   mvpMatrix, 0,  overlay.scale, overlay.scale, 1f)
    }

    // ── Bitmap extraction ─────────────────────────────────────────────────────

    private fun extractBitmap(inputPath: String, timeMicros: Long): Bitmap? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(inputPath)
            if (Build.VERSION.SDK_INT >= 27) {
                retriever.getScaledFrameAtTime(
                    timeMicros,
                    MediaMetadataRetriever.OPTION_CLOSEST,
                    1920, 1080
                )
            } else {
                retriever.getFrameAtTime(
                    timeMicros,
                    MediaMetadataRetriever.OPTION_CLOSEST
                )
            }
        } catch (_: Throwable) {
            null
        } finally {
            try { retriever.release() } catch (_: Throwable) { }
        }
    }
}
