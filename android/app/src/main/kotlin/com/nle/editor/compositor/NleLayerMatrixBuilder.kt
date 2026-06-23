package com.nle.editor.compositor

import android.opengl.Matrix
import com.nle.editor.rendergraph.NleResolvedVisualLayer

class NleLayerMatrixBuilder {

    fun buildMvpMatrix(
        layer: NleResolvedVisualLayer,
        fitScale: NleFitScale,
    ): FloatArray {
        val matrix = FloatArray(16)
        Matrix.setIdentityM(matrix, 0)

        val transform = layer.clip.transform

        val translateX = transform.positionX.toFloat()
        val translateY = -transform.positionY.toFloat()

        val userScale = transform.scale.toFloat().coerceAtLeast(0.01f)
        val scaleX = userScale * fitScale.scaleX
        val scaleY = userScale * fitScale.scaleY

        Matrix.translateM(
            matrix,
            0,
            translateX,
            translateY,
            0f,
        )

        Matrix.rotateM(
            matrix,
            0,
            transform.rotation.toFloat(),
            0f,
            0f,
            1f,
        )

        Matrix.scaleM(
            matrix,
            0,
            scaleX,
            scaleY,
            1f,
        )

        return matrix
    }
}
