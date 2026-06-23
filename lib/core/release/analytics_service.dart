import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/config/app_config.dart';
import 'package:nle_editor/core/release/analytics_event.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    config: ref.watch(appConfigProvider),
  );
});

class AnalyticsService {
  final AppConfig config;

  const AnalyticsService({
    required this.config,
  });

  Future<void> initialize() async {
    if (!config.analyticsEnabled) {
      debugPrint('[Analytics] Disabled for ${config.environment.name}');
      return;
    }

    // Add real provider later.
  }

  Future<void> track(AnalyticsEvent event) async {
    if (!config.analyticsEnabled) {
      debugPrint('[Analytics disabled] ${event.name} ${event.parameters}');
      return;
    }

    // Real provider later.
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!config.analyticsEnabled) return;

    // Real provider later.
  }
}
