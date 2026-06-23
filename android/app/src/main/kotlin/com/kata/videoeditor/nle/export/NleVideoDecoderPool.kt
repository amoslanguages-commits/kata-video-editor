package com.kata.videoeditor.nle.export

/**
 * Cache of [NleVideoSourceDecoder] instances keyed by asset ID.
 *
 * Decoders are created and prepared lazily on first access.
 * Call [releaseAll] in a `finally` block at the end of the export job.
 *
 * V2 supports one active decoder per unique source asset. A single-clip
 * timeline will therefore only ever have one entry in the pool.
 */
class NleVideoDecoderPool {

    private val decoders = linkedMapOf<String, NleVideoSourceDecoder>()
    private val maxCacheSize = 8

    /**
     * Returns the decoder for [asset], creating and preparing it if necessary.
     *
     * Must be called from the GL/export thread (the decoder's [NleDecoderOutputSurface]
     * allocates an OES texture which requires an active EGL context).
     */
    fun decoderFor(asset: NleTrueExportAsset): NleVideoSourceDecoder {
        val existing = decoders.remove(asset.id)
        if (existing != null) {
            if (existing.asset.path == asset.path) {
                decoders[asset.id] = existing
                return existing
            } else {
                try { existing.release() } catch (_: Throwable) {}
            }
        }

        val decoder = NleVideoSourceDecoder(asset).also { it.prepare() }
        decoders[asset.id] = decoder

        if (decoders.size > maxCacheSize) {
            val eldestKey = decoders.keys.first()
            val eldest = decoders.remove(eldestKey)
            try { eldest?.release() } catch (_: Throwable) {}
        }
        return decoder
    }

    /**
     * Stops and releases all decoders and their output surfaces.
     *
     * Safe to call even if [decoderFor] was never called.
     */
    fun releaseAll() {
        for (decoder in decoders.values) {
            try {
                decoder.release()
            } catch (_: Throwable) {
                // Best-effort cleanup; do not propagate.
            }
        }
        decoders.clear()
    }
}
