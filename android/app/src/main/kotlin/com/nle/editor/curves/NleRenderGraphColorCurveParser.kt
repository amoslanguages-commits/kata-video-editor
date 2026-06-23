package com.nle.editor.curves

import org.json.JSONObject
import org.json.JSONArray

object NleRenderGraphColorCurveParser {

    fun parseClipCurves(clipJson: JSONObject): NleColorCurveStack? {
        val json = clipJson.optJSONObject("colorCurves") ?: return null

        val enabled = json.optBoolean("enabled", true)
        val evaluationSpace = NleCurveEvaluationSpace.parse(json.optString("evaluationSpace"))
        
        val curvesArray = json.optJSONArray("curves")
        val curvesList = mutableListOf<NleColorCurve>()
        
        if (curvesArray != null) {
            for (i in 0 until curvesArray.length()) {
                val curveJson = curvesArray.optJSONObject(i) ?: continue
                val type = NleCurveType.parse(curveJson.optString("type"))
                val curveEnabled = curveJson.optBoolean("enabled", true)
                val interpolation = NleCurveInterpolation.parse(curveJson.optString("interpolation"))
                val intensity = curveJson.optDouble("intensity", 1.0).toFloat().coerceIn(0f, 1f)
                
                val pointsArray = curveJson.optJSONArray("points")
                val pointsList = mutableListOf<NleCurvePoint>()
                if (pointsArray != null) {
                    for (j in 0 until pointsArray.length()) {
                        val ptJson = pointsArray.optJSONObject(j) ?: continue
                        val x = ptJson.optDouble("x", 0.0).toFloat().coerceIn(0f, 1f)
                        val y = ptJson.optDouble("y", 0.0).toFloat().coerceIn(0f, 1f)
                        pointsList.add(NleCurvePoint(x, y))
                    }
                }
                
                val finalPoints = if (pointsList.isEmpty()) {
                    listOf(NleCurvePoint(0f, 0f), NleCurvePoint(1f, 1f))
                } else {
                    pointsList
                }
                
                curvesList.add(NleColorCurve(
                    type = type,
                    enabled = curveEnabled,
                    points = finalPoints,
                    interpolation = interpolation,
                    intensity = intensity
                ))
            }
        }
        
        val byType = curvesList.associateBy { it.type }
        val finalCurves = NleCurveType.values().map { type ->
            byType[type] ?: NleColorCurve.identity(type)
        }

        return NleColorCurveStack(
            enabled = enabled,
            evaluationSpace = evaluationSpace,
            curves = finalCurves
        )
    }
}
