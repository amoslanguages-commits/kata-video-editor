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
    val projectPath: String? = null,
    val resolvedPath: String? = null,
    val sourcePolicy: String = "automatic",
    val usedProxy: Boolean = false,
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
    val durationUs: Long,
    val videoTrackCount: Int,
    val audioTrackCount: Int,
    val clipCount: Int,
    val hasOverlays: Boolean,
    val hasText: Boolean,
    val hasAudio: Boolean,
)

data class NleRenderExportHints(
    val requiresCompositing: Boolean,
    val requiresAudioMixdown: Boolean,
    val requiresColorPipeline: Boolean,
    val requiresTextLayout: Boolean,
    val useOriginalForExport: Boolean,
)

data class NleRenderEffectChain(
    val enabled: Boolean,
    val nodes: List<Map<String, Any?>>,
    val slots: List<NleRenderEffectSlot> = emptyList(),
)
