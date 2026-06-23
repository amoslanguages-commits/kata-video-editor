package com.kata.videoeditor.nle

import java.util.concurrent.ConcurrentHashMap
import com.kata.videoeditor.nle.gpu.NleCompositorSession
import com.kata.videoeditor.nle.export.NleExportMode

/**
 * Registry and execution orchestrator for active [NleExportJob]s.
 *
 * Each job is executed on its own dedicated background thread.
 * The manager is thread-safe: the job map uses [ConcurrentHashMap].
 */
class NleExportJobManager(
    private val eventEmitter: NleNativeEventEmitter,
    private val compositorSession: NleCompositorSession
) {
    private val jobs = ConcurrentHashMap<String, NleExportJob>()

    /**
     * Creates and starts a new export job.
     *
     * @return A result map with `success = true` and the `jobId`.
     * @throws IllegalStateException if a job with the same [jobId] is already running.
     */
    fun startExportJob(
        projectId: String?,
        jobId: String,
        renderGraphJson: String,
        outputPath: String,
        profile: NleExportProfile,
        exportMode: NleExportMode
    ): Map<String, Any?> {
        if (jobs.containsKey(jobId)) {
            throw IllegalStateException(
                "${NleNativeErrorCode.EXPORT_JOB_ALREADY_RUNNING}: Job $jobId is already running."
            )
        }

        val job = NleExportJob(
            jobId             = jobId,
            projectId         = projectId,
            renderGraphJson   = renderGraphJson,
            outputPath        = outputPath,
            profile           = profile,
            exportMode        = exportMode,
            eventEmitter      = eventEmitter,
            compositorSession = compositorSession
        )

        jobs[jobId] = job

        kotlin.concurrent.thread(
            name        = "nle-export-$jobId",
            isDaemon    = true
        ) {
            try {
                job.run()
            } finally {
                jobs.remove(jobId)
            }
        }

        return mapOf("success" to true, "jobId" to jobId)
    }

    /**
     * Signals the job to stop.
     *
     * @return A result map with `success = true`.
     * @throws IllegalArgumentException if [jobId] is not found.
     */
    fun cancelExportJob(jobId: String): Map<String, Any?> {
        val job = jobs[jobId]
            ?: throw IllegalArgumentException(
                "${NleNativeErrorCode.EXPORT_JOB_NOT_FOUND}: Export job $jobId not found."
            )
        job.cancelled.set(true)
        return mapOf("success" to true, "jobId" to jobId)
    }

    /**
     * Cancels all running export jobs; called from [NleEngineManager.dispose].
     */
    fun dispose() {
        jobs.values.forEach { it.cancelled.set(true) }
        jobs.clear()
    }
}
