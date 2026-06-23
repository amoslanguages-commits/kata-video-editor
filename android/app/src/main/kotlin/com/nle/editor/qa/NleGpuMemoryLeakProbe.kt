package com.nle.editor.qa

class NleGpuMemoryLeakProbe {
    companion object {
        private var textureAllocCount = 0
        private var fboAllocCount = 0

        fun onTextureAllocated() {
            textureAllocCount++
        }

        fun onTextureReleased() {
            textureAllocCount = maxOf(0, textureAllocCount - 1)
        }

        fun onFboAllocated() {
            fboAllocCount++
        }

        fun onFboReleased() {
            fboAllocCount = maxOf(0, fboAllocCount - 1)
        }

        fun getStats(): Map<String, Int> {
            return mapOf(
                "activeTextures" to textureAllocCount,
                "activeFbos" to fboAllocCount
            )
        }
    }

    fun probe(): List<NleColorQaIssue> {
        val issues = mutableListOf<NleColorQaIssue>()

        if (textureAllocCount > 128) {
            issues.add(
                NleColorQaIssue(
                    id = "MEMORY_LEAK_GL_TEXTURES",
                    severity = NleColorQaSeverity.WARNING,
                    area = NleColorQaArea.MEMORY_LEAK,
                    title = "Excessive GL texture allocations",
                    message = "Active GL texture allocation count ($textureAllocCount) exceeds safety threshold of 128.",
                    suggestedFix = "Ensure all unused NleGpuLutPass or preview textures are fully released."
                )
            )
        }

        if (fboAllocCount > 32) {
            issues.add(
                NleColorQaIssue(
                    id = "MEMORY_LEAK_GL_FBOS",
                    severity = NleColorQaSeverity.RELEASE_BLOCKER,
                    area = NleColorQaArea.MEMORY_LEAK,
                    title = "Excessive Framebuffer allocations",
                    message = "Active Framebuffer allocation count ($fboAllocCount) exceeds safety threshold of 32.",
                    suggestedFix = "Ensure NlePingPongRenderTargets are fully disposed when changing projects."
                )
            )
        }

        return issues
    }
}
