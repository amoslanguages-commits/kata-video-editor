import 'package:flutter/foundation.dart';

import 'package:nle_editor/core/config/app_environment.dart';

class AppConfig {
  final AppEnvironment environment;
  final String appName;
  final String packageName;
  final bool showDebugTools;
  final bool allowDevProUnlock;
  final bool allowLocalCrashLogs;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
  final bool watermarkEnabledByDefault;
  final bool allowExperimentalNativeEngine;
  final bool allowVerboseNativeLogs;
  final bool allowInternalDiagnosticsExport;
  final String privacyPolicyUrl;
  final String supportEmail;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.packageName,
    required this.showDebugTools,
    required this.allowDevProUnlock,
    required this.allowLocalCrashLogs,
    required this.analyticsEnabled,
    required this.crashReportingEnabled,
    required this.watermarkEnabledByDefault,
    required this.allowExperimentalNativeEngine,
    required this.allowVerboseNativeLogs,
    required this.allowInternalDiagnosticsExport,
    required this.privacyPolicyUrl,
    required this.supportEmail,
  });

  factory AppConfig.forEnvironment(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.dev:
        return const AppConfig(
          environment: AppEnvironment.dev,
          appName: 'Kata Dev',
          packageName: 'com.kata.videoeditor.dev',
          showDebugTools: true,
          allowDevProUnlock: true,
          allowLocalCrashLogs: true,
          analyticsEnabled: false,
          crashReportingEnabled: false,
          watermarkEnabledByDefault: false,
          allowExperimentalNativeEngine: true,
          allowVerboseNativeLogs: true,
          allowInternalDiagnosticsExport: true,
          privacyPolicyUrl: 'https://example.com/privacy-dev',
          supportEmail: 'gtelaon.pro@gmail.com',
        );

      case AppEnvironment.staging:
        return const AppConfig(
          environment: AppEnvironment.staging,
          appName: 'Kata Staging',
          packageName: 'com.kata.videoeditor.staging',
          showDebugTools: true,
          allowDevProUnlock: false,
          allowLocalCrashLogs: true,
          analyticsEnabled: false,
          crashReportingEnabled: false,
          watermarkEnabledByDefault: true,
          allowExperimentalNativeEngine: true,
          allowVerboseNativeLogs: true,
          allowInternalDiagnosticsExport: true,
          privacyPolicyUrl: 'https://example.com/privacy-staging',
          supportEmail: 'gtelaon.pro@gmail.com',
        );

      case AppEnvironment.production:
        return const AppConfig(
          environment: AppEnvironment.production,
          appName: 'Kata',
          packageName: 'com.kata.videoeditor',
          showDebugTools: false,
          allowDevProUnlock: false,
          allowLocalCrashLogs: false,
          analyticsEnabled: true,
          crashReportingEnabled: true,
          watermarkEnabledByDefault: true,
          allowExperimentalNativeEngine: false,
          allowVerboseNativeLogs: false,
          allowInternalDiagnosticsExport: false,
          privacyPolicyUrl: 'https://example.com/privacy',
          supportEmail: 'gtelaon.pro@gmail.com',
        );
    }
  }

  bool get isProduction => environment.isProduction;

  bool get shouldShowInternalTools => showDebugTools && !isProduction;

  bool get safeToShowDevUnlock {
    return !isProduction && allowDevProUnlock && kDebugMode;
  }

  Map<String, dynamic> toJson() {
    return {
      'environment': environment.name,
      'appName': appName,
      'packageName': packageName,
      'showDebugTools': showDebugTools,
      'allowDevProUnlock': allowDevProUnlock,
      'allowLocalCrashLogs': allowLocalCrashLogs,
      'analyticsEnabled': analyticsEnabled,
      'crashReportingEnabled': crashReportingEnabled,
      'watermarkEnabledByDefault': watermarkEnabledByDefault,
      'allowExperimentalNativeEngine': allowExperimentalNativeEngine,
      'allowVerboseNativeLogs': allowVerboseNativeLogs,
      'allowInternalDiagnosticsExport': allowInternalDiagnosticsExport,
      'privacyPolicyUrl': privacyPolicyUrl,
      'supportEmail': supportEmail,
    };
  }
}
