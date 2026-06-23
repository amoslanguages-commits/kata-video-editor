import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(databaseProvider);
});
