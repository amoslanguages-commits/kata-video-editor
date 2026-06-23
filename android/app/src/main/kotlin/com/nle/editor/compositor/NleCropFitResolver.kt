package com.nle.editor.compositor

import com.nle.editor.rendergraph.NleRenderAsset
import com.nle.editor.rendergraph.NleRenderClip
import kotlin.math.max

data class NleTextureCrop(
    val left: Float,
    val top: Float,
    val right: Float,
    val bottom: Float,
) {
    fun textureCoords(): FloatArray {
        val l = left.coerceIn(0f, 0.95f)
        val t = top.coerceIn(0f, 0.95f)
        val r = (1f - right).coerceIn(l + 0.01f, 1f)
        val b = (1f - bottom).coerceIn(t + 0.01f, 1f)

        return floatArrayOf(
            l, b,
            r, b,
            l, t,
            r, t,
        )
    }
}

data class NleFitScale(
    val scaleX: Float,
    val scaleY: Float,
)

class NleCropFitResolver {

    fun resolveCrop(clip: NleRenderClip): NleTextureCrop {
        return NleTextureCrop(
            left = clip.crop.left.toFloat(),
            top = clip.crop.top.toFloat(),
            right = clip.crop.right.toFloat(),
            bottom = clip.crop.bottom.toFloat(),
        )
    }

    fun resolveFitScale(
        clip: NleRenderClip,
        asset: NleRenderAsset?,
        outputWidth: Int,
        outputHeight: Int,
    ): NleFitScale {
        val assetWidth = max(1, asset?.width ?: outputWidth)
        val assetHeight = max(1, asset?.height ?: outputHeight)

        val assetAspect = assetWidth.toFloat() / assetHeight.toFloat()
        val outputAspect = outputWidth.toFloat() / outputHeight.toFloat()

        return when (clip.crop.fitMode.lowercase()) {
            "stretch" -> {
                NleFitScale(
                    scaleX = 1f,
                    scaleY = 1f,
                )
            }

            "fill" -> {
                if (assetAspect > outputAspect) {
                    NleFitScale(
                        scaleX = assetAspect / outputAspect,
                        scaleY = 1f,
                    )
                } else {
                    NleFitScale(
                        scaleX = 1f,
                        scaleY = outputAspect / assetAspect,
                    )
                }
            }

            "fit" -> {
                if (assetAspect > outputAspect) {
                    NleFitScale(
                        scaleX = 1f,
                        scaleY = outputAspect / assetAspect,
                    )
                } else {
                    NleFitScale(
                        scaleX = assetAspect / outputAspect,
                        scaleY = 1f,
                    )
                }
            }

            else -> {
                if (assetAspect > outputAspect) {
                    NleFitScale(
                        scaleX = 1f,
                        scaleY = outputAspect / assetAspect,
                    )
                } else {
                    NleFitScale(
                        scaleX = assetAspect / outputAspect,
                        scaleY = 1f,
                    )
                }
            }
        }
    }
}
