import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/media_library/media_asset_canonicalization_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final mediaAssetCanonicalizationServiceProvider =
    Provider<MediaAssetCanonicalizationService>((ref) {
  return MediaAssetCanonicalizationService(
    database: ref.watch(databaseProvider),
  );
});
