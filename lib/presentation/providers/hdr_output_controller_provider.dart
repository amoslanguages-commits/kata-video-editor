// lib/presentation/providers/hdr_output_controller_provider.dart
//
// 30J-PRO: StateNotifierProvider family for HdrOutputController.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/presentation/controllers/hdr_output_controller.dart';
import 'package:nle_editor/presentation/providers/hdr_output_providers.dart';

final hdrOutputControllerProvider = StateNotifierProvider.family<HdrOutputController, HdrOutputState, String>((ref, projectId) {
  final repository = ref.watch(hdrOutputRepositoryProvider);
  final nativeService = ref.watch(nativeHdrOutputServiceProvider);

  return HdrOutputController(
    projectId: projectId,
    repository: repository,
    nativeService: nativeService,
  );
});
