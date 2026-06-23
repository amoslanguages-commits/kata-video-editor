package com.kata.videoeditor.nle.export

/**
 * Selects which video export implementation is used for a given job.
 *
 * [BITMAP_PROTOTYPE] — Legacy V1 path: [com.kata.videoeditor.nle.NleTimelineFrameExporter].
 *   Uses MediaMetadataRetriever + Bitmap + Canvas.
 *   Available for debugging / regression testing via `"exportMode": "bitmap_v1"` in profile payload.
 *
 * [TRUE_DECODER_V2] — New V2 path: [NleTrueDecoderVideoExporter].
 *   Uses MediaCodec decoder → OES SurfaceTexture → GPU compositor → MediaCodec encoder surface.
 *   Default for all production exports.
 */
enum class NleExportMode {
    BITMAP_PROTOTYPE,
    TRUE_DECODER_V2,
}
