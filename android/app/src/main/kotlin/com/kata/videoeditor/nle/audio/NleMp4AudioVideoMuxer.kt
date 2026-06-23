package com.kata.videoeditor.nle.audio

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import com.kata.videoeditor.nle.NleNativeErrorCode
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

class NleMp4AudioVideoMuxer {
    fun mux(
        videoOnlyPath: String,
        audioM4aPath: String?,
        finalOutputPath: String,
        cancelled: AtomicBoolean,
        onProgress: (Int, String) -> Unit,
    ): String {
        if (audioM4aPath == null) {
            File(videoOnlyPath).copyTo(
                target = File(finalOutputPath),
                overwrite = true
            )
            return finalOutputPath
        }

        val outputFile = File(finalOutputPath)
        outputFile.parentFile?.mkdirs()

        if (outputFile.exists()) {
            outputFile.delete()
        }

        val videoExtractor = MediaExtractor()
        val audioExtractor = MediaExtractor()
        var muxer: MediaMuxer? = null

        try {
            videoExtractor.setDataSource(videoOnlyPath)
            audioExtractor.setDataSource(audioM4aPath)

            val videoTrackIndex = findTrack(videoExtractor, "video/")
            val audioTrackIndex = findTrack(audioExtractor, "audio/")

            if (videoTrackIndex < 0) {
                throw IllegalArgumentException("No video track found.")
            }

            if (audioTrackIndex < 0) {
                File(videoOnlyPath).copyTo(
                    target = outputFile,
                    overwrite = true
                )
                return finalOutputPath
            }

            videoExtractor.selectTrack(videoTrackIndex)
            audioExtractor.selectTrack(audioTrackIndex)

            val videoFormat = videoExtractor.getTrackFormat(videoTrackIndex)
            val audioFormat = audioExtractor.getTrackFormat(audioTrackIndex)

            muxer = MediaMuxer(
                finalOutputPath,
                MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
            )

            val muxVideoTrack = muxer.addTrack(videoFormat)
            val muxAudioTrack = muxer.addTrack(audioFormat)

            muxer.start()

            onProgress(84, "Muxing video track")

            copyTrackSamples(
                extractor = videoExtractor,
                muxer = muxer,
                muxTrackIndex = muxVideoTrack,
                cancelled = cancelled
            )

            onProgress(92, "Muxing audio track")

            copyTrackSamples(
                extractor = audioExtractor,
                muxer = muxer,
                muxTrackIndex = muxAudioTrack,
                cancelled = cancelled
            )

            onProgress(98, "Finalizing video with audio")

            if (!outputFile.exists() || outputFile.length() <= 0L) {
                throw IllegalStateException(NleNativeErrorCode.AUDIO_EXPORT_MUX_FAILED)
            }

            return finalOutputPath
        } catch (e: Throwable) {
            outputFile.delete()
            throw RuntimeException(
                "${NleNativeErrorCode.AUDIO_EXPORT_MUX_FAILED}: ${e.message}",
                e
            )
        } finally {
            try {
                muxer?.stop()
            } catch (_: Throwable) {
            }

            try {
                muxer?.release()
            } catch (_: Throwable) {
            }

            try {
                videoExtractor.release()
            } catch (_: Throwable) {
            }

            try {
                audioExtractor.release()
            } catch (_: Throwable) {
            }
        }
    }

    private fun findTrack(
        extractor: MediaExtractor,
        mimePrefix: String,
    ): Int {
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: continue

            if (mime.startsWith(mimePrefix)) {
                return i
            }
        }

        return -1
    }

    private fun copyTrackSamples(
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        muxTrackIndex: Int,
        cancelled: AtomicBoolean,
    ) {
        val bufferSize = 1024 * 1024
        val buffer = ByteBuffer.allocateDirect(bufferSize)
        val info = MediaCodec.BufferInfo()

        while (true) {
            if (cancelled.get()) {
                throw InterruptedException(NleNativeErrorCode.EXPORT_CANCELLED)
            }

            buffer.clear()

            val sampleSize = extractor.readSampleData(buffer, 0)

            if (sampleSize < 0) {
                break
            }

            info.offset = 0
            info.size = sampleSize
            info.presentationTimeUs = extractor.sampleTime
            info.flags = extractor.sampleFlags

            muxer.writeSampleData(
                muxTrackIndex,
                buffer,
                info
            )

            extractor.advance()
        }
    }
}
