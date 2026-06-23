package com.kata.videoeditor.nle

import android.media.MediaRecorder
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class NleVoiceRecorder {
    private var recorder: MediaRecorder? = null
    private var isRecording = false
    private var isPaused = false
    private var outputPath: String? = null
    private var sampleRate: Int = 48000
    private var channels: Int = 1
    private var bitrate: Int = 128000
    private var startTimeMs: Long = 0
    private var pauseTimeMs: Long = 0
    private var totalPausedTimeMs: Long = 0

    fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "voice_prepare" -> {
                val path = call.argument<String>("outputPath")
                val sRate = call.argument<Int>("sampleRate") ?: 48000
                val chCount = call.argument<Int>("channelCount") ?: 1
                val bRate = call.argument<Int>("bitrate") ?: 128000

                if (path == null) {
                    result.error("INVALID_ARGUMENT", "outputPath is required", null)
                    return
                }

                try {
                    prepare(path, sRate, chCount, bRate)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("PREPARE_FAILED", e.message, null)
                }
            }
            "voice_start" -> {
                try {
                    start()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("START_FAILED", e.message, null)
                }
            }
            "voice_pause" -> {
                try {
                    pause()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("PAUSE_FAILED", e.message, null)
                }
            }
            "voice_resume" -> {
                try {
                    resume()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("RESUME_FAILED", e.message, null)
                }
            }
            "voice_stop" -> {
                try {
                    val stopResult = stop()
                    result.success(stopResult)
                } catch (e: Exception) {
                    result.error("STOP_FAILED", e.message, null)
                }
            }
            "voice_cancel" -> {
                try {
                    cancel()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("CANCEL_FAILED", e.message, null)
                }
            }
            "voice_meter" -> {
                result.success(getMeter())
            }
            "voice_is_recording" -> {
                result.success(isRecording)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun prepare(path: String, sRate: Int, chCount: Int, bRate: Int) {
        releaseRecorder()
        outputPath = path
        sampleRate = sRate
        channels = chCount
        bitrate = bRate

        val file = File(path)
        file.parentFile?.mkdirs()

        val r = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(NleContextHolder.context!!)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        r.setAudioSource(MediaRecorder.AudioSource.MIC)
        r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        r.setAudioSamplingRate(sampleRate)
        r.setAudioChannels(channels)
        r.setAudioEncodingBitRate(bitrate)
        r.setOutputFile(outputPath)

        r.prepare()
        recorder = r
        isRecording = false
        isPaused = false
        totalPausedTimeMs = 0
    }

    private fun start() {
        val r = recorder ?: throw IllegalStateException("Recorder not prepared")
        r.start()
        isRecording = true
        isPaused = false
        startTimeMs = System.currentTimeMillis()
        totalPausedTimeMs = 0
    }

    private fun pause() {
        if (!isRecording || isPaused) return
        val r = recorder ?: throw IllegalStateException("Recorder not prepared")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            r.pause()
            isPaused = true
            pauseTimeMs = System.currentTimeMillis()
        }
    }

    private fun resume() {
        if (!isRecording || !isPaused) return
        val r = recorder ?: throw IllegalStateException("Recorder not prepared")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            r.resume()
            isPaused = false
            totalPausedTimeMs += System.currentTimeMillis() - pauseTimeMs
        }
    }

    private fun stop(): Map<String, Any?> {
        val r = recorder ?: throw IllegalStateException("Recorder not prepared")
        if (isRecording) {
            try {
                r.stop()
            } catch (e: Exception) {
                // Ignore stop exception if recorder has no data
            }
        }
        val durationMs = if (startTimeMs > 0) {
            val endTime = System.currentTimeMillis()
            val currentPaused = if (isPaused) endTime - pauseTimeMs else 0
            (endTime - startTimeMs - totalPausedTimeMs - currentPaused).coerceAtLeast(0)
        } else {
            0
        }
        val path = outputPath ?: ""
        
        releaseRecorder()

        val formatInfo = mapOf(
            "sampleRate" to sampleRate,
            "channels" to channels,
            "bitDepth" to 16,
            "codec" to "aac",
            "bitrate" to bitrate
        )

        return mapOf(
            "outputPath" to path,
            "durationMicros" to durationMs * 1000L,
            "formatInfo" to formatInfo
        )
    }

    private fun cancel() {
        val path = outputPath
        releaseRecorder()
        if (path != null) {
            try {
                File(path).delete()
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    private fun getMeter(): Map<String, Any?> {
        val r = recorder
        var peak = 0.0
        var rms = 0.0
        var clipping = false
        if (r != null && isRecording && !isPaused) {
            try {
                val maxAmp = r.maxAmplitude.toDouble()
                peak = maxAmp / 32767.0
                rms = peak * 0.707
                if (peak >= 0.99) {
                    clipping = true
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
        return mapOf(
            "peak" to peak,
            "rms" to rms,
            "clipping" to clipping
        )
    }

    private fun releaseRecorder() {
        recorder?.let {
            try {
                it.release()
            } catch (e: Exception) {}
        }
        recorder = null
        isRecording = false
        isPaused = false
        outputPath = null
    }
}
