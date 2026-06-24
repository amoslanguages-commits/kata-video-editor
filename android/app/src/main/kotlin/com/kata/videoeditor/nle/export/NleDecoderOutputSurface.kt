package com.kata.videoeditor.nle.export

import android.graphics.SurfaceTexture
import android.opengl.GLES20
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.view.Surface
import com.kata.videoeditor.nle.NleNativeErrorCode
import com.kata.videoeditor.nle.gpu.NleOesTextureUtil

/**
 * A single decoded video frame ready for GPU compositing.
 *
 * @property oesTextureId     The `GL_TEXTURE_EXTERNAL_OES` texture ID containing the frame.
 * @property textureTransform The 4×4 texture-coordinate transform matrix from
 *                            [SurfaceTexture.getTransformMatrix]. Must be applied in the
 *                            OES shader to correctly orient the decoded image.
 * @property presentationTimeUs Frame presentation timestamp in microseconds.
 */
class NleDecodedVideoFrame(
    val oesTextureId: Int,
    val textureTransform: FloatArray,
    val presentationTimeUs: Long,
)

/**
 * Wraps a [SurfaceTexture] / [Surface] pair that receives frames from a [android.media.MediaCodec]
 * decoder and exposes them as an OES texture for the GPU compositor.
 *
 * Construction must happen on the GL thread (the OES texture requires an active EGL context).
 * [awaitFrameAndUpdate] must also be called on the GL thread so that [SurfaceTexture.updateTexImage]
 * runs in the correct context.
 */
class NleDecoderOutputSurface : SurfaceTexture.OnFrameAvailableListener {

    private val frameSyncObject = Object()
    private var frameAvailable  = false
    private var released        = false

    /** The OES texture ID (valid for the lifetime of this surface). */
    val oesTextureId: Int = NleOesTextureUtil.createOesTexture()

    /** The [SurfaceTexture] backed by [oesTextureId]. */
    val surfaceTexture: SurfaceTexture = SurfaceTexture(oesTextureId)

    /** The [Surface] passed to [android.media.MediaCodec.configure] as the decoder output. */
    val surface: Surface = Surface(surfaceTexture)

    private val transform = FloatArray(16)

    companion object {
        private val callbackThread by lazy {
            HandlerThread("NleDecoderCallbackThread").apply { start() }
        }
    }

    init {
        surfaceTexture.setOnFrameAvailableListener(
            this,
            Handler(callbackThread.looper),
        )
    }

    // ── SurfaceTexture.OnFrameAvailableListener ───────────────────────────────

    override fun onFrameAvailable(surfaceTexture: SurfaceTexture?) {
        synchronized(frameSyncObject) {
            frameAvailable = true
            frameSyncObject.notifyAll()
        }
    }

    // ── Frame access ─────────────────────────────────────────────────────────

    /**
     * Blocks until a new frame is available (or [timeoutMs] elapses), then calls
     * [SurfaceTexture.updateTexImage] to latch the frame into [oesTextureId].
     *
     * @param timeoutMs Maximum wait in milliseconds. Defaults to 2 500 ms.
     * @return The latched [NleDecodedVideoFrame] with the OES texture and transform matrix.
     * @throws RuntimeException on timeout or if this surface has already been released.
     */
    fun awaitFrameAndUpdate(timeoutMs: Long = 2_500L): NleDecodedVideoFrame {
        synchronized(frameSyncObject) {
            if (!frameAvailable) {
                try {
                    frameSyncObject.wait(timeoutMs)
                } catch (e: InterruptedException) {
                    Thread.currentThread().interrupt()
                    throw RuntimeException(NleNativeErrorCode.EXPORT_DECODER_TIMEOUT, e)
                }
            }

            if (!frameAvailable) {
                throw RuntimeException(
                    "${NleNativeErrorCode.EXPORT_DECODER_TIMEOUT}: Timed out waiting for decoder frame after ${timeoutMs}ms."
                )
            }

            frameAvailable = false
        }

        check(!released) { "NleDecoderOutputSurface.awaitFrameAndUpdate called after release()." }

        surfaceTexture.updateTexImage()
        surfaceTexture.getTransformMatrix(transform)

        // SurfaceTexture.timestamp is in nanoseconds; convert to microseconds.
        val ptsUs = surfaceTexture.timestamp / 1_000L

        return NleDecodedVideoFrame(
            oesTextureId      = oesTextureId,
            textureTransform  = transform.copyOf(),
            presentationTimeUs = ptsUs,
        )
    }

    // ── Release ──────────────────────────────────────────────────────────────

    /**
     * Releases the [Surface], [SurfaceTexture], and GL texture.
     *
     * Must be called on the GL thread while the EGL context is still current.
     */
    fun release() {
        released = true
        try { surface.release()       } catch (_: Throwable) {}
        try { surfaceTexture.release() } catch (_: Throwable) {}
        try {
            GLES20.glDeleteTextures(1, intArrayOf(oesTextureId), 0)
        } catch (_: Throwable) {}
    }
}
