import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/services/app_settings_service.dart';
import 'package:nle_editor/domain/settings/app_settings.dart';

class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final AppSettingsService service;

  AppSettingsNotifier({
    required this.service,
  }) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();

    try {
      final settings = await service.loadSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> update(AppSettings Function(AppSettings current) updateFn) async {
    final current = state.valueOrNull ?? await service.loadSettings();
    final updated = updateFn(current).copyWith(updatedAt: DateTime.now());

    state = AsyncValue.data(updated);

    await service.saveSettings(updated);
  }

  Future<void> reset() async {
    state = const AsyncValue.loading();

    try {
      final settings = await service.resetSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
