import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/native/native_eyedropper_service.dart';
import 'package:nle_editor/presentation/controllers/secondary_grade_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/secondary_grade_providers.dart';

final nativeEyedropperServiceProvider =
    Provider<NativeEyedropperService>((ref) {
  final service = NativeEyedropperService(
    bridge: ref.watch(nativeBridgeProvider),
  );

  ref.onDispose(service.dispose);

  return service;
});

final secondaryGradeControllerProvider =
    StateNotifierProvider.family<
        SecondaryGradeController,
        SecondaryGradeState,
        String>((ref, clipId) {
  return SecondaryGradeController(
    clipId: clipId,
    repository: ref.watch(secondaryGradeRepositoryProvider),
    eyedropperService: ref.watch(nativeEyedropperServiceProvider),
  );
});
