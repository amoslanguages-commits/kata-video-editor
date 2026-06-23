package com.kata.videoeditor.nle

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Shader
import android.view.Surface
import io.flutter.view.TextureRegistry

class NlePreviewTexture(
    private val entry: TextureRegistry.SurfaceTextureEntry,
    initialWidth: Int,
    initialHeight: Int,
) {
    val textureId: Long = entry.id()

    private var surface: Surface? = null

    var width: Int = initialWidth.coerceAtLeast(16)
        private set

    var height: Int = initialHeight.coerceAtLeast(16)
        private set

    var attachedProjectId: String? = null
        private set

    var attachedSessionId: String? = null
        private set

    var createdAtMillis: Long = System.currentTimeMillis()
        private set

    var updatedAtMillis: Long = createdAtMillis
        private set

    init {
        entry.surfaceTexture().setDefaultBufferSize(width, height)
        surface = Surface(entry.surfaceTexture())
    }

    fun attachToProject(
        projectId: String,
        sessionId: String?,
    ) {
        attachedProjectId = projectId
        attachedSessionId = sessionId
        updatedAtMillis = System.currentTimeMillis()
    }

    fun resize(
        newWidth: Int,
        newHeight: Int,
    ) {
        width = newWidth.coerceAtLeast(16)
        height = newHeight.coerceAtLeast(16)

        entry.surfaceTexture().setDefaultBufferSize(width, height)
        updatedAtMillis = System.currentTimeMillis()
    }

    fun getSurface(): Surface? {
        return surface
    }

    fun renderPlaceholderFrame(
        label: String = "Native Preview Surface",
        playheadMicros: Long = 0L,
    ) {
        val targetSurface = surface ?: return

        var canvas: Canvas? = null

        try {
            canvas = targetSurface.lockCanvas(null)

            drawPlaceholder(
                canvas = canvas,
                label = label,
                playheadMicros = playheadMicros,
            )

            targetSurface.unlockCanvasAndPost(canvas)
            canvas = null

            updatedAtMillis = System.currentTimeMillis()
        } finally {
            if (canvas != null) {
                try {
                    targetSurface.unlockCanvasAndPost(canvas)
                } catch (_: Throwable) {
                }
            }
        }
    }

    private fun drawPlaceholder(
        canvas: Canvas,
        label: String,
        playheadMicros: Long,
    ) {
        val w = canvas.width
        val h = canvas.height

        val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                0f,
                0f,
                w.toFloat(),
                h.toFloat(),
                Color.rgb(14, 18, 32),
                Color.rgb(4, 7, 14),
                Shader.TileMode.CLAMP
            )
        }

        canvas.drawRect(
            0f,
            0f,
            w.toFloat(),
            h.toFloat(),
            backgroundPaint
        )

        val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.argb(110, 0, 229, 255)
            strokeWidth = 3f
        }

        canvas.drawRect(
            8f,
            8f,
            w - 8f,
            h - 8f,
            borderPaint
        )

        val gridPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(28, 255, 255, 255)
            strokeWidth = 1f
        }

        val thirdX1 = w / 3f
        val thirdX2 = w * 2f / 3f
        val thirdY1 = h / 3f
        val thirdY2 = h * 2f / 3f

        canvas.drawLine(thirdX1, 0f, thirdX1, h.toFloat(), gridPaint)
        canvas.drawLine(thirdX2, 0f, thirdX2, h.toFloat(), gridPaint)
        canvas.drawLine(0f, thirdY1, w.toFloat(), thirdY1, gridPaint)
        canvas.drawLine(0f, thirdY2, w.toFloat(), thirdY2, gridPaint)

        val titlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = (w * 0.04f).coerceIn(22f, 42f)
            textAlign = Paint.Align.CENTER
            isFakeBoldText = true
        }

        val subtitlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(190, 255, 255, 255)
            textSize = (w * 0.025f).coerceIn(14f, 24f)
            textAlign = Paint.Align.CENTER
        }

        val badgePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(42, 0, 229, 255)
            style = Paint.Style.FILL
        }

        val badgeStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(130, 0, 229, 255)
            style = Paint.Style.STROKE
            strokeWidth = 2f
        }

        val badgeRect = android.graphics.RectF(
            w * 0.18f,
            h * 0.40f,
            w * 0.82f,
            h * 0.60f
        )

        canvas.drawRoundRect(
            badgeRect,
            24f,
            24f,
            badgePaint
        )

        canvas.drawRoundRect(
            badgeRect,
            24f,
            24f,
            badgeStrokePaint
        )

        canvas.drawText(
            label,
            w / 2f,
            h * 0.48f,
            titlePaint
        )

        canvas.drawText(
            "Texture ID: $textureId • ${width}x$height",
            w / 2f,
            h * 0.54f,
            subtitlePaint
        )

        canvas.drawText(
            "Playhead: ${playheadMicros / 1000L} ms",
            w / 2f,
            h * 0.58f,
            subtitlePaint
        )

        val footerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(130, 255, 255, 255)
            textSize = 18f
            textAlign = Paint.Align.CENTER
        }

        canvas.drawText(
            "Android native surface ready. Decoder/GPU compositor comes later.",
            w / 2f,
            h - 30f,
            footerPaint
        )
    }

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "textureId" to textureId,
            "width" to width,
            "height" to height,
            "projectId" to attachedProjectId,
            "sessionId" to attachedSessionId,
            "createdAtMillis" to createdAtMillis,
            "updatedAtMillis" to updatedAtMillis
        )
    }

    fun release() {
        try {
            surface?.release()
        } catch (_: Throwable) {
        }

        surface = null

        try {
            entry.release()
        } catch (_: Throwable) {
        }
    }
}
