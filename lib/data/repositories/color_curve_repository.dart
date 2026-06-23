import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/color_curves/color_curve_models.dart';

class ColorCurveRepository {
  final db.AppDatabase database;

  const ColorCurveRepository({
    required this.database,
  });

  Future<NleColorCurveStack> getCurveStack(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      return NleColorCurveStack.identity();
    }
    final raw = clip.colorCurveStackJson;

    if (raw == null || raw.trim().isEmpty) {
      return NleColorCurveStack.identity();
    }

    try {
      return NleColorCurveStack.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return NleColorCurveStack.identity();
    }
  }

  Future<void> saveCurveStack({
    required String clipId,
    required NleColorCurveStack stack,
  }) async {
    await database.updateClipColorCurveStackJson(
      clipId: clipId,
      colorCurveStackJson: jsonEncode(stack.toJson()),
    );
  }

  Future<void> resetCurveStack(String clipId) {
    return saveCurveStack(
      clipId: clipId,
      stack: NleColorCurveStack.identity(),
    );
  }

  Future<void> updateCurve({
    required String clipId,
    required NleColorCurve curve,
  }) async {
    final current = await getCurveStack(clipId);

    await saveCurveStack(
      clipId: clipId,
      stack: current.updateCurve(curve),
    );
  }

  Future<void> setEnabled({
    required String clipId,
    required bool enabled,
  }) async {
    final current = await getCurveStack(clipId);

    await saveCurveStack(
      clipId: clipId,
      stack: current.copyWith(enabled: enabled),
    );
  }

  Future<void> setEvaluationSpace({
    required String clipId,
    required NleCurveEvaluationSpace evaluationSpace,
  }) async {
    final current = await getCurveStack(clipId);

    await saveCurveStack(
      clipId: clipId,
      stack: current.copyWith(evaluationSpace: evaluationSpace),
    );
  }
}
