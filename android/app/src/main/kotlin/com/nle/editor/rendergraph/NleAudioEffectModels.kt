package com.nle.editor.rendergraph

data class NleRenderEffectSlot(
    val id: String,
    val order: Int,
    val active: Boolean,
    val type: String,
    val wetMix: Float,
    val eq3Band: NleEq3BandSettings? = null,
    val compressor: NleCompressorSettings? = null,
    val limiter: NleLimiterSettings? = null,
    val noiseGate: NleNoiseGateSettings? = null,
    val noiseReduction: NleNoiseReductionSettings? = null,
    val reverb: NleReverbSettings? = null,
    val pitchTempo: NlePitchTempoSettings? = null,
    val voiceEnhancer: NleVoiceEnhancerSettings? = null
)

data class NleEq3BandSettings(
    val lowGainDb: Float,
    val midGainDb: Float,
    val highGainDb: Float,
    val lowFrequencyHz: Float,
    val highFrequencyHz: Float
)

data class NleCompressorSettings(
    val thresholdDb: Float,
    val ratio: Float,
    val attackMs: Float,
    val releaseMs: Float,
    val makeupGainDb: Float,
    val kneeDb: Float
)

data class NleLimiterSettings(
    val ceilingDb: Float,
    val releaseMs: Float
)

data class NleNoiseGateSettings(
    val thresholdDb: Float,
    val reductionDb: Float,
    val attackMs: Float,
    val releaseMs: Float
)

data class NleNoiseReductionSettings(
    val amount: Float,
    val voiceOptimized: Boolean
)

data class NleReverbSettings(
    val roomSize: Float,
    val damping: Float,
    val wet: Float,
    val dry: Float
)

data class NlePitchTempoSettings(
    val pitchShift: Float = 0f
)

data class NleVoiceEnhancerSettings(
    val clarity: Float,
    val body: Float,
    val air: Float,
    val deEss: Float
)
