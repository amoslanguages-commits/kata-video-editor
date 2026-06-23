import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/store_readiness/store_metadata.dart';
import 'package:nle_editor/presentation/controllers/store_readiness_controller.dart';

final storeReadinessProvider =
    StateNotifierProvider<StoreReadinessController, Set<String>>((ref) {
  return StoreReadinessController();
});

final storeListingDraftProvider = Provider<StoreListingText>((ref) {
  return StoreMetadataDrafts.nleEditor;
});
