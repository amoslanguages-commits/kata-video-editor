package com.nle.editor.compositor

import android.graphics.*
import com.nle.editor.rendergraph.NleResolvedVisualLayer
import org.json.JSONObject
import kotlin.math.max

class NleTextLayerRenderer {

    private val cache = linkedMapOf<String, NleLayerTexture>()

    fun textureForLayer(
        layer: NleResolvedVisualLayer,
        outputWidth: Int,
        outputHeight: Int,
    ): NleLayerTexture? {
        val text = layer.clip.text ?: return null
        val key = buildKey(layer, outputWidth, outputHeight)

        cache[key]?.let { return it }

        val bitmap = Bitmap.createBitmap(
            outputWidth,
            outputHeight,
            Bitmap.Config.ARGB_8888,
        )

        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)

        val style = parseStyle(text.styleJson)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        paint.color = parseColor(text.colorHex ?: "#FFFFFF")
        paint.textSize = style.fontSize
        paint.typeface = if (style.bold) {
            Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        } else {
            Typeface.DEFAULT
        }
        paint.textAlign = Paint.Align.CENTER

        if (style.shadow) {
            paint.setShadowLayer(10f, 0f, 4f, Color.argb(160, 0, 0, 0))
        }

        val strokeWidth = style.strokeWidth

        val x = outputWidth / 2f
        val y = outputHeight / 2f

        if (strokeWidth > 0f) {
            val strokePaint = Paint(paint)
            strokePaint.style = Paint.Style.STROKE
            strokePaint.strokeWidth = strokeWidth
            strokePaint.color = Color.BLACK

            drawMultilineText(
                canvas = canvas,
                text = text.content,
                x = x,
                centerY = y,
                paint = strokePaint,
            )
        }

        paint.style = Paint.Style.FILL

        drawMultilineText(
            canvas = canvas,
            text = text.content,
            x = x,
            centerY = y,
            paint = paint,
        )

        val texture = NleTexture2dUtil.createTextureFromBitmap(bitmap)
        bitmap.recycle()

        cache[key] = texture

        return texture
    }

    private fun drawMultilineText(
        canvas: Canvas,
        text: String,
        x: Float,
        centerY: Float,
        paint: Paint,
    ) {
        val lines = text.split("\n")
        val lineHeight = paint.fontMetrics.let { it.descent - it.ascent }
        val totalHeight = lineHeight * lines.size
        var y = centerY - totalHeight / 2f - paint.fontMetrics.ascent

        for (line in lines) {
            canvas.drawText(line, x, y, paint)
            y += lineHeight
        }
    }

    private fun parseStyle(styleJson: String?): TextStyle {
        if (styleJson.isNullOrBlank()) return TextStyle()

        return try {
            val json = JSONObject(styleJson)

            TextStyle(
                fontSize = max(8.0, json.optDouble("fontSize", 48.0)).toFloat(),
                strokeWidth = json.optDouble("strokeWidth", 0.0).toFloat(),
                bold = json.optBoolean("bold", true),
                shadow = json.optBoolean("shadow", true),
            )
        } catch (_: Throwable) {
            TextStyle()
        }
    }

    private fun buildKey(
        layer: NleResolvedVisualLayer,
        outputWidth: Int,
        outputHeight: Int,
    ): String {
        val text = layer.clip.text

        return listOf(
            layer.clip.id,
            outputWidth,
            outputHeight,
            text?.content.orEmpty(),
            text?.styleJson.orEmpty(),
            text?.colorHex.orEmpty(),
        ).joinToString("|")
    }

    private fun parseColor(hex: String): Int {
        return try {
            Color.parseColor(hex)
        } catch (_: Throwable) {
            Color.WHITE
        }
    }

    fun release() {
        cache.values.forEach { it.releaseIfOwned() }
        cache.clear()
    }

    data class TextStyle(
        val fontSize: Float = 48f,
        val strokeWidth: Float = 0f,
        val bold: Boolean = true,
        val shadow: Boolean = true,
    )
}
