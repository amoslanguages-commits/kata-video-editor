package com.kata.videoeditor.nle.gpu

/**
 * Per-layer color-grading settings applied in the GPU fragment shader.
 *
 * All values use the same ranges as the shader uniforms:
 *   - brightness: -1.0 (black) … 0.0 (neutral) … +1.0 (white)
 *   - contrast:    0.0 (grey)  …  1.0 (neutral) …  4.0 (high)
 *   - saturation:  0.0 (B&W)   …  1.0 (neutral) …  4.0 (vivid)
 */
data class NleCompositorEffectSettings(
    val brightness: Float = 0f,
    val contrast: Float = 1f,
    val saturation: Float = 1f,
)
