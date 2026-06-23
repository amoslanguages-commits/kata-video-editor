package com.kata.videoeditor.nle

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.atomic.AtomicBoolean

class NleProxyGenerator : MethodChannel.MethodCallHandler {

    private val executor = Executors.newFixedThreadPool(2)
    private val activeJobs = ConcurrentHashMap<String, JobState>()

    private val mainHandler = Handler(Looper.getMainLooper())

    private data class JobState(
        val cancelled: AtomicBoolean,
        val future: Future<*>
    )

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "proxy_generate" -> {
                val jobId = call.argument<String>("jobId")
                val sourcePath = call.argument<String>("sourcePath")
                val outputPath = call.argument<String>("outputPath")
                val targetHeight = call.argument<Int>("maxHeight") ?: 720
                val bitrate = call.argument<Int>("bitrate") ?: 2500000
                val fpsLimit = call.argument<Double>("fpsLimit") ?: 30.0
                val codec = call.argument<String>("codec") ?: "video/avc"

                if (jobId == null || sourcePath == null || outputPath == null) {
                    result.error("BAD_ARGS", "Missing required arguments for proxy generation", null)
                    return
                }

                val profile = NleProxyProfile(
                    targetHeight = targetHeight,
                    frameRate = fpsLimit.toInt(),
                    videoBitrate = bitrate,
                    iFrameIntervalSeconds = 2,
                    codec = codec
                )

                val cancelled = AtomicBoolean(false)
                val future = executor.submit {
                    try {
                        val transcoder = NleFrameProxyTranscoder()
                        transcoder.transcode(
                            inputPath = sourcePath,
                            outputPath = outputPath,
                            profile = profile,
                            cancelled = cancelled
                        ) { progress ->
                            // Background progress reporting is not strictly required by 34B-PRO
                        }

                        if (cancelled.get()) {
                            postToMain {
                                result.error("CANCELLED", "Proxy generation was cancelled", null)
                            }
                        } else {
                            val probe = NleMediaProbe().probe(outputPath)
                            val file = File(outputPath)
                            val fileSize = file.length()

                            postToMain {
                                result.success(mapOf(
                                    "proxyPath" to outputPath,
                                    "width" to probe.width,
                                    "height" to probe.height,
                                    "fps" to probe.fps.toDouble(),
                                    "bitrate" to bitrate,
                                    "fileSizeBytes" to fileSize,
                                    "durationMicros" to probe.durationUs,
                                    "codec" to codec
                                ))
                            }
                        }
                    } catch (e: Exception) {
                        postToMain {
                            result.error("TRANSCODE_FAILED", e.message, e.stackTraceToString())
                        }
                    } finally {
                        activeJobs.remove(jobId)
                    }
                }

                activeJobs[jobId] = JobState(cancelled, future)
            }
            "proxy_cancel" -> {
                val jobId = call.argument<String>("jobId")
                if (jobId != null) {
                    val job = activeJobs.remove(jobId)
                    if (job != null) {
                        job.cancelled.set(true)
                        job.future.cancel(true)
                    }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun postToMain(action: () -> Unit) {
        mainHandler.post(action)
    }
}
