package com.nle.editor.deviceqa

import android.app.ActivityManager
import android.content.Context
import android.os.Build

class NleDeviceInfoCollector(
    private val context: Context,
) {
    fun collectBasicInfo(): BasicDeviceInfo {
        val activityManager =
            context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)

        val totalMemoryMb     = memoryInfo.totalMem / (1024L * 1024L)
        val availableMemoryMb = memoryInfo.availMem / (1024L * 1024L)
        val maxMemoryMb       = Runtime.getRuntime().maxMemory() / (1024L * 1024L)
        val cores             = Runtime.getRuntime().availableProcessors().coerceAtLeast(1)

        return BasicDeviceInfo(
            manufacturer      = Build.MANUFACTURER.orEmpty(),
            brand             = Build.BRAND.orEmpty(),
            model             = Build.MODEL.orEmpty(),
            device            = Build.DEVICE.orEmpty(),
            hardware          = Build.HARDWARE.orEmpty(),
            androidSdk        = Build.VERSION.SDK_INT,
            androidRelease    = Build.VERSION.RELEASE.orEmpty(),
            supportedAbis     = Build.SUPPORTED_ABIS.toList(),
            totalMemoryMb     = totalMemoryMb,
            availableMemoryMb = availableMemoryMb,
            maxMemoryMb       = maxMemoryMb,
            cpuCoreCount      = cores,
            deviceTier        = classifyTier(
                totalMemoryMb = totalMemoryMb,
                cpuCoreCount  = cores,
                maxMemoryMb   = maxMemoryMb,
            ),
        )
    }

    private fun classifyTier(
        totalMemoryMb: Long,
        cpuCoreCount: Int,
        maxMemoryMb: Long,
    ): NleDeviceTier {
        return when {
            totalMemoryMb < 3072L || cpuCoreCount <= 4 || maxMemoryMb < 256L ->
                NleDeviceTier.LOW_END

            totalMemoryMb < 6144L || cpuCoreCount <= 6 || maxMemoryMb < 512L ->
                NleDeviceTier.MID_RANGE

            totalMemoryMb >= 6144L && cpuCoreCount >= 8 ->
                NleDeviceTier.HIGH_END

            else -> NleDeviceTier.UNKNOWN
        }
    }

    data class BasicDeviceInfo(
        val manufacturer: String,
        val brand: String,
        val model: String,
        val device: String,
        val hardware: String,
        val androidSdk: Int,
        val androidRelease: String,
        val supportedAbis: List<String>,
        val totalMemoryMb: Long,
        val availableMemoryMb: Long,
        val maxMemoryMb: Long,
        val cpuCoreCount: Int,
        val deviceTier: NleDeviceTier,
    )
}
