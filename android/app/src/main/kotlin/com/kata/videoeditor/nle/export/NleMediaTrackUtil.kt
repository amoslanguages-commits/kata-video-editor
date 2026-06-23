package com.kata.videoeditor.nle.export

import android.media.MediaExtractor
import android.media.MediaFormat

/**
 * Helpers for selecting and inspecting video tracks via [MediaExtractor] / [MediaFormat].
 */
object NleMediaTrackUtil {

    /**
     * Selects the first video track in [extractor] and returns its (index, format) pair.
     *
     * @throws IllegalStateException if no video track exists.
     */
    fun selectFirstVideoTrack(extractor: MediaExtractor): Pair<Int, MediaFormat> {
        var bestIndex = -1
        var bestFormat: MediaFormat? = null
        var bestScore = -1

        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime   = format.getString(MediaFormat.KEY_MIME) ?: continue

            if (mime.startsWith("video/")) {
                var score = 0
                if (mime == "video/avc") score = 100
                else if (mime == "video/hevc") score = 90
                else if (mime == "video/mp4v-es") score = 50
                else if (mime == "video/dolby-vision") score = 10 // heavily penalize to avoid NAME_NOT_FOUND decoder crash
                else score = 20

                if (score > bestScore) {
                    bestScore = score
                    bestIndex = i
                    bestFormat = format
                }
            }
        }

        if (bestIndex >= 0) {
            extractor.selectTrack(bestIndex)
            return Pair(bestIndex, bestFormat!!)
        }

        throw IllegalStateException("No video track found in source.")
    }

    /** Returns [MediaFormat.KEY_WIDTH] or 0 if absent. */
    fun formatWidth(format: MediaFormat): Int =
        if (format.containsKey(MediaFormat.KEY_WIDTH)) format.getInteger(MediaFormat.KEY_WIDTH)
        else 0

    /** Returns [MediaFormat.KEY_HEIGHT] or 0 if absent. */
    fun formatHeight(format: MediaFormat): Int =
        if (format.containsKey(MediaFormat.KEY_HEIGHT)) format.getInteger(MediaFormat.KEY_HEIGHT)
        else 0

    /** Returns the video rotation in degrees, or 0 if the key is absent. */
    fun formatRotation(format: MediaFormat): Int =
        if (format.containsKey("rotation-degrees")) format.getInteger("rotation-degrees")
        else 0
}
