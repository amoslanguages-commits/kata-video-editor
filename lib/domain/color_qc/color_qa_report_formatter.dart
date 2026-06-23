// lib/domain/color_qc/color_qa_report_formatter.dart

import 'package:nle_editor/domain/color_qc/color_qc_models.dart';

class ColorQaReportFormatter {
  const ColorQaReportFormatter();

  String formatToMarkdown(ColorQaReport report) {
    final buffer = StringBuffer();
    buffer.writeln('# Professional Color QA Audit Report');
    buffer.writeln('Generated at: ${report.timestamp.toIso8601String()}');
    buffer.writeln();
    buffer.writeln('## Status: ${report.passed ? '✅ PASSED' : '❌ FAILED'}');
    buffer.writeln();

    final blockers = report.issues.where((i) => i.severity == ColorQaSeverity.releaseBlocker).toList();
    final errors = report.issues.where((i) => i.severity == ColorQaSeverity.error).toList();
    final warnings = report.issues.where((i) => i.severity == ColorQaSeverity.warning).toList();
    final infos = report.issues.where((i) => i.severity == ColorQaSeverity.info).toList();

    buffer.writeln('### Summary');
    buffer.writeln('- **Release Blockers**: ${blockers.length}');
    buffer.writeln('- **Errors**: ${errors.length}');
    buffer.writeln('- **Warnings**: ${warnings.length}');
    buffer.writeln('- **Info/Neutrality**: ${infos.length}');
    buffer.writeln();

    if (report.issues.isEmpty) {
      buffer.writeln('🎉 No issues detected! The color pipeline is clean and fully optimized.');
      return buffer.toString();
    }

    _writeSection(buffer, '🚨 Release Blockers', blockers);
    _writeSection(buffer, '❌ Errors', errors);
    _writeSection(buffer, '⚠️ Warnings', warnings);
    _writeSection(buffer, 'ℹ️ Neutral Adjustments (Info)', infos);

    return buffer.toString();
  }

  void _writeSection(StringBuffer buffer, String title, List<ColorQaIssue> issues) {
    if (issues.isEmpty) return;
    buffer.writeln('## $title');
    buffer.writeln();
    for (final issue in issues) {
      buffer.writeln('### [${issue.id}] ${issue.title}');
      buffer.writeln('- **Area**: `${issue.area.name}`');
      buffer.writeln('- **Message**: ${issue.message}');
      if (issue.suggestedFix != null) {
        buffer.writeln('- **Suggested Fix**: ${issue.suggestedFix}');
      }
      buffer.writeln();
    }
  }
}
