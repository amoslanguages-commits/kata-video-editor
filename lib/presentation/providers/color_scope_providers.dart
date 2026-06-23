import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/color_scope_settings_repository.dart';
import 'package:nle_editor/domain/native/native_scope_service.dart';
import 'package:nle_editor/presentation/controllers/color_scope_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final colorScopeSettingsRepositoryProvider =
    Provider<ColorScopeSettingsRepository>((ref) {
  return const ColorScopeSettingsRepository();
});

final nativeScopeServiceProvider = Provider<NativeScopeService>((ref) {
  final service = NativeScopeService(
    bridge: ref.watch(nativeBridgeProvider),
  );

  ref.onDispose(service.dispose);

  return service;
});

final colorScopeControllerProvider =
    StateNotifierProvider<ColorScopeController, ColorScopeState>((ref) {
  return ColorScopeController(
    repository: ref.watch(colorScopeSettingsRepositoryProvider),
    nativeService: ref.watch(nativeScopeServiceProvider),
  );
});
