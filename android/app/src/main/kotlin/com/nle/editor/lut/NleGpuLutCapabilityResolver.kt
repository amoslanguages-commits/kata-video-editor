package com.nle.editor.lut

import com.nle.editor.color.NleDeviceColorCapability

class NleGpuLutCapabilityResolver {

    fun chooseTextureMode(
        capability: NleDeviceColorCapability,
        lutSize: Int,
    ): NleLutTextureMode {
        // GLES3 supports 3D textures.
        // But some weak devices still behave poorly, so the 2D atlas path remains.
        return if (capability.supportsGles3 && lutSize <= 64) {
            NleLutTextureMode.TEXTURE_3D
        } else {
            NleLutTextureMode.TEXTURE_2D_ATLAS
        }
    }
}
