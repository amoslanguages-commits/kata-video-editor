import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/film_look_repository.dart';
import 'package:nle_editor/domain/film_look/film_look_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final filmLookRepositoryProvider = Provider<FilmLookRepository>((ref) {
  return FilmLookRepository(
    database: ref.watch(databaseProvider),
  );
});

final clipFilmLookProvider =
    FutureProvider.family<NleFilmLookSettings, String>((ref, clipId) {
  return ref.watch(filmLookRepositoryProvider).getClipFilmLook(clipId);
});

final timelineFilmLookProvider =
    FutureProvider.family<NleFilmLookSettings, String>((ref, projectId) {
  return ref.watch(filmLookRepositoryProvider).getTimelineFilmLook(projectId);
});
