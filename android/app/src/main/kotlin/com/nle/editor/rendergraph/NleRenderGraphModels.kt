package com.nle.editor.rendergraph

import com.nle.editor.lut.NleLutStack
import com.nle.editor.grade.NlePrimaryGrade
import com.nle.editor.grade.NleSecondaryGradeStack
import com.nle.editor.curves.NleColorCurveStack

data class NleRenderGraph(
    val schema: String,
    val version: Int,
    val project: NleRenderProject,
    val assets: List<NleRenderAsset>,
    val tracks: List<NleRenderTrack>,
    val composition: NleRenderComposition,
    val audioMix: NleRenderAudioMix,
    val exportHints: NleRenderExportHints,
)

data class NleRenderAudioMix(
    val enabled: Boolean,
    val hasSoloAudio: Boolean,
    val soloAudioTrackIds: List<String>,
    val mutedAudioTrackIds: List<String>,
    val activeAudioTrackIds: List<String>,
    val sampleRate: Int,
    val channels: Int,
    val masterEffectChain: NleRenderEffectChain? = null,
)

data class NleRenderProject(
    val id: String,
    val name: String,
    val durationUs: Long,
    val width: Int,
    val height: Int,
    val frameRate: Double,
    val aspectRatio: String,
    val backgroundColor: String,
)

data class NleRenderAsset(
    val id: String,
    val type: String,
    val originalPath: String?,
    val proxyPath: String?,
    val thumbnailPath: String?,
    val displayName: String?,
    val durationUs: Long,
    val width: Int,
    val height: Int,
    val hasVideo: Boolean,
    val hasAudio: Boolean,
    val codec: String?,
    val frameRate: Double?,
    val rotationDegrees: Int,
)

data class NleRenderTrack(
    val id: String,
    val name: String,
    val type: String,
    val trackType: String,
    val role: String,
    val trackRole: String,
    val sortOrder: Int,
    val isMuted: Boolean,
    val isSolo: Boolean,
    val isLocked: Boolean,
    val isHidden: Boolean,
    val height: Double,
    val colorHex: String?,
    val isVisual: Boolean,
    val isAudio: Boolean,
    val layerOrder: Int,
    val clips: List<NleRenderClip>,
    val effectChain: NleRenderEffectChain? = null,
)

data class NleRenderClip(
    val id: String,
    val projectId: String,
    val trackId: String,
    val assetId: String?,
    val type: String,
    val clipType: String,
    val name: String,
    val timelineStartUs: Long,
    val timelineEndUs: Long,
    val sourceStartUs: Long,
    val sourceEndUs: Long,
    val durationUs: Long,
    val speed: Double,
    val transform: NleRenderTransform,
    val crop: NleRenderCrop,
    val color: NleRenderColor,
    val audio: NleRenderAudio,
    val text: NleRenderText?,
    val lutStack: NleLutStack? = null,
    val primaryGrade: NlePrimaryGrade = NlePrimaryGrade.identity(),
    val colorCurveStack: NleColorCurveStack? = null,
    val secondaryGrades: NleSecondaryGradeStack? = null,
    val effectChain: NleRenderEffectChain? = null,
    val isDisabled: Boolean,
    val zIndex: Int,
)

data class NleRenderTransform(
    val positionX: Double,
    val positionY: Double,
    val scale: Double,
    val rotation: Double,
    val opacity: Double,
)

data class NleRenderCrop(
    val fitMode: String,
    val left: Double,
    val top: Double,
    val right: Double,
    val bottom: Double,
)

data class NleRenderColor(
    val brightness: Double,
    val contrast: Double,
    val saturation: Double,
)

data class NleRenderAudio(
    val volume: Double,
    val fadeInUs: Long,
    val fadeOutUs: Long,
)

data class NleRenderText(
    val content: String,
    val styleJson: String?,
    val colorHex: String?,
)

data class NleRenderComposition(
    val visualTrackIdsBottomToTop: List<String>,
    val enabledVisualTrackIdsBottomToTop: List<String>,
    val audioTrackIds: List<String>,
    val enabledAudioTrackIds: List<String>,
    val hasSoloAudio: Boolean,
    val hasHiddenTracks: Boolean,
    val visualLayerCount: Int,
    val audioLayerCount: Int,
)

data class NleRenderExportHints(
    val useProxyForPreview: Boolean,
    val useOriginalForExport: Boolean,
    val requiresGpuCompositor: Boolean,
    val containsText: Boolean,
    val containsImage: Boolean,
    val containsVideo: Boolean,
    val containsAudio: Boolean,
    val containsAdjustment: Boolean,
    val containsColorAdjustments: Boolean,
    val containsCrop: Boolean,
    val containsSpeedChanges: Boolean,
    val containsFades: Boolean,
    val containsLut: Boolean = false,
    val containsColorCurves: Boolean = false,
    val containsSecondaryGrades: Boolean = false,
)

data class NleRenderEffectChain(
    val ownerId: String,
    val ownerType: String,
    val slots: List<NleRenderEffectSlot>,
    val enabled: Boolean,
)

data class NleRenderEffectSlot(
    val id: String,
    val type: String,
    val name: String,
    val order: Int,
    val active: Boolean,
    val wetMix: Float,
    val eq3Band: NleEq3BandSettings?,
    val compressor: NleCompressorSettings?,
    val limiter: NleLimiterSettings?,
    val noiseGate: NleNoiseGateSettings?,
    val noiseReduction: NleNoiseReductionSettings?,
    val reverb: NleReverbSettings?,
    val pitchTempo: NlePitchTempoSettings?,
    val voiceEnhancer: NleVoiceEnhancerSettings?,
)

data class NleEq3BandSettings(
    val lowGainDb: Float,
    val midGainDb: Float,
    val highGainDb: Float,
    val lowFrequencyHz: Float,
    val highFrequencyHz: Float,
)

data class NleCompressorSettings(
    val thresholdDb: Float,
    val ratio: Float,
    val attackMs: Float,
    val releaseMs: Float,
    val makeupGainDb: Float,
    val kneeDb: Float,
)

data class NleLimiterSettings(
    val ceilingDb: Float,
    val releaseMs: Float,
    val truePeakSafe: Boolean,
)

data class NleNoiseGateSettings(
    val thresholdDb: Float,
    val reductionDb: Float,
    val attackMs: Float,
    val releaseMs: Float,
)

data class NleNoiseReductionSettings(
    val amount: Float,
    val voiceOptimized: Boolean,
)

data class NleReverbSettings(
    val roomSize: Float,
    val damping: Float,
    val wet: Float,
    val dry: Float,
)

data class NlePitchTempoSettings(
    val pitchSemitones: Float,
    val tempoMultiplier: Float,
    val preserveFormants: Boolean,
)

data class NleVoiceEnhancerSettings(
    val clarity: Float,
    val body: Float,
    val air: Float,
    val deEss: Float,
)
