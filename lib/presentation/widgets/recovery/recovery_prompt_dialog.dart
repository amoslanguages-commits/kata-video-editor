import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/recovery/recovery_snapshot_info.dart';

/// Shown when a project is opened and recovery data (autosave / session) is
/// found on disk. The user can choose to restore or dismiss.
///
/// Returns a [ProjectRecoveryDecision] when popped.
class RecoveryPromptDialog extends StatelessWidget {
  final RecoverySnapshotInfo info;

  const RecoveryPromptDialog({
    super.key,
    required this.info,
  });

  static Future<ProjectRecoveryDecision?> show(
    BuildContext context,
    RecoverySnapshotInfo info,
  ) {
    return showDialog<ProjectRecoveryDecision>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecoveryPromptDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 0.5),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restore_rounded,
              color: AppTheme.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Recover editing session?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'We found a saved editing session for this project. '
            'You can restore your playhead position, selected clip, '
            'and latest autosave reference.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _RecoveryRow(
            label: 'Autosave',
            value: info.hasAutosave
                ? 'Found • ${_fmt(info.autosaveModifiedAt)}'
                : 'Not found',
            good: info.hasAutosave,
          ),
          const SizedBox(height: 8),
          _RecoveryRow(
            label: 'Session',
            value: info.hasSession
                ? 'Found • ${_fmt(info.sessionSavedAt)}'
                : 'Not found',
            good: info.hasSession,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOverlay,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: AppTheme.textMuted,
                  size: 14,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'V1 recovery is safe — it restores your editor session '
                    'and keeps the autosave file. '
                    'It will not overwrite your project automatically.',
                    style: TextStyle(
                      color: AppTheme.textDisabled,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            ProjectRecoveryDecision.dismiss(),
          ),
          child: const Text(
            'Ignore',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentPrimary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.restore_rounded, size: 16),
          label: const Text(
            'Restore Session',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.pop(
            context,
            ProjectRecoveryDecision.restoreSession(),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime? date) {
    if (date == null) return 'unknown';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    final local = date.toLocal();
    final month = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][local.month - 1];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final min = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '$month ${local.day}, $hour:$min $ampm';
  }
}

// ─── Row widget ───────────────────────────────────────────────────────────────

class _RecoveryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool good;

  const _RecoveryRow({
    required this.label,
    required this.value,
    required this.good,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            good
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            color: good ? AppTheme.success : AppTheme.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
