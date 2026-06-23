package com.nle.editor.qa

class NleColorPassOrderValidator {

    fun validate(passIds: List<String>): List<NleColorQaIssue> {
        val issues = mutableListOf<NleColorQaIssue>()
        val correctOrder = listOf(
            "input_to_scene_linear",
            "primary_grade",
            "color_curves",
            "secondary_grade",
            "gpu_lut",
            "film_look",
            "output_display_transform"
        )

        fun getPassIndex(passId: String): Int {
            if (passId.startsWith("secondary_grade_")) return correctOrder.indexOf("secondary_grade")
            if (passId.startsWith("gpu_lut_")) return correctOrder.indexOf("gpu_lut")
            if (passId.startsWith("film_look_")) return correctOrder.indexOf("film_look")
            return correctOrder.indexOf(passId)
        }

        var lastIndex = -1
        for (pass in passIds) {
            val index = getPassIndex(pass)
            if (index == -1) continue

            if (index < lastIndex) {
                issues.add(
                    NleColorQaIssue(
                        id = "NATIVE_PASS_BAD_ORDER_$pass",
                        severity = NleColorQaSeverity.RELEASE_BLOCKER,
                        area = NleColorQaArea.GPU_PIPELINE,
                        title = "GPU pass order is wrong",
                        message = "Pass \"$pass\" appears after a later stage.",
                        suggestedFix = "Use Input → Primary → Curves → Qualifier → LUT → Film Look → Output.",
                    )
                )
            }
            lastIndex = index
        }

        val containsOutputTransform = passIds.any { it == "output_display_transform" || it == "hdrOutputTransform" }
        if (!containsOutputTransform) {
            issues.add(
                NleColorQaIssue(
                    id = "NATIVE_PASS_OUTPUT_MISSING",
                    severity = NleColorQaSeverity.RELEASE_BLOCKER,
                    area = NleColorQaArea.HDR_OUTPUT,
                    title = "Output transform pass missing",
                    message = "No HDR/WCG output transform pass exists in the final chain.",
                    suggestedFix = "Add NleHdrOutputTransformPass as the final pass.",
                )
            )
        }

        return issues
    }
}
