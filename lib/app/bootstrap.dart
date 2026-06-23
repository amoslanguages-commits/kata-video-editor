import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nle_editor/app/nle_editor_app.dart';
import 'package:nle_editor/core/config/app_config.dart';
import 'package:nle_editor/core/config/app_environment.dart';
import 'package:nle_editor/core/release/crash_reporting_service.dart';
import 'package:nle_editor/core/release/production_safety_guard.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';

// Database dependencies
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/database/database_connection.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

import 'package:nle_editor/domain/beta/beta_crash_logger.dart';

Future<void> bootstrapApp({
  required AppEnvironment environment,
}) async {
  final config = AppConfig.forEnvironment(environment);
  AppDatabase? database;
  BetaCrashLogger? betaCrashLogger;

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await dotenv.load(fileName: ".env");

      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );

      await ProductionSafetyGuard(config: config).verify();

      final crashReporting = CrashReportingService(config: config);
      await crashReporting.initialize();

      database = AppDatabase(openConnection());
      betaCrashLogger = BetaCrashLogger(database: database!);
      await betaCrashLogger!.init();

      final originalFlutterOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (originalFlutterOnError != null) originalFlutterOnError(details);
      };

      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            crashReportingServiceProvider.overrideWithValue(crashReporting),
            databaseProvider.overrideWithValue(database!),
          ],
          child: const NleEditorApp(),
        ),
      );
    },
    (error, stackTrace) async {
      final crashReporting = CrashReportingService(config: config);
      await crashReporting.initialize();
      await crashReporting.recordError(
        error,
        stackTrace,
        fatal: true,
      );

      if (betaCrashLogger != null) {
        await betaCrashLogger!.logError(
          category: 'fatal_crash',
          code: 'zoned_guarded_exception',
          userMessage: 'A fatal application crash occurred.',
          technicalMessage: '$error\n$stackTrace',
          severity: 'fail',
        );
      }
    },
  );
}
