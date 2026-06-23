package com.kata.videoeditor.nle

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class NleMediaScanner {

    fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "media_scan" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGUMENT", "Path is required", null)
                    return
                }
                try {
                    val scanResult = scanFile(path)
                    result.success(scanResult)
                } catch (e: Exception) {
                    result.error("SCAN_FAILED", e.message, null)
                }
            }
            "media_generate_thumbnail" -> {
                val path = call.argument<String>("path")
                val outputPath = call.argument<String>("outputPath")
                val width = call.argument<Int>("width") ?: 512
                val height = call.argument<Int>("height") ?: 512

                if (path == null || outputPath == null) {
                    result.error("INVALID_ARGUMENT", "Path and outputPath are required", null)
                    return
                }
                try {
                    val thumbPath = generateThumbnail(path, outputPath, width, height)
                    result.success(thumbPath)
                } catch (e: Exception) {
                    result.error("THUMBNAIL_FAILED", e.message, null)
                }
            }
            "media_file_exists" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.success(false)
                    return
                }
                result.success(File(path).exists())
            }
            else -> result.notImplemented()
        }
    }

    private fun scanFile(path: String): Map<String, Any?> {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("File does not exist: $path")
        }

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val mime = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE) ?: ""
            
            var type = "unknown"
            if (mime.startsWith("video/")) {
                type = "video"
            } else if (mime.startsWith("audio/")) {
                type = "audio"
            } else if (mime.startsWith("image/")) {
                type = "image"
            }

            val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
            val durationMicros = durationMs * 1000L

            val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
            val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
            val bitrate = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)?.toIntOrNull() ?: 0

            var fps = 30.0
            var sampleRate = 0
            var channelCount = 0
            var videoCodec = ""
            var audioCodec = ""
            var colorSpace = "rec709"
            var hasHdr = false

            // Use MediaExtractor to get precise details for audio/video tracks
            val extractor = MediaExtractor()
            try {
                extractor.setDataSource(path)
                for (i in 0 until extractor.trackCount) {
                    val format = extractor.getTrackFormat(i)
                    val trackMime = format.getString(MediaFormat.KEY_MIME) ?: ""
                    
                    if (trackMime.startsWith("video/")) {
                        videoCodec = trackMime
                        if (format.containsKey(MediaFormat.KEY_FRAME_RATE)) {
                            fps = format.getInteger(MediaFormat.KEY_FRAME_RATE).toDouble()
                        }
                        
                        // Detect HDR and Color space
                        if (format.containsKey("color-transfer")) {
                            val transfer = format.getInteger("color-transfer")
                            // 6 = HLG, 7 = HDR10 / SMPTE ST 2084
                            if (transfer == 6 || transfer == 7) {
                                hasHdr = true
                                colorSpace = "bt2020"
                            }
                        }
                    } else if (trackMime.startsWith("audio/")) {
                        audioCodec = trackMime
                        if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
                            sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                        }
                        if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
                            channelCount = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore extractor failures
            } finally {
                extractor.release()
            }

            // Fallback for image type resolution if retriever metadata is empty
            var finalWidth = width
            var finalHeight = height
            if (type == "image" && (width == 0 || height == 0)) {
                val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(path, options)
                finalWidth = options.outWidth
                finalHeight = options.outHeight
            }

            return mapOf(
                "path" to path,
                "type" to type,
                "durationMicros" to durationMicros,
                "width" to finalWidth,
                "height" to finalHeight,
                "fps" to fps,
                "sampleRate" to sampleRate,
                "channelCount" to channelCount,
                "bitrate" to bitrate,
                "videoCodec" to videoCodec,
                "audioCodec" to audioCodec,
                "colorSpace" to colorSpace,
                "hasHdr" to hasHdr
            )
        } finally {
            retriever.release()
        }
    }

    private fun generateThumbnail(path: String, outputPath: String, width: Int, height: Int): String? {
        val file = File(path)
        if (!file.exists()) {
            return null
        }

        var bitmap: Bitmap? = null

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val mime = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE) ?: ""

            if (mime.startsWith("video/")) {
                bitmap = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            } else if (mime.startsWith("image/")) {
                bitmap = BitmapFactory.decodeFile(path)
            }
        } catch (e: Exception) {
            // Ignore, try bitmap decode as fallback
        } finally {
            retriever.release()
        }

        if (bitmap == null) {
            // Fallback: decode directly if it was an image
            try {
                bitmap = BitmapFactory.decodeFile(path)
            } catch (e: Exception) {
                return null
            }
        }

        if (bitmap == null) {
            return null
        }

        // Scale bitmap to requested size (preserving aspect ratio)
        val srcWidth = bitmap.width
        val srcHeight = bitmap.height
        val ratio = srcWidth.toFloat() / srcHeight.toFloat()
        var targetWidth = width
        var targetHeight = height

        if (srcWidth > srcHeight) {
            targetHeight = (targetWidth / ratio).toInt()
        } else {
            targetWidth = (targetHeight * ratio).toInt()
        }

        val scaled = Bitmap.createScaledBitmap(bitmap, targetWidth.coerceAtLeast(1), targetHeight.coerceAtLeast(1), true)
        
        val outFile = File(outputPath)
        outFile.parentFile?.mkdirs()
        
        val out = FileOutputStream(outFile)
        scaled.compress(Bitmap.CompressFormat.JPEG, 85, out)
        out.flush()
        out.close()

        if (scaled != bitmap) {
            scaled.recycle()
        }
        bitmap.recycle()

        return outputPath
    }
}
