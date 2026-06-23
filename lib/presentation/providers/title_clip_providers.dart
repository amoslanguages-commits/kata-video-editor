import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/title_clip_repository.dart';
import 'package:nle_editor/domain/titles/title_clip_models.dart';
import 'package:nle_editor/presentation/providers/database_providers.dart';

final titleClipRepositoryProvider = Provider<TitleClipRepository>((ref) {
  return TitleClipRepository(
    database: ref.watch(appDatabaseProvider),
  );
});

final titleClipDataProvider =
    FutureProvider.family<NleTitleClipData, String>((ref, clipId) {
  return ref.watch(titleClipRepositoryProvider).getTitleData(clipId);
});
