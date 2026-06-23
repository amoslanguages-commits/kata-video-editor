import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/color_grade/primary_grade_models.dart';

class PrimaryGradeRepository {
  final db.AppDatabase database;

  const PrimaryGradeRepository({
    required this.database,
  });

  Future<NlePrimaryGrade> getPrimaryGrade(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      return const NlePrimaryGrade.identity();
    }
    final raw = clip.primaryGradeJson;

    if (raw == null || raw.trim().isEmpty) {
      return const NlePrimaryGrade.identity();
    }

    try {
      return NlePrimaryGrade.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const NlePrimaryGrade.identity();
    }
  }

  Future<void> savePrimaryGrade({
    required String clipId,
    required NlePrimaryGrade grade,
  }) async {
    await database.updateClipPrimaryGradeJson(
      clipId: clipId,
      primaryGradeJson: jsonEncode(grade.toJson()),
    );
  }

  Future<void> resetPrimaryGrade(String clipId) async {
    await savePrimaryGrade(
      clipId: clipId,
      grade: const NlePrimaryGrade.identity(),
    );
  }

  Future<void> setEnabled({
    required String clipId,
    required bool enabled,
  }) async {
    final current = await getPrimaryGrade(clipId);

    await savePrimaryGrade(
      clipId: clipId,
      grade: current.copyWith(enabled: enabled),
    );
  }

  Future<void> setMode({
    required String clipId,
    required NlePrimaryGradeMode mode,
  }) async {
    final current = await getPrimaryGrade(clipId);

    await savePrimaryGrade(
      clipId: clipId,
      grade: current.copyWith(mode: mode),
    );
  }

  Future<void> updateLift({
    required String clipId,
    required NlePrimaryWheelControl lift,
  }) async {
    final current = await getPrimaryGrade(clipId);

    await savePrimaryGrade(
      clipId: clipId,
      grade: current.copyWith(lift: lift),
    );
  }

  Future<void> updateGamma({
    required String clipId,
    required NlePrimaryWheelControl gamma,
  }) async {
    final current = await getPrimaryGrade(clipId);

    await savePrimaryGrade(
      clipId: clipId,
      grade: current.copyWith(gamma: gamma),
    );
  }

  Future<void> updateGain({
    required String clipId,
    required NlePrimaryWheelControl gain,
  }) async {
    final current = await getPrimaryGrade(clipId);

    await savePrimaryGrade(
      clipId: clipId,
      grade: current.copyWith(gain: gain),
    );
  }

  Future<void> updateOffset({
    required String clipId,
    required NlePrimaryWheelControl offset,
  }) async {
    final current = await getPrimaryGrade(clipId);

    await savePrimaryGrade(
      clipId: clipId,
      grade: current.copyWith(offset: offset),
    );
  }

  Future<void> updateBasic({
    required String clipId,
    double? intensity,
    double? contrast,
    double? pivot,
    double? saturation,
  }) async {
    final current = await getPrimaryGrade(clipId);

    await savePrimaryGrade(
      clipId: clipId,
      grade: current.copyWith(
        intensity: intensity,
        contrast: contrast,
        pivot: pivot,
        saturation: saturation,
      ),
    );
  }
}
