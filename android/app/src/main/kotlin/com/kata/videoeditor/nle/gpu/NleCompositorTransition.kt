package com.kata.videoeditor.nle.gpu

/**
 * Resolved state of an active transition at a specific timeline position.
 *
 * @param transitionId   ID from the render graph transition entry.
 * @param type           Transition type string: "dissolve", "fade", etc.
 * @param progress       Smoothed progress from 0.0 (outgoing visible) to 1.0 (incoming visible).
 * @param outgoingClipId The clip that is leaving.
 * @param incomingClipId The clip that is entering.
 */
data class NleTransitionState(
    val transitionId: String,
    val type: String,
    val progress: Float,
    val outgoingClipId: String,
    val incomingClipId: String,
)
