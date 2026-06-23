import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/core/config/app_config.dart';
import 'package:nle_editor/core/config/app_environment.dart';
import 'package:nle_editor/core/release/production_safety_guard.dart';
import 'package:nle_editor/core/release/release_notes_generator.dart';
import 'package:nle_editor/presentation/controllers/release_checklist_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfig and AppEnvironment Tests', () {
    test('Development environment flags are set correctly', () {
      final config = AppConfig.forEnvironment(AppEnvironment.dev);

      expect(config.environment, equals(AppEnvironment.dev));
      expect(config.isProduction, isFalse);
      expect(config.showDebugTools, isTrue);
      expect(config.allowDevProUnlock, isTrue);
      expect(config.analyticsEnabled, isFalse);
      expect(config.crashReportingEnabled, isFalse);
      expect(config.packageName, equals('com.kata.videoeditor.dev'));
    });

    test('Staging environment flags are set correctly', () {
      final config = AppConfig.forEnvironment(AppEnvironment.staging);

      expect(config.environment, equals(AppEnvironment.staging));
      expect(config.isProduction, isFalse);
      expect(config.showDebugTools, isTrue);
      expect(config.allowDevProUnlock, isFalse);
      expect(config.packageName, equals('com.kata.videoeditor.staging'));
    });

    test('Production environment flags are set correctly', () {
      final config = AppConfig.forEnvironment(AppEnvironment.production);

      expect(config.environment, equals(AppEnvironment.production));
      expect(config.isProduction, isTrue);
      expect(config.showDebugTools, isFalse);
      expect(config.allowDevProUnlock, isFalse);
      expect(config.packageName, equals('com.kata.videoeditor'));
    });
  });

  group('ProductionSafetyGuard Tests', () {
    test('Throws StateError in tests for production config due to kDebugMode', () async {
      final config = AppConfig.forEnvironment(AppEnvironment.production);
      final guard = ProductionSafetyGuard(config: config);

      expect(() => guard.verify(), throwsStateError);
    });

    test('Does not throw StateError for development config', () async {
      final config = AppConfig.forEnvironment(AppEnvironment.dev);
      final guard = ProductionSafetyGuard(config: config);

      // Verify should run fine for non-production environments
      await noDiagnosticErrors(guard.verify);
    });

    test('Throws StateError if production config has debug settings enabled', () async {
      // Create a compromised production config
      const compromisedConfig = AppConfig(
        environment: AppEnvironment.production,
        appName: 'Kata',
        packageName: 'com.kata.videoeditor',
        showDebugTools: true, // Should trigger safety error
        allowDevProUnlock: false,
        allowLocalCrashLogs: false,
        analyticsEnabled: false,
        crashReportingEnabled: false,
        watermarkEnabledByDefault: true,
        allowExperimentalNativeEngine: false,
        allowVerboseNativeLogs: false,
        allowInternalDiagnosticsExport: false,
        privacyPolicyUrl: 'https://example.com/privacy',
        supportEmail: 'support@example.com',
      );

      final guard = ProductionSafetyGuard(config: compromisedConfig);
      expect(() => guard.verify(), throwsStateError);
    });
  });

  group('ReleaseChecklistController Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads empty list initially, saves and toggles entries', () async {
      final controller = ReleaseChecklistController();
      // Wait for constructor's load to complete
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.currentDoneIds, isEmpty);

      // Toggle item on
      await controller.toggle('prod_flavor_runs', true);
      expect(controller.currentDoneIds, contains('prod_flavor_runs'));

      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('release_checklist_done_ids_v1'), equals(['prod_flavor_runs']));

      // Toggle item off
      await controller.toggle('prod_flavor_runs', false);
      expect(controller.currentDoneIds, isEmpty);

      // Reset checklist
      await controller.toggle('version_updated', true);
      expect(controller.currentDoneIds, contains('version_updated'));
      await controller.reset();
      expect(controller.currentDoneIds, isEmpty);
    });
  });

  group('ReleaseNotesGenerator Tests', () {
    test('Formats markdown notes correctly with details', () {
      final generator = ReleaseNotesGenerator();
      const input = ReleaseNotesInput(
        version: '1.0.0',
        buildNumber: '42',
        highlights: ['First release candidate', 'Support 4K rendering'],
        fixes: ['Fix audio delay on exit', 'Fix timeline clip overlap'],
        knownIssues: ['Performance lag on low-end devices'],
      );

      final markdown = generator.generateMarkdown(input);

      expect(markdown, contains('# Kata 1.0.0+42'));
      expect(markdown, contains('## Highlights'));
      expect(markdown, contains('- First release candidate'));
      expect(markdown, contains('- Support 4K rendering'));
      expect(markdown, contains('## Fixes'));
      expect(markdown, contains('- Fix audio delay on exit'));
      expect(markdown, contains('## Known Issues'));
      expect(markdown, contains('- Performance lag on low-end devices'));
      expect(markdown, contains('## Tester Focus'));
    });
  });
}

// Simple test helper to run an async call and assert it doesn't throw
Future<void> noDiagnosticErrors(Future<void> Function() callback) async {
  try {
    await callback();
  } catch (e) {
    fail('Should not throw exception but threw: $e');
  }
}
