import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/diagnostics/timeline_issue.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/screens/diagnostics/diagnostics_screen.dart';

/// A collapsible inline panel shown above the timeline editor that summarises
/// the current validation state with error/warning counts and a quick link to
/// the full [DiagnosticsScreen].
class TimelineValidationPanel extends ConsumerStatefulWidget {
  final String projectId;

  const TimelineValidationPanel({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<TimelineValidationPanel> createState() =>
      _TimelineValidationPanelState();
}

class _TimelineValidationPanelState
    extends ConsumerState<TimelineValidationPanel>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync =
        ref.watch(timelineValidationReportProvider(widget.projectId));

    return reportAsync.when(
      data: (report) {
        // Don't show the panel if everything is clean.
        if (report.issues.isEmpty) return const SizedBox.shrink();

        return _Panel(
          report: report,
          expanded: _expanded,
          expandAnimation: _expandAnimation,
          onToggle: _toggle,
          onViewDiagnostics: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DiagnosticsScreen(projectId: widget.projectId),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Panel extends StatelessWidget {
  final TimelineValidationReport report;
  final bool expanded;
  final Animation<double> expandAnimation;
  final VoidCallback onToggle;
  final VoidCallback onViewDiagnostics;

  const _Panel({
    required this.report,
    required this.expanded,
    required this.expandAnimation,
    required this.onToggle,
    required this.onViewDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    final hasErrors = report.errorCount > 0 || report.criticalCount > 0;
    final headerColor = hasErrors ? AppTheme.error : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: headerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: headerColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          // ── Header row ─────────────────────────────────────────────────────
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    hasErrors
                        ? Icons.error_outline_rounded
                        : Icons.warning_amber_rounded,
                    color: headerColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.summaryText,
                      style: TextStyle(
                        color: headerColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onViewDiagnostics,
                    style: TextButton.styleFrom(
                      foregroundColor: headerColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Fix',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: headerColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded issue list ─────────────────────────────────────────────
          SizeTransition(
            sizeFactor: expandAnimation,
            child: Column(
              children: [
                Container(
                  height: 0.5,
                  color: headerColor.withValues(alpha: 0.2),
                ),
                ...report.issues.take(5).map(
                      (issue) => _InlineIssueTile(
                        issue: issue,
                        onViewDiagnostics: onViewDiagnostics,
                      ),
                    ),
                if (report.issues.length > 5)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Text(
                      '+ ${report.issues.length - 5} more — tap "Fix" to see all',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineIssueTile extends StatelessWidget {
  final TimelineIssue issue;
  final VoidCallback onViewDiagnostics;

  const _InlineIssueTile({
    required this.issue,
    required this.onViewDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(issue.severity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  issue.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case TimelineIssueSeverity.critical:
      case TimelineIssueSeverity.error:
        return AppTheme.error;
      case TimelineIssueSeverity.warning:
        return AppTheme.warning;
      default:
        return AppTheme.accentPrimary;
    }
  }
}
