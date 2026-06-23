import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/presentation/controllers/film_look_controller.dart';
import 'package:nle_editor/presentation/providers/film_look_providers.dart';

/// Per-clip film look controller.
/// Usage:  ref.watch(filmLookControllerProvider(clipId))
final filmLookControllerProvider = StateNotifierProvider.family<
    FilmLookController, FilmLookState, String>((ref, clipId) {
  return FilmLookController(
    clipId: clipId,
    repository: ref.watch(filmLookRepositoryProvider),
  );
});

/// Timeline / project-level film look controller.
/// Usage:  ref.watch(timelineFilmLookControllerProvider(projectId))
final timelineFilmLookControllerProvider = StateNotifierProvider.family<
    TimelineFilmLookController, FilmLookState, String>((ref, projectId) {
  return TimelineFilmLookController(
    projectId: projectId,
    repository: ref.watch(filmLookRepositoryProvider),
  );
});
