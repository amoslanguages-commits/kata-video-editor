package com.nle.editor.audio

import android.media.MediaCodec
import android.media.MediaFormat
import com.nle.editor.rendergraph.NleRenderGraph
import java.nio.ByteBuffer

class NleAudioTrackExporter {

    fun exportAudio(
        graph: NleRenderGraph,
        useOriginalForExport: Boolean,
        onOutputFormat: (MediaFormat) -> Unit,
        onEncodedSample: (ByteBuffer, MediaCodec.BufferInfo) -> Unit,
        onProgress: (Double) -> Unit = {},
    ) {
        val sampleRate = graph.audioMix.sampleRate.coerceAtLeast(8000)
        val channelCount = graph.audioMix.channels.coerceIn(1, 2)

        val format = NleAudioMixFormat(
            sampleRate = sampleRate,
            channelCount = channelCount,
        )

        val sourceCache = NleAudioSourceCache()

        val mixer = NlePcmMixer(
            sourceCache = sourceCache,
        )

        val stream = NleMixedPcmStream(
            graph = graph,
            mixer = mixer,
            format = format,
            chunkFrames = 2048,
        )

        val encoder = NleAacAudioEncoder(
            sampleRate = sampleRate,
            channelCount = channelCount,
        )

        try {
            sourceCache.prepare(
                graph = graph,
                useOriginalForExport = useOriginalForExport,
                targetSampleRate = sampleRate,
                targetChannels = channelCount,
            )

            encoder.start()

            while (stream.hasMore()) {
                val chunk = stream.nextChunk() ?: break

                encoder.queuePcmChunk(chunk)

                encoder.drain(
                    onFormat = onOutputFormat,
                    onSample = onEncodedSample,
                )

                val progress = chunk.startTimeUs.toDouble() /
                    graph.project.durationUs.toDouble().coerceAtLeast(1.0)

                onProgress(progress.coerceIn(0.0, 1.0))
            }

            encoder.signalEndOfStream()

            var done = false

            while (!done) {
                done = encoder.drain(
                    onFormat = onOutputFormat,
                    onSample = onEncodedSample,
                )
            }

            onProgress(1.0)
        } finally {
            encoder.release()
            sourceCache.clear()
        }
    }
}
