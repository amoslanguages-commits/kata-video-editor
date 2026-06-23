import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/export/export_batch_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final exportBatchServiceProvider = Provider<ExportBatchService>((ref) {
  return ExportBatchService(
    nativeExportService: ref.watch(nativeExportServiceProvider),
  );
});
