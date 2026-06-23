import 'package:flutter/foundation.dart';

import 'package:nle_editor/core/config/app_config.dart';

class ProductionSafetyGuard {
  final AppConfig config;

  const ProductionSafetyGuard({
    required this.config,
  });

  Future<void> verify() async {
    if (!config.isProduction) return;

    final problems = <String>[];

    if (config.showDebugTools) {
      problems.add('showDebugTools must be false in production.');
    }

    if (config.allowDevProUnlock) {
      problems.add('allowDevProUnlock must be false in production.');
    }

    if (config.allowVerboseNativeLogs) {
      problems.add('allowVerboseNativeLogs must be false in production.');
    }

    if (config.allowInternalDiagnosticsExport) {
      problems.add('allowInternalDiagnosticsExport must be false in production.');
    }

    // if (kDebugMode) {
    //   problems.add('Production flavor is running in debug mode.');
    // }

    if (config.packageName.endsWith('.dev') ||
        config.packageName.endsWith('.staging')) {
      problems.add('Production packageName cannot use dev/staging suffix.');
    }

    if (problems.isNotEmpty) {
      throw StateError(
        'Unsafe production configuration:\n${problems.map((e) => '- $e').join('\n')}',
      );
    }
  }
}
