import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/film_look/film_look_models.dart';
import 'package:nle_editor/domain/film_look/film_stock_presets.dart';

class FilmLookRepository {
  final db.AppDatabase database;
  final FilmStockPresets presets;

  const FilmLookRepository({
    required this.database,
    this.presets = const FilmStockPresets(),
  });

  Future<NleFilmLookSettings> getClipFilmLook(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) return const NleFilmLookSettings.identity();
    final raw = clip.filmLookJson;

    if (raw == null || raw.trim().isEmpty) {
      return const NleFilmLookSettings.identity();
    }

    try {
      return NleFilmLookSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const NleFilmLookSettings.identity();
    }
  }

  Future<void> saveClipFilmLook({
    required String clipId,
    required NleFilmLookSettings settings,
  }) async {
    await database.updateClipFilmLookJson(
      clipId: clipId,
      filmLookJson: jsonEncode(settings.toJson()),
    );
  }

  Future<void> resetClipFilmLook(String clipId) {
    return saveClipFilmLook(
      clipId: clipId,
      settings: const NleFilmLookSettings.identity(),
    );
  }

  Future<void> applyClipPreset({
    required String clipId,
    required NleFilmStockPreset preset,
  }) async {
    await saveClipFilmLook(
      clipId: clipId,
      settings: presets.preset(preset),
    );
  }

  Future<NleFilmLookSettings> getTimelineFilmLook(String projectId) async {
    final project = await database.getProjectById(projectId);
    final raw = project.timelineFilmLookJson;

    if (raw == null || raw.trim().isEmpty) {
      return const NleFilmLookSettings.identity();
    }

    try {
      return NleFilmLookSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const NleFilmLookSettings.identity();
    }
  }

  Future<void> saveTimelineFilmLook({
    required String projectId,
    required NleFilmLookSettings settings,
  }) async {
    await database.updateProjectTimelineFilmLookJson(
      projectId: projectId,
      timelineFilmLookJson: jsonEncode(settings.toJson()),
    );
  }
}
