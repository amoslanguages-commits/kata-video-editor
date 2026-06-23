import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/caption_repository.dart';
import 'package:nle_editor/domain/captions/subtitle_track_models.dart';
import 'package:nle_editor/presentation/providers/database_providers.dart';
import 'package:nle_editor/presentation/controllers/caption_controller.dart';

final captionRepositoryProvider = Provider<CaptionRepository>((ref) {
  return CaptionRepository(
    database: ref.watch(appDatabaseProvider),
  );
});

final subtitleTracksProvider =
    FutureProvider.family<List<NleSubtitleTrack>, String>((ref, projectId) {
  return ref.watch(captionRepositoryProvider).getTracks(projectId);
});

final subtitleTrackProvider =
    FutureProvider.family<NleSubtitleTrack, String>((ref, trackId) {
  return ref.watch(captionRepositoryProvider).getTrack(trackId);
});

final captionControllerProvider =
    StateNotifierProvider.family<CaptionController, CaptionEditorState, String>(
  (ref, projectId) {
    return CaptionController(
      projectId: projectId,
      repository: ref.watch(captionRepositoryProvider),
    );
  },
);
