package com.nle.editor.scopes

import java.nio.ByteBuffer
import kotlin.math.*

object NleScopeProcessor {

    fun processFrame(
        rgbaBuffer: ByteBuffer,
        width: Int,
        height: Int,
        timestampMicros: Long,
        settings: NleScopeSettings
    ): Map<String, Any> {
        val totalPixels = width * height
        
        // Histograms (256 bins)
        val lumaHist = IntArray(256)
        val redHist = IntArray(256)
        val greenHist = IntArray(256)
        val blueHist = IntArray(256)
        
        // Clipping counters
        var blackClipCount = 0
        var whiteClipCount = 0
        var redClipCount = 0
        var greenClipCount = 0
        var blueClipCount = 0
        var satWarningCount = 0
        
        // Grids for Waveform, Parade, Vectorscope density
        // Waveform: width columns, 100 vertical bins
        val numWaveformBins = 100
        val waveformCounts = Array(width) { IntArray(numWaveformBins) }
        
        // Vectorscope: 100x100 grid for vx, vy in [-1.0, 1.0]
        val numVectorBins = 100
        val vectorCounts = Array(numVectorBins) { IntArray(numVectorBins) }
        
        // For Parade points, we'll collect the normalized RGB values for every pixel.
        // To prevent massive JSON payload and slow rendering, we can sample the pixels.
        // Since Parade requires drawing R, G, B channels side-by-side, we can just retain
        // the color coordinates of a downsampled subgrid.
        // Let's decide target parade size: e.g. 128 width, 72 height
        val paradeWidth = min(width, 128)
        val paradeHeight = min(height, 72)
        val stepX = max(1, width / paradeWidth)
        val stepY = max(1, height / paradeHeight)
        
        val paradePoints = mutableListOf<Map<String, Any>>()
        
        rgbaBuffer.rewind()
        
        for (y in 0 until height) {
            for (x in 0 until width) {
                val index = (y * width + x) * 4
                if (index + 3 >= rgbaBuffer.remaining()) break
                
                val rInt = rgbaBuffer.get(index).toInt() and 0xFF
                val gInt = rgbaBuffer.get(index + 1).toInt() and 0xFF
                val bInt = rgbaBuffer.get(index + 2).toInt() and 0xFF
                
                val r = rInt / 255.0
                val g = gInt / 255.0
                val b = bInt / 255.0
                
                // Luma calculation
                val yVal = 0.299 * r + 0.587 * g + 0.114 * b
                val yInt = clamp((yVal * 255.0).roundToInt(), 0, 255)
                
                // 1. Histograms
                lumaHist[yInt]++
                redHist[rInt]++
                greenHist[gInt]++
                blueHist[bInt]++
                
                // 2. Clipping
                if (yVal <= 0.01) blackClipCount++
                if (yVal >= 0.99) whiteClipCount++
                if (r >= 0.99) redClipCount++
                if (g >= 0.99) greenClipCount++
                if (b >= 0.99) blueClipCount++
                
                // HSL Hue and Saturation
                val maxC = max(r, max(g, b))
                val minC = min(r, min(g, b))
                val delta = maxC - minC
                
                var h = 0.0
                var s = 0.0
                val l = (maxC + minC) / 2.0
                
                if (delta > 0.0) {
                    h = when (maxC) {
                        r -> ((g - b) / delta) % 6.0
                        g -> ((b - r) / delta) + 2.0
                        else -> ((r - g) / delta) + 4.0
                    }
                    h /= 6.0
                    if (h < 0.0) h += 1.0
                    
                    s = delta / (1.0 - abs(2.0 * l - 1.0))
                }
                
                if (s >= 0.95) satWarningCount++
                
                // 3. Waveform Grid
                val wBin = clamp((yVal * numWaveformBins).toInt(), 0, numWaveformBins - 1)
                waveformCounts[x][wBin]++
                
                // 4. Vectorscope Grid
                val angle = h * 2.0 * Math.PI
                val vx = s * cos(angle)
                val vy = s * sin(angle)
                val gx = clamp(((vx + 1.0) / 2.0 * numVectorBins).toInt(), 0, numVectorBins - 1)
                val gy = clamp(((vy + 1.0) / 2.0 * numVectorBins).toInt(), 0, numVectorBins - 1)
                vectorCounts[gx][gy]++
                
                // 5. Parade sampling
                if (x % stepX == 0 && y % stepY == 0) {
                    val px = x.toDouble() / (width - 1.0)
                    val py = y.toDouble() / (height - 1.0)
                    paradePoints.add(
                        mapOf(
                            "x" to px,
                            "y" to py,
                            "red" to r,
                            "green" to g,
                            "blue" to b
                        )
                    )
                }
            }
        }
        
        // Format Waveform points
        val waveformPoints = mutableListOf<Map<String, Any>>()
        for (x in 0 until width) {
            var colMax = 0
            for (w in 0 until numWaveformBins) {
                if (waveformCounts[x][w] > colMax) {
                    colMax = waveformCounts[x][w]
                }
            }
            val divisor = max(1, colMax).toDouble()
            val px = x.toDouble() / (width - 1.0)
            for (w in 0 until numWaveformBins) {
                val count = waveformCounts[x][w]
                if (count > 0) {
                    val py = w.toDouble() / (numWaveformBins - 1.0)
                    waveformPoints.add(
                        mapOf(
                            "x" to px,
                            "y" to py,
                            "intensity" to (count.toDouble() / divisor)
                        )
                    )
                }
            }
        }
        
        // Format Vectorscope points
        val vectorPoints = mutableListOf<Map<String, Any>>()
        var vecMax = 0
        for (gx in 0 until numVectorBins) {
            for (gy in 0 until numVectorBins) {
                if (vectorCounts[gx][gy] > vecMax) {
                    vecMax = vectorCounts[gx][gy]
                }
            }
        }
        val vecDivisor = max(1, vecMax).toDouble()
        for (gx in 0 until numVectorBins) {
            for (gy in 0 until numVectorBins) {
                val count = vectorCounts[gx][gy]
                if (count > 0) {
                    val vx = (gx.toDouble() / (numVectorBins - 1.0)) * 2.0 - 1.0
                    val vy = (gy.toDouble() / (numVectorBins - 1.0)) * 2.0 - 1.0
                    vectorPoints.add(
                        mapOf(
                            "x" to vx,
                            "y" to vy,
                            "intensity" to (count.toDouble() / vecDivisor)
                        )
                    )
                }
            }
        }
        
        // Normalize histograms
        val normLuma = lumaHist.map { it.toDouble() / totalPixels }
        val normRed = redHist.map { it.toDouble() / totalPixels }
        val normGreen = greenHist.map { it.toDouble() / totalPixels }
        val normBlue = blueHist.map { it.toDouble() / totalPixels }
        
        val blackClipPercent = (blackClipCount.toDouble() / totalPixels) * 100.0
        val whiteClipPercent = (whiteClipCount.toDouble() / totalPixels) * 100.0
        val redClipPercent = (redClipCount.toDouble() / totalPixels) * 100.0
        val greenClipPercent = (greenClipCount.toDouble() / totalPixels) * 100.0
        val blueClipPercent = (blueClipCount.toDouble() / totalPixels) * 100.0
        val saturationWarningPercent = (satWarningCount.toDouble() / totalPixels) * 100.0
        
        val warnings = mapOf(
            "blackClipping" to (blackClipPercent > 0.05),
            "whiteClipping" to (whiteClipPercent > 0.05),
            "redChannelClipping" to (redClipPercent > 0.05),
            "greenChannelClipping" to (greenClipPercent > 0.05),
            "blueChannelClipping" to (blueClipPercent > 0.05),
            "overSaturated" to (saturationWarningPercent > 0.05),
            "blackClipPercent" to blackClipPercent,
            "whiteClipPercent" to whiteClipPercent,
            "redClipPercent" to redClipPercent,
            "greenClipPercent" to greenClipPercent,
            "blueClipPercent" to blueClipPercent,
            "saturationWarningPercent" to saturationWarningPercent
        )
        
        val histogram = mapOf(
            "luma" to normLuma,
            "red" to normRed,
            "green" to normGreen,
            "blue" to normBlue
        )
        
        return mapOf(
            "frameTimestampMicros" to timestampMicros,
            "sampleWidth" to width,
            "sampleHeight" to height,
            "waveform" to waveformPoints,
            "rgbParade" to paradePoints,
            "vectorscope" to vectorPoints,
            "histogram" to histogram,
            "warnings" to warnings
        )
    }
    
    private fun clamp(value: Int, min: Int, max: Int): Int {
        return max(min, min(max, value))
    }
}
