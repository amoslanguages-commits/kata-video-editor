package com.nle.editor.color

import android.opengl.GLES20

class NleColorPipelineUniformBinder {
    fun bind(
        programId: Int,
        pipeline: NleResolvedColorPipeline,
        assetId: String?,
        forExport: Boolean,
    ) {
        val input = pipeline.inputForAsset(assetId)
        val working = pipeline.working
        val output = pipeline.output

        // Set input uniforms
        setUniformInt(programId, "u_inputTransferCurve", input.transferCurve.ordinal)
        setUniformFloat(programId, "u_exposureBias", input.exposureBias)
        setUniformInt(programId, "u_inputColorSpace", input.colorSpace.ordinal)
        setUniformInt(programId, "u_workingColorSpace", working.workingSpace.ordinal)

        // Set output uniforms
        setUniformInt(programId, "u_outputColorSpace", output.colorSpace.ordinal)
        setUniformInt(programId, "u_toneMapMode", output.toneMapMode.ordinal)
        setUniformFloat(programId, "u_outputBlackLevel", output.outputBlackLevel)
        setUniformFloat(programId, "u_outputWhiteLevel", output.outputWhiteLevel)
        setUniformInt(programId, "u_outputTransferCurve", output.transferCurve.ordinal)
        setUniformInt(programId, "u_enableDither", if (output.dither) 1 else 0)
    }

    private fun setUniformInt(programId: Int, name: String, value: Int) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform1i(loc, value)
        }
    }

    private fun setUniformFloat(programId: Int, name: String, value: Float) {
        val loc = GLES20.glGetUniformLocation(programId, name)
        if (loc >= 0) {
            GLES20.glUniform1f(loc, value)
        }
    }
}
