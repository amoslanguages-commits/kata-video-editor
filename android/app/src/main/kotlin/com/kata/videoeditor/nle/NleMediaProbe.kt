package com.kata.videoeditor.nle

import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import java.io.File

class NleMediaProbe {
    data class Result(
        val width: Int,
        val height: Int,
        val rotation: Int,
        val durationUs: Long,
        val fps: Int
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "width" to width,
            "height" to height,
            "rotation" to rotation,
            "durationUs" to durationUs,
            "fps" to fps
        )
    }

    fun probe(path: String): Result {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("File does not exist: $path")
        }

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val widthStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
            val heightStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
            val rotationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
            val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)

            val width = widthStr?.toIntOrNull() ?: 0
            val height = heightStr?.toIntOrNull() ?: 0
            val rotation = rotationStr?.toIntOrNull() ?: 0
            val durationMs = durationStr?.toLongOrNull() ?: 0L
            val durationUs = durationMs * 1000L

            var fps = 30
            val extractor = MediaExtractor()
            try {
                extractor.setDataSource(path)
                for (i in 0 until extractor.trackCount) {
                    val format = extractor.getTrackFormat(i)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                    if (mime.startsWith("video/")) {
                        if (format.containsKey(MediaFormat.KEY_FRAME_RATE)) {
                            fps = format.getInteger(MediaFormat.KEY_FRAME_RATE)
                        }
                        break
                    }
                }
            } catch (e: Exception) {
                // Keep default 30 fps
            } finally {
                extractor.release()
            }

            return Result(
                width = width,
                height = height,
                rotation = rotation,
                durationUs = durationUs,
                fps = fps
            )
        } finally {
            retriever.release()
        }
    }
}
