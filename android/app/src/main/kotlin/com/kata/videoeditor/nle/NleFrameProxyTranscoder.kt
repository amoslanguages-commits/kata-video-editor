package com.kata.videoeditor.nle

import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

class NleFrameProxyTranscoder {

    fun transcode(
        inputPath: String,
        outputPath: String,
        profile: NleProxyProfile,
        cancelled: AtomicBoolean,
        onProgress: (Int) -> Unit
    ) {
        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()

        val probe = NleMediaProbe().probe(inputPath)
        val durationUs = probe.durationUs
        val originalWidth = probe.width
        val originalHeight = probe.height

        if (durationUs <= 0L || originalWidth <= 0 || originalHeight <= 0) {
            throw IllegalArgumentException("Invalid input video dimensions or duration")
        }

        // Calculate target dimensions keeping aspect ratio (width and height must be even)
        val scale = profile.targetHeight.toFloat() / originalHeight.toFloat()
        val targetHeight = profile.targetHeight
        var targetWidth = ((originalWidth * scale).toInt() / 2) * 2
        if (targetWidth <= 0) targetWidth = 2

        val format = MediaFormat.createVideoFormat(profile.codec, targetWidth, targetHeight).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar)
            setInteger(MediaFormat.KEY_BIT_RATE, profile.videoBitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, profile.frameRate)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, profile.iFrameIntervalSeconds)
        }

        val encoder = MediaCodec.createEncoderByType(profile.codec)
        val retriever = MediaMetadataRetriever()
        var muxer: MediaMuxer? = null

        var encoderStarted = false
        var muxerStarted = false
        var trackIndex = -1

        try {
            retriever.setDataSource(inputPath)
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            encoder.start()
            encoderStarted = true

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            val bufferInfo = MediaCodec.BufferInfo()
            val frameIntervalUs = 1_000_000L / profile.frameRate
            var currentTimeUs = 0L

            val yuvSize = targetWidth * targetHeight * 3 / 2
            val yuvBuffer = ByteArray(yuvSize)

            var isEOS = false

            while (!isEOS && !cancelled.get()) {
                // 1. Queue input buffers
                if (currentTimeUs < durationUs) {
                    val inputBufferIndex = encoder.dequeueInputBuffer(10000)
                    if (inputBufferIndex >= 0) {
                        val inputBuffer = encoder.getInputBuffer(inputBufferIndex)!!
                        inputBuffer.clear()

                        val bitmap = retriever.getFrameAtTime(currentTimeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                        if (bitmap != null) {
                            val scaled = Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
                            convertBitmapToNV12(scaled, yuvBuffer)
                            if (scaled != bitmap) {
                                scaled.recycle()
                            }
                            bitmap.recycle()

                            inputBuffer.put(yuvBuffer)
                            encoder.queueInputBuffer(
                                inputBufferIndex,
                                0,
                                yuvSize,
                                currentTimeUs,
                                0
                            )

                            val progress = ((currentTimeUs.toFloat() / durationUs.toFloat()) * 100).toInt().coerceIn(0, 99)
                            onProgress(progress)

                            currentTimeUs += frameIntervalUs
                        } else {
                            // If we can't extract a frame, send EOS to finish encoding
                            encoder.queueInputBuffer(
                                inputBufferIndex,
                                0,
                                0,
                                currentTimeUs,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            currentTimeUs = durationUs
                        }
                    }
                } else if (currentTimeUs == durationUs) {
                    val inputBufferIndex = encoder.dequeueInputBuffer(10000)
                    if (inputBufferIndex >= 0) {
                        encoder.queueInputBuffer(
                            inputBufferIndex,
                            0,
                            0,
                            currentTimeUs,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM
                        )
                        currentTimeUs = durationUs + 1 // sentinel to not queue again
                    }
                }

                // 2. Dequeue output buffers
                val outputBufferIndex = encoder.dequeueOutputBuffer(bufferInfo, 10000)
                if (outputBufferIndex >= 0) {
                    val outputBuffer = encoder.getOutputBuffer(outputBufferIndex)!!

                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
                        bufferInfo.size = 0
                    }

                    if (bufferInfo.size > 0 && muxerStarted) {
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                    }

                    encoder.releaseOutputBuffer(outputBufferIndex, false)

                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        isEOS = true
                    }
                } else if (outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    if (muxerStarted) {
                        throw IllegalStateException("Muxer already started / format changed twice")
                    }
                    val newFormat = encoder.outputFormat
                    trackIndex = muxer.addTrack(newFormat)
                    muxer.start()
                    muxerStarted = true
                }
            }

            if (!cancelled.get()) {
                onProgress(100)
            } else {
                // If cancelled, clean up partial file
                try {
                    outputFile.delete()
                } catch (e: Exception) {
                    // Ignore
                }
            }
        } finally {
            try {
                if (encoderStarted) {
                    encoder.stop()
                }
            } catch (e: Exception) {
                // Ignore
            } finally {
                encoder.release()
            }

            retriever.release()

            if (muxerStarted) {
                try {
                    muxer?.stop()
                } catch (e: Exception) {
                    // Ignore
                }
            }
            try {
                muxer?.release()
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    private fun convertBitmapToNV12(bitmap: Bitmap, yuv: ByteArray) {
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

        val size = width * height
        var yIndex = 0
        var uvIndex = size

        for (y in 0 until height) {
            for (x in 0 until width) {
                val argb = pixels[y * width + x]
                val r = (argb shr 16) and 0xff
                val g = (argb shr 8) and 0xff
                val b = argb and 0xff

                val Y = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                yuv[yIndex++] = Y.coerceIn(0, 255).toByte()

                if (y % 2 == 0 && x % 2 == 0) {
                    val U = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                    val V = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128

                    yuv[uvIndex++] = U.coerceIn(0, 255).toByte()
                    yuv[uvIndex++] = V.coerceIn(0, 255).toByte()
                }
            }
        }
    }
}
