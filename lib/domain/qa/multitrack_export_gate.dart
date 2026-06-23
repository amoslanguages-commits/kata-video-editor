import 'package:nle_editor/domain/qa/multitrack_qa_models.dart';

class MultitrackExportGateException implements Exception {
  final MultitrackQaReport report;

  const MultitrackExportGateException(this.report);

  @override
  String toString() {
    final failures = report.checks
        .where((check) => check.failed)
        .map((check) => '- ${check.title}: ${check.message}')
        .join('\n');

    return 'Export blocked by 29B QA failures:\n$failures';
  }
}

class MultitrackExportGate {
  const MultitrackExportGate();

  void assertCanExport(MultitrackQaReport report) {
    if (report.passed) return;

    throw MultitrackExportGateException(report);
  }
}
