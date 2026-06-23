import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/data/repositories/multitrack_timeline_repository.dart';
import 'package:nle_editor/domain/timeline/multitrack_timeline_view_model.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final multitrackTimelineRepositoryProvider =
    Provider<MultitrackTimelineRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return MultitrackTimelineRepository(database: database);
});

final ensureDefaultMultitrackTracksProvider =
    FutureProvider.family<void, String>((ref, projectId) async {
  final repository = ref.watch(multitrackTimelineRepositoryProvider);
  await repository.ensureDefaultTracks(projectId);
});

final realProjectTimelineProvider =
    StreamProvider.family<MultitrackTimelineViewModel, String>((ref, projectId) {
  final repository = ref.watch(multitrackTimelineRepositoryProvider);
  return repository.watchProjectTimeline(projectId);
});

final projectTimelineOnceProvider =
    FutureProvider.family<MultitrackTimelineViewModel, String>((ref, projectId) {
  final repository = ref.watch(multitrackTimelineRepositoryProvider);
  return repository.getProjectTimelineOnce(projectId);
});
