package com.kata.videoeditor.nle.gpu

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF

/**
 * Renders a [NleTextOverlay] into a [Bitmap] the same size as the output frame.
 *
 * The text is composited using the Android [Canvas] API (CPU-side), then the
 * bitmap is uploaded to an OpenGL texture by [NleGlUtil.createTextureFromBitmap]
 * and drawn as a full-viewport quad via [NleTextureProgram].
 *
 * Supported features per the V1 spec:
 *  - Multi-line text (`\n` and literal newlines)
 *  - Fill color + opacity
 *  - Stroke (outline)
 *  - Drop shadow
 *  - Rounded-corner background box
 *  - Left / center / right alignment
 */
class NleTextBitmapRenderer {

    /**
     * Returns a new [Bitmap] of [outputWidth]×[outputHeight] with the overlay
     * text composited onto a transparent background.
     *
     * The caller is responsible for recycling the returned bitmap after use.
     */
    fun createTextBitmap(
        overlay: NleTextOverlay,
        outputWidth: Int,
        outputHeight: Int,
    ): Bitmap {
        val w = outputWidth.coerceAtLeast(16)
        val h = outputHeight.coerceAtLeast(16)

        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val style  = overlay.style

        // ── Text paint ───────────────────────────────────────────────────────
        val combinedAlpha = (style.opacity * overlay.opacity).coerceIn(0f, 1f)

        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color     = style.color
            textSize  = style.fontSize
            textAlign = when (style.alignment) {
                "left"  -> Paint.Align.LEFT
                "right" -> Paint.Align.RIGHT
                else    -> Paint.Align.CENTER
            }
            alpha = (combinedAlpha * 255f).toInt()
        }

        if (style.shadowEnabled) {
            textPaint.setShadowLayer(
                style.shadowBlur,
                style.shadowOffsetX,
                style.shadowOffsetY,
                style.shadowColor
            )
        }

        // ── Lines ────────────────────────────────────────────────────────────
        val lines = overlay.text
            .replace("\\n", "\n")
            .split("\n")
            .filter { it.isNotBlank() }
            .ifEmpty { listOf(" ") }

        val lineHeight   = style.fontSize * 1.18f
        val totalHeight  = lineHeight * lines.size

        // Anchor text at the vertical centre of the bitmap.
        // positionX/Y offsets are applied via the GL MVP matrix, so the bitmap
        // itself is always centred here.
        val centerX = w / 2f
        val centerY = h / 2f

        val textX = when (style.alignment) {
            "left"  -> centerX - w * 0.35f
            "right" -> centerX + w * 0.35f
            else    -> centerX
        }

        val startY = centerY - totalHeight / 2f + style.fontSize

        // ── Background box ───────────────────────────────────────────────────
        if (style.backgroundEnabled) {
            val bounds = calculateTextBounds(
                lines     = lines,
                paint     = textPaint,
                lineHeight = lineHeight,
                textX     = textX,
                startY    = startY,
                alignment = style.alignment
            )

            val padX = style.fontSize * 0.45f
            val padY = style.fontSize * 0.30f

            val bgRect = RectF(
                bounds.left   - padX,
                bounds.top    - padY,
                bounds.right  + padX,
                bounds.bottom + padY
            )

            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = style.backgroundColor
                alpha = (overlay.opacity.coerceIn(0f, 1f) * 255f).toInt()
            }

            canvas.drawRoundRect(
                bgRect,
                style.backgroundRadius,
                style.backgroundRadius,
                bgPaint
            )
        }

        // ── Stroke pass ──────────────────────────────────────────────────────
        if (style.strokeWidth > 0f) {
            val strokePaint = Paint(textPaint).apply {
                this.style   = Paint.Style.STROKE
                strokeWidth = overlay.style.strokeWidth
                color       = overlay.style.strokeColor
                clearShadowLayer()
            }

            drawLines(canvas, lines, strokePaint, textX, startY, lineHeight)
        }

        // ── Fill pass ────────────────────────────────────────────────────────
        textPaint.style = Paint.Style.FILL
        drawLines(canvas, lines, textPaint, textX, startY, lineHeight)

        return bitmap
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun drawLines(
        canvas: Canvas,
        lines: List<String>,
        paint: Paint,
        x: Float,
        startY: Float,
        lineHeight: Float,
    ) {
        lines.forEachIndexed { index, line ->
            canvas.drawText(line, x, startY + index * lineHeight, paint)
        }
    }

    private fun calculateTextBounds(
        lines: List<String>,
        paint: Paint,
        lineHeight: Float,
        textX: Float,
        startY: Float,
        alignment: String,
    ): RectF {
        val rect = Rect()

        var left   = Float.MAX_VALUE
        var top    = Float.MAX_VALUE
        var right  = -Float.MAX_VALUE
        var bottom = -Float.MAX_VALUE

        lines.forEachIndexed { index, line ->
            paint.getTextBounds(line, 0, line.length, rect)

            val w = rect.width().toFloat()
            val y = startY + index * lineHeight

            val l = when (alignment) {
                "left"  -> textX
                "right" -> textX - w
                else    -> textX - w / 2f
            }
            val r = l + w
            val t = y - paint.textSize
            val b = y + paint.textSize * 0.25f

            if (l < left)   left   = l
            if (t < top)    top    = t
            if (r > right)  right  = r
            if (b > bottom) bottom = b
        }

        return RectF(left, top, right, bottom)
    }
}
