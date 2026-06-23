package com.kata.videoeditor.nle

import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

class NleProxyJobManager(private val eventEmitter: NleNativeEventEmitter) {
    private val executor = Executors.newSingleThreadExecutor()
    private val activeJobs = ConcurrentHashMap<String, NleProxyJob>()

    fun startProxyJob(
        projectId: String?,
        jobId: String,
        assetId: String,
        inputPath: String,
        outputPath: String,
        profile: NleProxyProfile
    ): Map<String, Any?> {
        cancelProxyJob(jobId)

        val job = NleProxyJob(
            jobId = jobId,
            projectId = projectId,
            assetId = assetId,
            inputPath = inputPath,
            outputPath = outputPath,
            profile = profile,
            eventEmitter = eventEmitter
        )

        activeJobs[jobId] = job
        executor.submit {
            try {
                job.run()
            } finally {
                activeJobs.remove(jobId)
            }
        }

        return mapOf(
            "success" to true,
            "jobId" to jobId
        )
    }

    fun cancelProxyJob(jobId: String): Map<String, Any?> {
        val job = activeJobs.remove(jobId)
        if (job != null) {
            job.cancelled.set(true)
            return mapOf(
                "success" to true,
                "jobId" to jobId,
                "cancelled" to true
            )
        }
        return mapOf(
            "success" to false,
            "errorCode" to NleNativeErrorCode.JOB_NOT_FOUND,
            "message" to "Proxy job with id $jobId not found."
        )
    }

    fun cancelAll() {
        val keys = activeJobs.keys()
        while (keys.hasMoreElements()) {
            val key = keys.nextElement()
            val job = activeJobs.remove(key)
            job?.cancelled?.set(true)
        }
    }

    fun dispose() {
        cancelAll()
        executor.shutdownNow()
    }
}
