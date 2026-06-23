package com.kata.videoeditor.nle

import android.content.Context

object NleContextHolder {
    @Volatile
    var context: Context? = null

    fun loadColorManagementGlsl(): String {
        val ctx = requireNotNull(context) { "NleContextHolder.context is not initialized" }
        return ctx.assets.open("shaders/nle_color_management.glsl").bufferedReader().use { it.readText() }
    }

    fun loadLutGlsl(): String {
        val ctx = requireNotNull(context) { "NleContextHolder.context is not initialized" }
        return ctx.assets.open("shaders/nle_gpu_lut.glsl").bufferedReader().use { it.readText() }
    }

    fun loadPrimaryGradeGlsl(): String {
        val ctx = requireNotNull(context) { "NleContextHolder.context is not initialized" }
        return ctx.assets.open("shaders/nle_primary_grade.glsl").bufferedReader().use { it.readText() }
    }

    fun loadColorCurvesGlsl(): String {
        val ctx = requireNotNull(context) { "NleContextHolder.context is not initialized" }
        return ctx.assets.open("shaders/nle_color_curves.glsl").bufferedReader().use { it.readText() }
    }

    fun loadSecondaryGradeGlsl(): String {
        val ctx = requireNotNull(context) { "NleContextHolder.context is not initialized" }
        return ctx.assets.open("shaders/nle_secondary_grade.glsl").bufferedReader().use { it.readText() }
    }
}
