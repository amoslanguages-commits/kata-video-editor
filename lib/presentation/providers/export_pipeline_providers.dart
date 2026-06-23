import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/export/export_pipeline_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final projectExportJobsProvider =
    StreamProvider.family<List<ExportJob>, String>((ref, projectId) {
  return ref.watch(exportRepositoryProvider).watchProjectExports(projectId);
});

final projectExportQueueSummaryProvider =
    Provider.family<NleExportQueueSummary, String>((ref, projectId) {
  final jobs = ref.watch(projectExportJobsProvider(projectId)).value ?? const <ExportJob>[];
  return NleExportQueueSummary.fromJobs(jobs);
});
