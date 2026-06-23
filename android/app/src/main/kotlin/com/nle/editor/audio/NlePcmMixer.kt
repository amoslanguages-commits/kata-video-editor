package com.nle.editor.audio

import com.nle.editor.rendergraph.NleRenderGraph

class NlePcmMixer(
    private val sourceCache: NleAudioSourceCache,
) {
    private val resolver = NleAudioLayerResolver()
    private val tempStereo = FloatArray(2)
    private val masterStereo = FloatArray(2)
    private var effectProcessor: NleAudioEffectRackProcessor? = null
    private var lastSampleRate = 0

    fun mixChunk(
        graph: NleRenderGraph,
        startTimeUs: Long,
        frameCount: Int,
        format: NleAudioMixFormat,
    ): NlePcmChunk {
        if (effectProcessor == null || lastSampleRate != format.sampleRate) {
            effectProcessor = NleAudioEffectRackProcessor(format.sampleRate)
            lastSampleRate = format.sampleRate
        }
        val processor = effectProcessor!!

        val chunkDurationUs =
            ((frameCount.toDouble() / format.sampleRate.toDouble()) * 1_000_000.0).toLong()

        val endTimeUs = startTimeUs + chunkDurationUs

        val layers = resolver.resolveWindow(
            graph = graph,
            windowStartUs = startTimeUs,
            windowEndUs = endTimeUs,
        )

        val output = FloatArray(frameCount * format.channelCount)

        for (frame in 0 until frameCount) {
            val timelineTimeUs = startTimeUs +
                ((frame.toDouble() / format.sampleRate.toDouble()) * 1_000_000.0).toLong()

            var masterSumL = 0f
            var masterSumR = 0f

            // Group active layers by track
            val activeLayers = layers.filter {
                timelineTimeUs >= it.timelineStartUs && timelineTimeUs < it.timelineEndUs
            }
            val layersByTrack = activeLayers.groupBy { it.track.id }

            for ((_, trackLayers) in layersByTrack) {
                var trackSumL = 0f
                var trackSumR = 0f

                for (layer in trackLayers) {
                    val assetId = layer.clip.assetId ?: continue
                    val source = sourceCache.get(assetId) ?: continue

                    val localUs = timelineTimeUs - layer.timelineStartUs

                    val sourceTimeUs = layer.sourceStartUs +
                        (localUs * safeSpeed(layer.clip.speed)).toLong()

                    if (sourceTimeUs < layer.sourceStartUs ||
                        sourceTimeUs >= layer.sourceEndUs
                    ) {
                        continue
                    }

                    source.sampleAtStereo(
                        sourceTimeUs = sourceTimeUs,
                        out = tempStereo,
                    )

                    // 1. Apply clip-level effect chain before clip gain/automation
                    processor.processChain(layer.clip.effectChain, tempStereo)

                    // 2. Apply clip gain/pan/fades/automation
                    val gain = NleAudioMath.gainForLayerAtTimelineTime(
                        layer = layer,
                        timelineTimeUs = timelineTimeUs,
                    )

                    trackSumL += tempStereo[0] * gain
                    trackSumR += tempStereo[1] * gain
                }

                // 3. Apply track-level effect chain to track-summed PCM samples
                val trackStereo = floatArrayOf(trackSumL, trackSumR)
                val track = trackLayers.first().track
                processor.processChain(track.effectChain, trackStereo)

                // 4. Apply track volume/pan/ducking/automation
                val trackVolume = if (track.isMuted) 0f else 1f
                masterSumL += trackStereo[0] * trackVolume
                masterSumR += trackStereo[1] * trackVolume
            }

            // 5. Apply project master limiter (LimiterDsp) to summed master output
            masterStereo[0] = masterSumL
            masterStereo[1] = masterSumR
            processor.processChain(graph.audioMix.masterEffectChain, masterStereo)

            val safeL = NleAudioMath.softClip(masterStereo[0])
            val safeR = NleAudioMath.softClip(masterStereo[1])

            if (format.channelCount == 1) {
                output[frame] = (safeL + safeR) * 0.5f
            } else {
                output[frame * format.channelCount] = safeL
                output[frame * format.channelCount + 1] = safeR

                for (ch in 2 until format.channelCount) {
                    output[frame * format.channelCount + ch] = 0f
                }
            }
        }

        return NlePcmChunk(
            startTimeUs = startTimeUs,
            sampleRate = format.sampleRate,
            channelCount = format.channelCount,
            frames = frameCount,
            data = output,
        )
    }

    private fun safeSpeed(speed: Double): Double {
        return if (speed <= 0.0) 1.0 else speed
    }
}
