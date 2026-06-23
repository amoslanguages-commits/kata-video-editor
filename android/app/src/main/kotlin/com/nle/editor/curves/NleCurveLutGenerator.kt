package com.nle.editor.curves

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.max

object NleCurveLutGenerator {

    fun evaluate(curve: NleColorCurve, x: Float): Float {
        if (!curve.enabled || curve.points.isEmpty()) {
            return x.coerceIn(0f, 1f)
        }

        val points = curve.points.map { NleCurvePoint(it.x.coerceIn(0f, 1f), it.y.coerceIn(0f, 1f)) }
            .sortedBy { it.x }

        if (points.size == 1) {
            return points.first().y.coerceIn(0f, 1f)
        }

        val input = x.coerceIn(0f, 1f)

        if (input <= points.first().x) return points.first().y.coerceIn(0f, 1f)
        if (input >= points.last().x) return points.last().y.coerceIn(0f, 1f)

        for (i in 0 until points.size - 1) {
            val a = points[i]
            val b = points[i + 1]

            if (input >= a.x && input <= b.x) {
                val span = max(b.x - a.x, 0.00001f)
                val tRaw = (input - a.x) / span

                val t = if (curve.interpolation == NleCurveInterpolation.SMOOTH) {
                    smoothStep(tRaw)
                } else {
                    tRaw
                }

                val y = a.y + (b.y - a.y) * t

                val mixed = input + (y - input) * curve.intensity.coerceIn(0f, 1f)

                return mixed.coerceIn(0f, 1f)
            }
        }

        return input
    }

    private fun smoothStep(t: Float): Float {
        val x = t.coerceIn(0f, 1f)
        return x * x * (3f - 2f * x)
    }

    fun buildLookupTable(curve: NleColorCurve, size: Int = 256): FloatArray {
        val result = FloatArray(size)
        for (i in 0 until size) {
            val x = i.toFloat() / (size - 1)
            result[i] = evaluate(curve, x)
        }
        return result
    }

    fun buildPackedRgbCurveTexture(stack: NleColorCurveStack, size: Int = 256): FloatBuffer {
        val master = buildLookupTable(stack.curve(NleCurveType.RGB_MASTER), size)
        val red = buildLookupTable(stack.curve(NleCurveType.RED), size)
        val green = buildLookupTable(stack.curve(NleCurveType.GREEN), size)
        val blue = buildLookupTable(stack.curve(NleCurveType.BLUE), size)

        val packed = FloatArray(size * 4)
        for (i in 0 until size) {
            packed[i * 4] = master[i]
            packed[i * 4 + 1] = red[i]
            packed[i * 4 + 2] = green[i]
            packed[i * 4 + 3] = blue[i]
        }

        return ByteBuffer.allocateDirect(packed.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(packed)
                position(0)
            }
    }

    fun buildPackedHslCurveTextureA(stack: NleColorCurveStack, size: Int = 256): FloatBuffer {
        val hueVsSat = buildLookupTable(stack.curve(NleCurveType.HUE_VS_SAT), size)
        val hueVsHue = buildLookupTable(stack.curve(NleCurveType.HUE_VS_HUE), size)
        val hueVsLum = buildLookupTable(stack.curve(NleCurveType.HUE_VS_LUM), size)
        val lumVsSat = buildLookupTable(stack.curve(NleCurveType.LUM_VS_SAT), size)

        val packed = FloatArray(size * 4)
        for (i in 0 until size) {
            packed[i * 4] = hueVsSat[i]
            packed[i * 4 + 1] = hueVsHue[i]
            packed[i * 4 + 2] = hueVsLum[i]
            packed[i * 4 + 3] = lumVsSat[i]
        }

        return ByteBuffer.allocateDirect(packed.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(packed)
                position(0)
            }
    }

    fun buildPackedHslCurveTextureB(stack: NleColorCurveStack, size: Int = 256): FloatBuffer {
        val satVsSat = buildLookupTable(stack.curve(NleCurveType.SAT_VS_SAT), size)
        val luma = buildLookupTable(stack.curve(NleCurveType.LUMA), size)

        val packed = FloatArray(size * 4)
        for (i in 0 until size) {
            packed[i * 4] = satVsSat[i]
            packed[i * 4 + 1] = luma[i]
            packed[i * 4 + 2] = 0f
            packed[i * 4 + 3] = 1f
        }

        return ByteBuffer.allocateDirect(packed.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(packed)
                position(0)
            }
    }
}
