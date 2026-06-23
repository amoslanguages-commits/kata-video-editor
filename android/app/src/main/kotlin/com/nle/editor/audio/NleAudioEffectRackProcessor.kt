package com.nle.editor.audio

import com.nle.editor.rendergraph.NleRenderEffectChain
import com.nle.editor.rendergraph.NleRenderEffectSlot
import com.nle.editor.rendergraph.NleEq3BandSettings
import com.nle.editor.rendergraph.NleCompressorSettings
import com.nle.editor.rendergraph.NleLimiterSettings
import com.nle.editor.rendergraph.NleNoiseGateSettings
import com.nle.editor.rendergraph.NleNoiseReductionSettings
import com.nle.editor.rendergraph.NleReverbSettings
import com.nle.editor.rendergraph.NlePitchTempoSettings
import com.nle.editor.rendergraph.NleVoiceEnhancerSettings

class NleAudioEffectRackProcessor(val sampleRate: Int) {
    private val sampleRateF = sampleRate.toFloat()
    private val tempOut = FloatArray(2)

    // Caches to hold stateful DSPs per slot ID
    private val eq3BandDSPs = mutableMapOf<String, Eq3BandDsp>()
    private val compressorDSPs = mutableMapOf<String, CompressorDsp>()
    private val limiterDSPs = mutableMapOf<String, LimiterDsp>()
    private val noiseGateDSPs = mutableMapOf<String, NoiseGateDsp>()
    private val reverbDSPs = mutableMapOf<String, ReverbDsp>()
    private val voiceEnhancerDSPs = mutableMapOf<String, VoiceEnhancerDsp>()
    private val noiseReductionDSPs = mutableMapOf<String, NoiseReductionDsp>()

    fun processChain(chain: NleRenderEffectChain?, samples: FloatArray) {
        if (chain == null || !chain.enabled) return

        val orderedSlots = chain.slots.sortedBy { it.order }
        for (slot in orderedSlots) {
            if (!slot.active) continue

            when (slot.type) {
                "eq3Band" -> {
                    val settings = slot.eq3Band ?: continue
                    val dsp = eq3BandDSPs.getOrPut(slot.id) { Eq3BandDsp(sampleRateF) }
                    processEq3Band(dsp, settings, slot.wetMix, samples)
                }
                "compressor" -> {
                    val settings = slot.compressor ?: continue
                    val dsp = compressorDSPs.getOrPut(slot.id) { CompressorDsp(sampleRateF) }
                    processCompressor(dsp, settings, slot.wetMix, samples)
                }
                "limiter" -> {
                    val settings = slot.limiter ?: continue
                    val dsp = limiterDSPs.getOrPut(slot.id) { LimiterDsp(sampleRateF) }
                    processLimiter(dsp, settings, slot.wetMix, samples)
                }
                "noiseGate" -> {
                    val settings = slot.noiseGate ?: continue
                    val dsp = noiseGateDSPs.getOrPut(slot.id) { NoiseGateDsp(sampleRateF) }
                    processNoiseGate(dsp, settings, slot.wetMix, samples)
                }
                "noiseReduction" -> {
                    val settings = slot.noiseReduction ?: continue
                    val dsp = noiseReductionDSPs.getOrPut(slot.id) { NoiseReductionDsp(sampleRateF) }
                    processNoiseReduction(dsp, settings, slot.wetMix, samples)
                }
                "reverb" -> {
                    val settings = slot.reverb ?: continue
                    val dsp = reverbDSPs.getOrPut(slot.id) { ReverbDsp(sampleRateF) }
                    processReverb(dsp, settings, slot.wetMix, samples)
                }
                "pitchTempo" -> {
                    // Pitch/Tempo shifts are handled via timeline speeds, this is a placeholder/hook
                }
                "voiceEnhancer" -> {
                    val settings = slot.voiceEnhancer ?: continue
                    val dsp = voiceEnhancerDSPs.getOrPut(slot.id) { VoiceEnhancerDsp(sampleRateF) }
                    processVoiceEnhancer(dsp, settings, slot.wetMix, samples)
                }
            }
        }
    }

    private fun processEq3Band(dsp: Eq3BandDsp, settings: NleEq3BandSettings, wetMix: Float, samples: FloatArray) {
        val len = samples.size
        var i = 0
        while (i < len) {
            val l = samples[i]
            val r = if (i + 1 < len) samples[i + 1] else l

            dsp.process(
                l, r,
                settings.lowGainDb, settings.midGainDb, settings.highGainDb,
                settings.lowFrequencyHz, settings.highFrequencyHz,
                tempOut
            )

            samples[i] = l + (tempOut[0] - l) * wetMix
            if (i + 1 < len) {
                samples[i + 1] = r + (tempOut[1] - r) * wetMix
            }
            i += 2
        }
    }

    private fun processCompressor(dsp: CompressorDsp, settings: NleCompressorSettings, wetMix: Float, samples: FloatArray) {
        val len = samples.size
        var i = 0
        while (i < len) {
            val l = samples[i]
            val r = if (i + 1 < len) samples[i + 1] else l

            dsp.process(
                l, r,
                settings.thresholdDb, settings.ratio,
                settings.attackMs, settings.releaseMs,
                settings.makeupGainDb, settings.kneeDb,
                tempOut
            )

            samples[i] = l + (tempOut[0] - l) * wetMix
            if (i + 1 < len) {
                samples[i + 1] = r + (tempOut[1] - r) * wetMix
            }
            i += 2
        }
    }

    private fun processLimiter(dsp: LimiterDsp, settings: NleLimiterSettings, wetMix: Float, samples: FloatArray) {
        val len = samples.size
        var i = 0
        while (i < len) {
            val l = samples[i]
            val r = if (i + 1 < len) samples[i + 1] else l

            dsp.process(l, r, settings.ceilingDb, settings.releaseMs, tempOut)

            samples[i] = l + (tempOut[0] - l) * wetMix
            if (i + 1 < len) {
                samples[i + 1] = r + (tempOut[1] - r) * wetMix
            }
            i += 2
        }
    }

    private fun processNoiseGate(dsp: NoiseGateDsp, settings: NleNoiseGateSettings, wetMix: Float, samples: FloatArray) {
        val len = samples.size
        var i = 0
        while (i < len) {
            val l = samples[i]
            val r = if (i + 1 < len) samples[i + 1] else l

            dsp.process(
                l, r,
                settings.thresholdDb, settings.reductionDb,
                settings.attackMs, settings.releaseMs,
                tempOut
            )

            samples[i] = l + (tempOut[0] - l) * wetMix
            if (i + 1 < len) {
                samples[i + 1] = r + (tempOut[1] - r) * wetMix
            }
            i += 2
        }
    }

    private fun processNoiseReduction(dsp: NoiseReductionDsp, settings: NleNoiseReductionSettings, wetMix: Float, samples: FloatArray) {
        val len = samples.size
        var i = 0
        while (i < len) {
            val l = samples[i]
            val r = if (i + 1 < len) samples[i + 1] else l

            dsp.process(l, r, settings.amount, settings.voiceOptimized, tempOut)

            samples[i] = l + (tempOut[0] - l) * wetMix
            if (i + 1 < len) {
                samples[i + 1] = r + (tempOut[1] - r) * wetMix
            }
            i += 2
        }
    }

    private fun processReverb(dsp: ReverbDsp, settings: NleReverbSettings, wetMix: Float, samples: FloatArray) {
        val len = samples.size
        var i = 0
        while (i < len) {
            val l = samples[i]
            val r = if (i + 1 < len) samples[i + 1] else l

            dsp.process(
                l, r,
                settings.roomSize, settings.damping,
                settings.wet, settings.dry,
                tempOut
            )

            samples[i] = l + (tempOut[0] - l) * wetMix
            if (i + 1 < len) {
                samples[i + 1] = r + (tempOut[1] - r) * wetMix
            }
            i += 2
        }
    }

    private fun processVoiceEnhancer(dsp: VoiceEnhancerDsp, settings: NleVoiceEnhancerSettings, wetMix: Float, samples: FloatArray) {
        val len = samples.size
        var i = 0
        while (i < len) {
            val l = samples[i]
            val r = if (i + 1 < len) samples[i + 1] else l

            dsp.process(
                l, r,
                settings.clarity, settings.body,
                settings.air, settings.deEss,
                tempOut
            )

            samples[i] = l + (tempOut[0] - l) * wetMix
            if (i + 1 < len) {
                samples[i + 1] = r + (tempOut[1] - r) * wetMix
            }
            i += 2
        }
    }

    fun clear() {
        eq3BandDSPs.clear()
        compressorDSPs.clear()
        limiterDSPs.clear()
        noiseGateDSPs.clear()
        reverbDSPs.clear()
        voiceEnhancerDSPs.clear()
        noiseReductionDSPs.clear()
    }

    // ==========================================
    // DSP IMPLEMENTATIONS
    // ==========================================

    class Biquad {
        var b0 = 1f; var b1 = 0f; var b2 = 0f
        var a1 = 0f; var a2 = 0f
        var x1 = 0f; var x2 = 0f
        var y1 = 0f; var y2 = 0f

        fun process(inSample: Float): Float {
            val outSample = b0 * inSample + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2 = x1
            x1 = inSample
            val cl = if (outSample.isNaN() || outSample.isInfinite()) 0f else outSample
            y2 = y1
            y1 = cl
            return cl
        }

        fun setLowPass(freq: Float, sampleRate: Float, q: Float = 0.707f) {
            val omega = (2.0 * Math.PI * freq / sampleRate).toFloat()
            val cosOmega = Math.cos(omega.toDouble()).toFloat()
            val alpha = (Math.sin(omega.toDouble()) / (2.0 * q)).toFloat()
            val a0 = 1f + alpha
            b0 = ((1f - cosOmega) / 2f) / a0
            b1 = (1f - cosOmega) / a0
            b2 = ((1f - cosOmega) / 2f) / a0
            a1 = (-2f * cosOmega) / a0
            a2 = (1f - alpha) / a0
        }

        fun setHighPass(freq: Float, sampleRate: Float, q: Float = 0.707f) {
            val omega = (2.0 * Math.PI * freq / sampleRate).toFloat()
            val cosOmega = Math.cos(omega.toDouble()).toFloat()
            val alpha = (Math.sin(omega.toDouble()) / (2.0 * q)).toFloat()
            val a0 = 1f + alpha
            b0 = ((1f + cosOmega) / 2f) / a0
            b1 = -(1f + cosOmega) / a0
            b2 = ((1f + cosOmega) / 2f) / a0
            a1 = (-2f * cosOmega) / a0
            a2 = (1f - alpha) / a0
        }

        fun setPeaking(freq: Float, sampleRate: Float, gainDb: Float, q: Float = 1.0f) {
            val a = Math.pow(10.0, (gainDb / 40.0).toDouble()).toFloat()
            val omega = (2.0 * Math.PI * freq / sampleRate).toFloat()
            val cosOmega = Math.cos(omega.toDouble()).toFloat()
            val alpha = (Math.sin(omega.toDouble()) / (2.0 * q)).toFloat()
            val a0 = 1f + (alpha / a)
            b0 = (1f + (alpha * a)) / a0
            b1 = (-2f * cosOmega) / a0
            b2 = (1f - (alpha * a)) / a0
            a1 = (-2f * cosOmega) / a0
            a2 = (1f - (alpha / a)) / a0
        }

        fun setHighShelf(freq: Float, sampleRate: Float, gainDb: Float, q: Float = 0.707f) {
            val a = Math.pow(10.0, (gainDb / 40.0).toDouble()).toFloat()
            val omega = (2.0 * Math.PI * freq / sampleRate).toFloat()
            val cosOmega = Math.cos(omega.toDouble()).toFloat()
            val alpha = (Math.sin(omega.toDouble()) / (2.0 * q)).toFloat()
            val sa = 2.0f * Math.sqrt(a.toDouble()).toFloat() * alpha
            val a0 = (a + 1f) - (a - 1f) * cosOmega + sa
            b0 = (a * ((a + 1f) + (a - 1f) * cosOmega + sa)) / a0
            b1 = (-2f * a * ((a - 1f) + (a + 1f) * cosOmega)) / a0
            b2 = (a * ((a + 1f) + (a - 1f) * cosOmega - sa)) / a0
            a1 = (2f * ((a - 1f) - (a + 1f) * cosOmega)) / a0
            a2 = ((a + 1f) - (a - 1f) * cosOmega - sa) / a0
        }

        fun setLowShelf(freq: Float, sampleRate: Float, gainDb: Float, q: Float = 0.707f) {
            val a = Math.pow(10.0, (gainDb / 40.0).toDouble()).toFloat()
            val omega = (2.0 * Math.PI * freq / sampleRate).toFloat()
            val cosOmega = Math.cos(omega.toDouble()).toFloat()
            val alpha = (Math.sin(omega.toDouble()) / (2.0 * q)).toFloat()
            val sa = 2.0f * Math.sqrt(a.toDouble()).toFloat() * alpha
            val a0 = (a + 1f) + (a - 1f) * cosOmega + sa
            b0 = (a * ((a + 1f) - (a - 1f) * cosOmega + sa)) / a0
            b1 = (2f * a * ((a - 1f) - (a + 1f) * cosOmega)) / a0
            b2 = (a * ((a + 1f) - (a - 1f) * cosOmega - sa)) / a0
            a1 = (-2f * ((a - 1f) + (a + 1f) * cosOmega)) / a0
            a2 = ((a + 1f) - (a - 1f) * cosOmega - sa) / a0
        }
    }

    class Eq3BandDsp(val sampleRate: Float) {
        private val lpL = Biquad()
        private val lpR = Biquad()
        private val hpL = Biquad()
        private val hpR = Biquad()

        fun process(sampleL: Float, sampleR: Float, lowGainDb: Float, midGainDb: Float, highGainDb: Float, lowFreq: Float, highFreq: Float, out: FloatArray) {
            lpL.setLowPass(lowFreq, sampleRate, 0.5f)
            lpR.setLowPass(lowFreq, sampleRate, 0.5f)

            hpL.setHighPass(highFreq, sampleRate, 0.5f)
            hpR.setHighPass(highFreq, sampleRate, 0.5f)

            val lowGain = Math.pow(10.0, (lowGainDb / 20.0)).toFloat()
            val midGain = Math.pow(10.0, (midGainDb / 20.0)).toFloat()
            val highGain = Math.pow(10.0, (highGainDb / 20.0)).toFloat()

            val lL = lpL.process(sampleL)
            val hL = hpL.process(sampleL)
            val mL = sampleL - lL - hL

            val lR = lpR.process(sampleR)
            val hR = hpR.process(sampleR)
            val mR = sampleR - lR - hR

            out[0] = lL * lowGain + mL * midGain + hL * highGain
            out[1] = lR * lowGain + mR * midGain + hR * highGain
        }
    }

    class CompressorDsp(val sampleRate: Float) {
        private var envelope = 0f

        fun process(sampleL: Float, sampleR: Float, thresholdDb: Float, ratio: Float, attackMs: Float, releaseMs: Float, makeupGainDb: Float, kneeDb: Float, out: FloatArray) {
            val peak = Math.max(Math.abs(sampleL), Math.abs(sampleR))

            val attackCoef = Math.exp(-1.0 / (attackMs * 0.001f * sampleRate)).toFloat()
            val releaseCoef = Math.exp(-1.0 / (releaseMs * 0.001f * sampleRate)).toFloat()

            if (peak > envelope) {
                envelope = attackCoef * envelope + (1f - attackCoef) * peak
            } else {
                envelope = releaseCoef * envelope + (1f - releaseCoef) * peak
            }

            val envelopeDb = 20f * Math.log10(envelope.toDouble() + 1e-6).toFloat()
            var gainReductionDb = 0f

            if (kneeDb > 0f) {
                val diff = envelopeDb - thresholdDb
                if (diff >= kneeDb / 2f) {
                    gainReductionDb = (thresholdDb - envelopeDb) * (1f - 1f / ratio)
                } else if (diff > -kneeDb / 2f) {
                    val kneeTerm = (diff + kneeDb / 2f)
                    gainReductionDb = 0.5f * kneeTerm * kneeTerm / kneeDb * (1f - 1f / ratio)
                    gainReductionDb = -gainReductionDb
                }
            } else {
                if (envelopeDb > thresholdDb) {
                    gainReductionDb = (thresholdDb - envelopeDb) * (1f - 1f / ratio)
                }
            }

            val reduction = Math.pow(10.0, (gainReductionDb / 20.0)).toFloat()
            val makeup = Math.pow(10.0, (makeupGainDb / 20.0)).toFloat()

            out[0] = sampleL * reduction * makeup
            out[1] = sampleR * reduction * makeup
        }
    }

    class LimiterDsp(val sampleRate: Float) {
        private var envelope = 0f

        fun process(sampleL: Float, sampleR: Float, ceilingDb: Float, releaseMs: Float, out: FloatArray) {
            val peak = Math.max(Math.abs(sampleL), Math.abs(sampleR))
            val ceiling = Math.pow(10.0, (ceilingDb / 20.0)).toFloat()

            val releaseCoef = Math.exp(-1.0 / (releaseMs * 0.001f * sampleRate)).toFloat()

            if (peak > envelope) {
                envelope = peak
            } else {
                envelope = releaseCoef * envelope + (1f - releaseCoef) * peak
            }

            var scale = 1f
            if (envelope > ceiling) {
                scale = ceiling / envelope
            }

            out[0] = sampleL * scale
            out[1] = sampleR * scale
        }
    }

    class NoiseGateDsp(val sampleRate: Float) {
        private var envelope = 0f
        private var gateGain = 1f

        fun process(sampleL: Float, sampleR: Float, thresholdDb: Float, reductionDb: Float, attackMs: Float, releaseMs: Float, out: FloatArray) {
            val peak = Math.max(Math.abs(sampleL), Math.abs(sampleR))

            val attackCoef = Math.exp(-1.0 / (attackMs * 0.001f * sampleRate)).toFloat()
            val releaseCoef = Math.exp(-1.0 / (releaseMs * 0.001f * sampleRate)).toFloat()

            if (peak > envelope) {
                envelope = attackCoef * envelope + (1f - attackCoef) * peak
            } else {
                envelope = releaseCoef * envelope + (1f - releaseCoef) * peak
            }

            val envelopeDb = 20f * Math.log10(envelope.toDouble() + 1e-6).toFloat()
            val targetGain = if (envelopeDb > thresholdDb) 1f else Math.pow(10.0, (reductionDb / 20.0)).toFloat()

            val coef = if (targetGain > gateGain) attackCoef else releaseCoef
            gateGain = coef * gateGain + (1f - coef) * targetGain

            out[0] = sampleL * gateGain
            out[1] = sampleR * gateGain
        }
    }

    class CircularBuffer(size: Int) {
        private val buffer = FloatArray(size)
        private var index = 0

        fun write(sample: Float) {
            buffer[index] = sample
            index = (index + 1) % buffer.size
        }

        fun read(): Float {
            return buffer[index]
        }
    }

    class ReverbDsp(val sampleRate: Float) {
        private val delayL = CircularBuffer((0.029f * sampleRate).toInt().coerceAtLeast(100))
        private val delayR = CircularBuffer((0.037f * sampleRate).toInt().coerceAtLeast(100))

        fun process(sampleL: Float, sampleR: Float, roomSize: Float, damping: Float, wet: Float, dry: Float, out: FloatArray) {
            val dl = delayL.read()
            val dr = delayR.read()

            val lFeedback = dl * roomSize * (1f - damping)
            val rFeedback = dr * roomSize * (1f - damping)

            delayL.write(sampleL + lFeedback)
            delayR.write(sampleR + rFeedback)

            out[0] = sampleL * dry + dl * wet
            out[1] = sampleR * dry + dr * wet
        }
    }

    class NoiseReductionDsp(val sampleRate: Float) {
        private val hpL = Biquad()
        private val hpR = Biquad()
        private var envelope = 0f
        private var reductionGain = 1f

        fun process(sampleL: Float, sampleR: Float, amount: Float, voiceOptimized: Boolean, out: FloatArray) {
            // Apply 80Hz rumble cut if voiceOptimized
            var l = sampleL
            var r = sampleR
            if (voiceOptimized) {
                hpL.setHighPass(80f, sampleRate, 0.707f)
                hpR.setHighPass(80f, sampleRate, 0.707f)
                l = hpL.process(sampleL)
                r = hpR.process(sampleR)
            }

            // Expander-based gate to reduce noise in silent parts
            val peak = Math.max(Math.abs(l), Math.abs(r))
            val attackCoef = Math.exp(-1.0 / (5.0 * 0.001f * sampleRate)).toFloat()
            val releaseCoef = Math.exp(-1.0 / (100.0 * 0.001f * sampleRate)).toFloat()

            if (peak > envelope) {
                envelope = attackCoef * envelope + (1f - attackCoef) * peak
            } else {
                envelope = releaseCoef * envelope + (1f - releaseCoef) * peak
            }

            val envelopeDb = 20f * Math.log10(envelope.toDouble() + 1e-6).toFloat()
            // Gate threshold at -48dB, amount dictates attenuation down to -24dB
            val thresholdDb = -48f
            val maxReductionDb = -amount * 24f
            
            val targetGain = if (envelopeDb > thresholdDb) {
                1f
            } else {
                val dbBelow = thresholdDb - envelopeDb
                // Dynamic expansion: more attenuation the further below threshold
                val gainDb = (dbBelow * -1.5f).coerceAtLeast(maxReductionDb)
                Math.pow(10.0, (gainDb / 20.0)).toFloat()
            }

            reductionGain = 0.1f * reductionGain + 0.9f * targetGain

            out[0] = l * reductionGain
            out[1] = r * reductionGain
        }
    }

    class VoiceEnhancerDsp(val sampleRate: Float) {
        private val filterBodyL = Biquad()
        private val filterBodyR = Biquad()
        private val filterClarityL = Biquad()
        private val filterClarityR = Biquad()
        private val filterAirL = Biquad()
        private val filterAirR = Biquad()
        private val filterDeEssL = Biquad()
        private val filterDeEssR = Biquad()

        fun process(sampleL: Float, sampleR: Float, clarity: Float, body: Float, air: Float, deEss: Float, out: FloatArray) {
            val bodyGainDb = body * 6f
            val clarityGainDb = clarity * 8f
            val airGainDb = air * 6f
            val deEssGainDb = -deEss * 12f

            filterBodyL.setPeaking(200f, sampleRate, bodyGainDb, 1.0f)
            filterBodyR.setPeaking(200f, sampleRate, bodyGainDb, 1.0f)

            filterClarityL.setPeaking(2500f, sampleRate, clarityGainDb, 1.0f)
            filterClarityR.setPeaking(2500f, sampleRate, clarityGainDb, 1.0f)

            filterAirL.setHighShelf(10000f, sampleRate, airGainDb)
            filterAirR.setHighShelf(10000f, sampleRate, airGainDb)

            filterDeEssL.setPeaking(7000f, sampleRate, deEssGainDb, 2.0f)
            filterDeEssR.setPeaking(7000f, sampleRate, deEssGainDb, 2.0f)

            var l = filterBodyL.process(sampleL)
            l = filterClarityL.process(l)
            l = filterDeEssL.process(l)
            l = filterAirL.process(l)

            var r = filterBodyR.process(sampleR)
            r = filterClarityR.process(r)
            r = filterDeEssR.process(r)
            r = filterAirR.process(r)

            out[0] = l
            out[1] = r
        }
    }
}
