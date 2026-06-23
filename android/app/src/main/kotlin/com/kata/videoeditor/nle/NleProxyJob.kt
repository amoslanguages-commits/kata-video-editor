package com.kata.videoeditor.nle

import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

class NleProxyJob(
    val jobId: String,
    val projectId: String?,
    val assetId: String,
    val inputPath: String,
    val outputPath: String,
    val profile: NleProxyProfile,
    private val eventEmitter: NleNativeEventEmitter
) : Runnable {

    val cancelled = AtomicBoolean(false)

    override fun run() {
        eventEmitter.emit(
            NleNativeEvent(
                type = NleNativeEventType.PROXY_STARTED,
                projectId = projectId,
                jobId = jobId,
                payload = mapOf(
                    "assetId" to assetId,
                    "progress" to 0
                )
            )
        )

        try {
            val transcoder = NleFrameProxyTranscoder()
            transcoder.transcode(
                inputPath = inputPath,
                outputPath = outputPath,
                profile = profile,
                cancelled = cancelled,
                onProgress = { progress ->
                    eventEmitter.emit(
                        NleNativeEvent(
                            type = NleNativeEventType.PROXY_PROGRESS,
                            projectId = projectId,
                            jobId = jobId,
                            payload = mapOf(
                                "assetId" to assetId,
                                "progress" to progress
                            )
                        )
                    )
                }
            )

            if (cancelled.get()) {
                eventEmitter.emit(
                    NleNativeEvent(
                        type = NleNativeEventType.PROXY_CANCELLED,
                        projectId = projectId,
                        jobId = jobId,
                        payload = mapOf(
                            "assetId" to assetId
                        )
                    )
                )
            } else {
                val outFile = File(outputPath)
                val fileSize = if (outFile.exists()) outFile.length() else 0L

                // We can probe the generated proxy to get its actual width/height
                var width = 0
                var height = 0
                try {
                    val p = NleMediaProbe().probe(outputPath)
                    width = p.width
                    height = p.height
                } catch (e: Exception) {
                    // Fallback
                    width = profile.targetHeight
                    height = profile.targetHeight
                }

                eventEmitter.emit(
                    NleNativeEvent(
                        type = NleNativeEventType.PROXY_COMPLETED,
                        projectId = projectId,
                        jobId = jobId,
                        payload = mapOf(
                            "assetId" to assetId,
                            "result" to mapOf(
                                "outputPath" to outputPath,
                                "fileSize" to fileSize,
                                "width" to width,
                                "height" to height,
                                "codec" to profile.codec
                            )
                        )
                    )
                )
            }
        } catch (e: Exception) {
            if (cancelled.get()) {
                eventEmitter.emit(
                    NleNativeEvent(
                        type = NleNativeEventType.PROXY_CANCELLED,
                        projectId = projectId,
                        jobId = jobId,
                        payload = mapOf(
                            "assetId" to assetId
                        )
                    )
                )
            } else {
                eventEmitter.emitError(
                    projectId = projectId,
                    sessionId = null,
                    commandId = null,
                    code = NleNativeErrorCode.PROXY_TRANSCODE_FAILED,
                    message = "Proxy generation failed: ${e.localizedMessage}",
                    technicalMessage = e.stackTraceToString()
                )
                eventEmitter.emit(
                    NleNativeEvent(
                        type = NleNativeEventType.PROXY_FAILED,
                        projectId = projectId,
                        jobId = jobId,
                        payload = mapOf(
                            "assetId" to assetId,
                            "errorCode" to NleNativeErrorCode.PROXY_TRANSCODE_FAILED,
                            "errorMessage" to e.localizedMessage
                        )
                    )
                )
            }
        }
    }
}
