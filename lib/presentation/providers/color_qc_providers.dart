// lib/presentation/providers/color_qc_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/data/repositories/color_qc_repository.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/controllers/color_qc_controller.dart';
export 'package:nle_editor/presentation/controllers/color_qc_controller.dart';

final colorQcRepositoryProvider = Provider<ColorQcRepository>((ref) {
  final nativeBridge = ref.watch(nativeBridgeProvider);
  return ColorQcRepository(nativeBridge: nativeBridge);
});

final colorQcControllerProvider =
    StateNotifierProvider.family<ColorQcController, ColorQcState, String>(
  (ref, projectId) {
    final repository = ref.watch(colorQcRepositoryProvider);
    return ColorQcController(
      projectId: projectId,
      repository: repository,
      ref: ref,
    );
  },
);
