import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';

/// A small pill-shaped badge rendered on project cards (and optionally in the
/// editor app bar) when recovery data exists for a project.
///
/// [visible] — when false, renders a zero-size widget.
/// [onTap]   — optional tap handler (e.g. navigate to the project's editor).
class RecoveryBadge extends StatelessWidget {
  final bool visible;
  final VoidCallback? onTap;

  const RecoveryBadge({
    super.key,
    required this.visible,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.warning.withValues(alpha: 0.35),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restore_rounded,
              color: AppTheme.warning,
              size: 12,
            ),
            SizedBox(width: 4),
            Text(
              'Recovery',
              style: TextStyle(
                color: AppTheme.warning,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
