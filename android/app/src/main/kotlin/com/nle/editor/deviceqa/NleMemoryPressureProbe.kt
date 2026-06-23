package com.nle.editor.deviceqa

import android.app.ActivityManager
import android.content.Context

data class NleMemoryPressureResult(
    val beforeAvailableMb: Long,
    val afterAvailableMb: Long,
    val allocatedMb: Long,
    val survived: Boolean,
    val message: String,
)

/**
 * Allocates [allocateMb] MB in-process to test whether the device can sustain
 * the expected memory load during video editing.
 *
 * ⚠️ Debug/internal only — do not call automatically in production.
 */
class NleMemoryPressureProbe(
    private val context: Context,
) {
    fun runLightProbe(allocateMb: Int = 128): NleMemoryPressureResult {
        val before = availableMemoryMb()

        return try {
            val blocks    = mutableListOf<ByteArray>()
            val blockSize = 8 * 1024 * 1024          // 8 MB per block
            val count     = allocateMb / 8

            repeat(count) { blocks.add(ByteArray(blockSize)) }

            val after = availableMemoryMb()
            blocks.clear()
            System.gc()

            NleMemoryPressureResult(
                beforeAvailableMb = before,
                afterAvailableMb  = after,
                allocatedMb       = allocateMb.toLong(),
                survived          = true,
                message           = "Memory pressure probe survived.",
            )
        } catch (error: OutOfMemoryError) {
            NleMemoryPressureResult(
                beforeAvailableMb = before,
                afterAvailableMb  = availableMemoryMb(),
                allocatedMb       = allocateMb.toLong(),
                survived          = false,
                message           = "OutOfMemory during probe: ${error.message}",
            )
        }
    }

    private fun availableMemoryMb(): Long {
        val am   = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        am.getMemoryInfo(info)
        return info.availMem / (1024L * 1024L)
    }
}
