import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/overlay_clip_repository.dart';
import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/presentation/providers/database_providers.dart';

final overlayClipRepositoryProvider = Provider<OverlayClipRepository>((ref) {
  return OverlayClipRepository(
    database: ref.watch(appDatabaseProvider),
  );
});

final overlayClipDataProvider =
    FutureProvider.family<NleOverlayClipData, String>((ref, clipId) {
  return ref.watch(overlayClipRepositoryProvider).getOverlayData(clipId);
});
