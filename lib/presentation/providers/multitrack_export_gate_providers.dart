import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/qa/multitrack_export_gate.dart';
import 'package:nle_editor/presentation/providers/multitrack_qa_providers.dart';

final multitrackExportGateProvider = Provider<MultitrackExportGate>((ref) {
  return const MultitrackExportGate();
});

final canExportProjectProvider =
    FutureProvider.family<bool, String>((ref, projectId) async {
  final report = await ref.watch(projectMultitrackQaReportProvider(projectId).future);
  final gate = ref.watch(multitrackExportGateProvider);

  gate.assertCanExport(report);

  return true;
});
