package com.nle.editor.lut

import java.io.File
import java.util.Locale

class NleCubeLutParser {

    fun parse(filePath: String): NleCubeLutData {
        val file = File(filePath)

        require(file.exists()) {
            "LUT file does not exist: $filePath"
        }

        var title = file.nameWithoutExtension
        var size = 0

        val values = ArrayList<Float>(33 * 33 * 33 * 3)

        file.forEachLine { raw ->
            val line = raw.trim()

            if (line.isEmpty()) return@forEachLine
            if (line.startsWith("#")) return@forEachLine

            val upper = line.uppercase(Locale.US)

            when {
                upper.startsWith("TITLE") -> {
                    title = line
                        .removePrefix("TITLE")
                        .trim()
                        .removeSurrounding("\"")
                }

                upper.startsWith("LUT_3D_SIZE") -> {
                    val parts = line.split(Regex("\\s+"))
                    if (parts.size >= 2) {
                        size = parts[1].toIntOrNull() ?: 0
                    }
                }

                upper.startsWith("DOMAIN_MIN") -> {
                    // 30C-PRO foundation ignores domain remap.
                    // Later: support domain min/max normalization.
                }

                upper.startsWith("DOMAIN_MAX") -> {
                    // 30C-PRO foundation ignores domain remap.
                }

                else -> {
                    val parts = line.split(Regex("\\s+"))

                    if (parts.size >= 3) {
                        val r = parts[0].toFloatOrNull()
                        val g = parts[1].toFloatOrNull()
                        val b = parts[2].toFloatOrNull()

                        if (r != null && g != null && b != null) {
                            values.add(r.coerceIn(0f, 1f))
                            values.add(g.coerceIn(0f, 1f))
                            values.add(b.coerceIn(0f, 1f))
                        }
                    }
                }
            }
        }

        require(size > 1) {
            "Invalid or missing LUT_3D_SIZE in $filePath"
        }

        val data = NleCubeLutData(
            title = title,
            size = size,
            values = values.toFloatArray(),
        )

        data.validate()

        return data
    }
}
