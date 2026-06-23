import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/lut_repository.dart';
import 'package:nle_editor/domain/color_lut/color_lut_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final lutRepositoryProvider = Provider<LutRepository>((ref) {
  return LutRepository(
    database: ref.watch(databaseProvider),
  );
});

final lutAssetsProvider = StreamProvider<List<NleLutAsset>>((ref) {
  return ref.watch(lutRepositoryProvider).watchLuts();
});

final clipLutStackProvider =
    FutureProvider.family<NleClipLutStack, String>((ref, clipId) {
  return ref.watch(lutRepositoryProvider).getClipLutStack(clipId: clipId);
});
