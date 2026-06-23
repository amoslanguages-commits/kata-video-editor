import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/diagnostics/timeline_issue.dart';
import 'package:nle_editor/domain/services/project_repair_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/screens/diagnostics/debug_logs_viewer.dart';
import 'package:nle_editor/presentation/widgets/debug/render_graph_debug_viewer.dart';

class DiagnosticsScreen extends ConsumerWidget {
  final String projectId;

  const DiagnosticsScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationAsync =
        ref.watch(timelineValidationReportProvider(projectId));
    final engineAsync = ref.watch(engineHealthReportProvider);

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Diagnostics & QA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Re-run checks',
            onPressed: () {
              ref.invalidate(timelineValidationReportProvider(projectId));
              ref.invalidate(engineHealthReportProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            tooltip: 'Debug logs',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DebugLogsViewer(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_tree_rounded),
            tooltip: 'Render Graph',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: AppTheme.editorBackground,
                  appBar: AppBar(
                    title: const Text('Render Graph Preview'),
                  ),
                  body: RenderGraphDebugViewer(projectId: projectId),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Engine health ──────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.memory_rounded,
            title: 'Native Engine',
            trailing: _HealthBadge(healthAsync: engineAsync),
          ),
          const SizedBox(height: 8),
          engineAsync.when(
            data: (report) => _EngineHealthCard(report: report),
            // ignore: prefer_const_constructors
            loading: () => _LoadingCard(label: 'Checking engine…'),
            error: (e, _) => _ErrorCard(message: 'Engine check failed: $e'),
          ),
          const SizedBox(height: 24),

          // ── Timeline validation ────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.rule_rounded,
            title: 'Timeline Validation',
            trailing: validationAsync.when(
              data: (r) => _IssueBadge(count: r.errorCount + r.criticalCount),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 8),
          validationAsync.when(
            data: (report) => _TimelineValidationCard(
              report: report,
              projectId: projectId,
            ),
            // ignore: prefer_const_constructors
            loading: () => _LoadingCard(label: 'Validating timeline…'),
            error: (e, _) => _ErrorCard(message: 'Validation failed: $e'),
          ),
          const SizedBox(height: 24),

          // ── Auto-repair ────────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.build_rounded,
            title: 'Project Auto-Repair',
          ),
          const SizedBox(height: 8),
          _AutoRepairCard(projectId: projectId),
          const SizedBox(height: 24),

          // ── QA Checklist ───────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.checklist_rounded,
            title: 'QA Checklist',
          ),
          const SizedBox(height: 8),
          const _QaChecklistCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentPrimary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Health Badge ──────────────────────────────────────────────────────────────

class _HealthBadge extends StatelessWidget {
  final AsyncValue<EngineHealthReport> healthAsync;

  const _HealthBadge({required this.healthAsync});

  @override
  Widget build(BuildContext context) {
    return healthAsync.when(
      data: (report) {
        Color color;
        String label;
        if (report.isHealthy) {
          color = AppTheme.success;
          label = 'Healthy';
        } else if (report.isDegraded) {
          color = AppTheme.warning;
          label = 'Degraded';
        } else {
          color = AppTheme.error;
          label = 'Offline';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Issue Badge ──────────────────────────────────────────────────────────────

class _IssueBadge extends StatelessWidget {
  final int count;

  const _IssueBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Clean',
          style: TextStyle(
            color: AppTheme.success,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count issues',
        style: const TextStyle(
          color: AppTheme.error,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Engine Health Card ────────────────────────────────────────────────────────

class _EngineHealthCard extends StatelessWidget {
  final EngineHealthReport report;

  const _EngineHealthCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        children: [
          _HealthRow(
            label: 'Method Channel',
            ok: report.methodChannelReachable,
          ),
          const SizedBox(height: 8),
          _HealthRow(
            label: 'Event Channel',
            ok: report.eventChannelActive,
          ),
          const SizedBox(height: 8),
          _HealthRow(
            label: 'Session Active',
            ok: report.sessionActive,
          ),
          if (report.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report.errorMessage!,
                style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final bool ok;

  const _HealthRow({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: ok ? AppTheme.success : AppTheme.error,
          size: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          ok ? 'OK' : 'FAIL',
          style: TextStyle(
            color: ok ? AppTheme.success : AppTheme.error,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Timeline Validation Card ──────────────────────────────────────────────────

class _TimelineValidationCard extends ConsumerWidget {
  final TimelineValidationReport report;
  final String projectId;

  const _TimelineValidationCard({
    required this.report,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: report.issues.isEmpty
          ? const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.success),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Timeline validation passed.',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rule_rounded, color: AppTheme.warning),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Timeline Issues',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${report.errorCount} errors • ${report.warningCount} warnings',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...report.issues.take(8).map(
                      (issue) => _IssueTile(
                        issue: issue,
                        onAction: (issue) => _handleAction(context, ref, issue),
                      ),
                    ),
                if (report.issues.length > 8) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${report.issues.length - 8} more issues',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    TimelineIssue issue,
  ) async {
    if (issue.action == null) return;
    final messenger = ScaffoldMessenger.of(context);

    switch (issue.action!.actionId) {
      case TimelineIssueActionId.removeClip:
        final clipId = issue.action!.payload['clipId'] as String?;
        if (clipId != null) {
          await ref.read(projectRepairServiceProvider).removeClip(clipId);
          ref.invalidate(timelineValidationReportProvider(projectId));
          messenger.showSnackBar(
            const SnackBar(content: Text('Clip removed.')),
          );
        }
        break;

      case TimelineIssueActionId.repairTiming:
        final clipId = issue.action!.payload['clipId'] as String?;
        if (clipId != null) {
          await ref.read(projectRepairServiceProvider).repairClipTiming(clipId);
          ref.invalidate(timelineValidationReportProvider(projectId));
          messenger.showSnackBar(
            const SnackBar(content: Text('Clip timing repaired.')),
          );
        }
        break;

      case TimelineIssueActionId.repairTransition:
        final txId = issue.action!.payload['transitionId'] as String?;
        if (txId != null) {
          await ref.read(transitionRepositoryProvider).deleteTransition(txId);
          ref.invalidate(timelineValidationReportProvider(projectId));
          messenger.showSnackBar(
            const SnackBar(content: Text('Transition removed.')),
          );
        }
        break;

      default:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Action "${issue.action!.actionId}" not handled here.',
            ),
          ),
        );
    }
  }
}

// ─── Issue Tile ────────────────────────────────────────────────────────────────

class _IssueTile extends StatelessWidget {
  final TimelineIssue issue;
  final void Function(TimelineIssue) onAction;

  const _IssueTile({required this.issue, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _severityStyle(issue.severity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.title,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    issue.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (issue.action != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onAction(issue),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  issue.action!.label,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, IconData) _severityStyle(String severity) {
    switch (severity) {
      case TimelineIssueSeverity.critical:
        return (AppTheme.error, Icons.error_rounded);
      case TimelineIssueSeverity.error:
        return (AppTheme.error, Icons.cancel_rounded);
      case TimelineIssueSeverity.warning:
        return (AppTheme.warning, Icons.warning_amber_rounded);
      default:
        return (AppTheme.accentPrimary, Icons.info_rounded);
    }
  }
}

// ─── Auto-Repair Card ──────────────────────────────────────────────────────────

class _AutoRepairCard extends ConsumerStatefulWidget {
  final String projectId;

  const _AutoRepairCard({required this.projectId});

  @override
  ConsumerState<_AutoRepairCard> createState() => _AutoRepairCardState();
}

class _AutoRepairCardState extends ConsumerState<_AutoRepairCard> {
  bool _running = false;
  ProjectRepairResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Automatically repairs common project issues:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          const _BulletPoint('Fixes invalid clip trim bounds'),
          const _BulletPoint('Removes orphaned keyframes'),
          const _BulletPoint('Removes unlinked transitions'),
          const SizedBox(height: 14),
          if (_lastResult != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (_lastResult!.hadIssues
                        ? AppTheme.warning
                        : AppTheme.success)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastResult!.summaryText,
                style: TextStyle(
                  color: _lastResult!.hadIssues
                      ? AppTheme.warning
                      : AppTheme.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.auto_fix_high_rounded),
              label: Text(_running ? 'Running…' : 'Run Auto-Repair'),
              onPressed: _running
                  ? null
                  : () async {
                      setState(() {
                        _running = true;
                        _lastResult = null;
                      });

                      final result = await ref
                          .read(projectRepairServiceProvider)
                          .autoRepair(widget.projectId);

                      if (mounted) {
                        setState(() {
                          _running = false;
                          _lastResult = result;
                        });
                        ref.invalidate(
                            timelineValidationReportProvider(widget.projectId));
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 5, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QA Checklist ─────────────────────────────────────────────────────────────

class _QaChecklistCard extends StatefulWidget {
  const _QaChecklistCard();

  @override
  State<_QaChecklistCard> createState() => _QaChecklistCardState();
}

class _QaChecklistCardState extends State<_QaChecklistCard> {
  final Map<String, bool> _checks = {
    'Timeline plays back without visual glitches': false,
    'Audio levels are balanced': false,
    'Transitions are smooth': false,
    'Text overlays are readable': false,
    'Export resolution and frame rate are correct': false,
    'No missing media warnings': false,
    'Storage headroom is sufficient': false,
    'Gallery save permission is granted': false,
  };

  @override
  Widget build(BuildContext context) {
    final done = _checks.values.where((v) => v).length;
    final total = _checks.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$done / $total completed',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (done == total)
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Ready to export!',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: done / total,
            backgroundColor: AppTheme.surfaceOverlay,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
            borderRadius: BorderRadius.circular(99),
            minHeight: 4,
          ),
          const SizedBox(height: 14),
          ..._checks.entries.map(
            (e) => Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                value: e.value,
                onChanged: (v) => setState(() => _checks[e.key] = v ?? false),
                title: Text(
                  e.key,
                  style: TextStyle(
                    color:
                        e.value ? AppTheme.textMuted : AppTheme.textSecondary,
                    fontSize: 13,
                    decoration: e.value
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppTheme.accentPrimary,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Utility Widgets ────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  final String label;

  const _LoadingCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accentPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
