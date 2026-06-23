import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/export/export_recovery_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final exportRecoveryServiceProvider = Provider<ExportRecoveryService>((ref) {
  return ExportRecoveryService(
    exportRepository: ref.watch(exportRepositoryProvider),
    nativeExportService: ref.watch(nativeExportServiceProvider),
  );
});
