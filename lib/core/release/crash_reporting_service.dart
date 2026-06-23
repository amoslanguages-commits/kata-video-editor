import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/config/app_config.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';

final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  final config = ref.watch(appConfigProvider);

  return CrashReportingService(config: config);
});

class CrashReportingService {
  final AppConfig config;

  bool _initialized = false;

  CrashReportingService({
    required this.config,
  });

  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    if (!config.crashReportingEnabled) {
      debugPrint('[CrashReporting] Disabled for ${config.environment.name}');
      return;
    }

    // Add real provider later (Sentry/Firebase).
  }

  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!config.crashReportingEnabled) {
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
      return;
    }

    await recordError(
      details.exception,
      details.stack,
      fatal: false,
      context: {
        'library': details.library,
        'context': details.context?.toDescription(),
      },
    );
  }

  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic> context = const {},
  }) async {
    if (!config.crashReportingEnabled) {
      debugPrint('[CrashReporting disabled] fatal=$fatal error=$error');
      return;
    }

    // Real provider later.
  }

  Future<void> setUserId(String? userId) async {
    if (!config.crashReportingEnabled) return;

    // Real provider later.
  }

  Future<void> setContext(
    String key,
    Map<String, dynamic> value,
  ) async {
    if (!config.crashReportingEnabled) return;

    // Real provider later.
  }
}
