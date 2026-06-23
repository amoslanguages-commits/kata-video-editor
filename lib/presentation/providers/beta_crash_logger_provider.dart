import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/beta/beta_crash_logger.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final betaCrashLoggerProvider = Provider<BetaCrashLogger>((ref) {
  final database = ref.watch(databaseProvider);
  return BetaCrashLogger(database: database);
});
