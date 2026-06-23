package com.nle.editor.lut

import android.opengl.GLES20
import com.nle.editor.color.NleDeviceColorCapability

class NleGpuLutCache(
    private val parser: NleCubeLutParser = NleCubeLutParser(),
    private val capabilityResolver: NleGpuLutCapabilityResolver =
        NleGpuLutCapabilityResolver(),
    private val uploader3d: NleGpu3dLutUploader = NleGpu3dLutUploader(),
    private val uploader2d: NleGpu2dLutAtlasUploader = NleGpu2dLutAtlasUploader(),
) {
    private val cache = LinkedHashMap<String, NleGpuLutTexture>()

    fun getOrUpload(
        layer: NleLutLayer,
        capability: NleDeviceColorCapability,
    ): NleGpuLutTexture {
        val existing = cache[layer.lutAssetId]
        if (existing != null && existing.size == layer.size) {
            return existing
        }

        val data = parser.parse(layer.lutPath)

        val mode = capabilityResolver.chooseTextureMode(
            capability = capability,
            lutSize = data.size,
        )

        val texture = when (mode) {
            NleLutTextureMode.TEXTURE_3D -> {
                uploader3d.upload(
                    lutAssetId = layer.lutAssetId,
                    filePath = layer.lutPath,
                    data = data,
                )
            }

            NleLutTextureMode.TEXTURE_2D_ATLAS -> {
                uploader2d.upload(
                    lutAssetId = layer.lutAssetId,
                    filePath = layer.lutPath,
                    data = data,
                )
            }
        }

        cache[layer.lutAssetId] = texture

        return texture
    }

    fun release(lutAssetId: String) {
        val texture = cache.remove(lutAssetId) ?: return
        GLES20.glDeleteTextures(1, intArrayOf(texture.textureId), 0)
    }

    fun releaseAll() {
        for (texture in cache.values) {
            GLES20.glDeleteTextures(1, intArrayOf(texture.textureId), 0)
        }
        cache.clear()
    }
}
