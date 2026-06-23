package com.nle.editor.scopes

import android.util.Log
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class NleScopeManager(
    private val sendEvent: (String, Map<String, Any?>) -> Unit
) {
    @Volatile
    var settings = NleScopeSettings(
        enabled = false,
        activeType = NleScopeType.WAVEFORM,
        colorSpace = NleScopeColorSpace.DISPLAY_REFERRED,
        showSkinToneLine = true,
        showClippingWarnings = true,
        showGrid = true,
        showOverlay = false,
        refreshFps = 12.0,
        sampleWidth = 256,
        sampleHeight = 144
    )
        private set

    @Volatile
    private var isLive = false

    @Volatile
    private var activeMonitorId: String? = null

    private val singleFrameRequested = AtomicBoolean(false)
    
    @Volatile
    private var requestedFrameTimestamp = -1L

    private val backgroundExecutor = Executors.newSingleThreadExecutor()

    @Volatile
    private var lastProcessedTimeMs = 0L

    val sampleWidth: Int
        get() = settings.sampleWidth

    val sampleHeight: Int
        get() = settings.sampleHeight

    val colorSpace: NleScopeColorSpace
        get() = settings.colorSpace

    fun configure(nextSettings: NleScopeSettings) {
        settings = nextSettings
        Log.d("NleScopeManager", "Configured scopes: $settings")
    }

    fun startLive(monitorId: String) {
        isLive = true
        activeMonitorId = monitorId
        Log.d("NleScopeManager", "Started live scopes for monitor: $monitorId")
    }

    fun stopLive() {
        isLive = false
        activeMonitorId = null
        Log.d("NleScopeManager", "Stopped live scopes")
    }

    fun requestFrame(monitorId: String, timestampMicros: Long) {
        activeMonitorId = monitorId
        requestedFrameTimestamp = timestampMicros
        singleFrameRequested.set(true)
        Log.d("NleScopeManager", "Requested single scope frame for monitor: $monitorId at $timestampMicros")
    }

    fun shouldProcess(monitorId: String, timestampMicros: Long): Boolean {
        if (!settings.enabled) return false

        // Check if this monitor is active
        if (activeMonitorId != monitorId) return false

        // Check if single frame is requested
        if (singleFrameRequested.get() && timestampMicros == requestedFrameTimestamp) {
            return true
        }

        // Check if live mode is active
        if (isLive) {
            val now = System.currentTimeMillis()
            val intervalMs = (1000.0 / settings.refreshFps).toLong()
            if (now - lastProcessedTimeMs >= intervalMs) {
                return true
            }
        }

        return false
    }

    fun processFrame(
        monitorId: String,
        rgbaBytes: ByteArray,
        width: Int,
        height: Int,
        timestampMicros: Long
    ) {
        // Update last processed time
        if (isLive && activeMonitorId == monitorId) {
            lastProcessedTimeMs = System.currentTimeMillis()
        }
        
        // Reset single frame request flag if we matched
        if (singleFrameRequested.get() && timestampMicros == requestedFrameTimestamp) {
            singleFrameRequested.set(false)
        }

        val currentSettings = settings

        backgroundExecutor.submit {
            try {
                val rgbaBuffer = java.nio.ByteBuffer.wrap(rgbaBytes)
                val payload = NleScopeProcessor.processFrame(
                    rgbaBuffer = rgbaBuffer,
                    width = width,
                    height = height,
                    timestampMicros = timestampMicros,
                    settings = currentSettings
                )

                // Emit back to Flutter using event sink channel
                val eventPayload = payload + mapOf("monitorId" to monitorId)
                sendEvent("scopes_frame_data", eventPayload)
            } catch (e: Throwable) {
                Log.e("NleScopeManager", "Failed to process scopes frame on background thread", e)
            }
        }
    }

    fun release() {
        backgroundExecutor.shutdown()
    }
}
