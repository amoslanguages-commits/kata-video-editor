package com.nle.editor.lut

data class NleGpuLutTexture(
    val lutAssetId: String,
    val path: String,
    val size: Int,
    val textureId: Int,
    val textureMode: NleLutTextureMode,
) {
    fun is3d(): Boolean = textureMode == NleLutTextureMode.TEXTURE_3D
    fun is2dAtlas(): Boolean = textureMode == NleLutTextureMode.TEXTURE_2D_ATLAS
}
