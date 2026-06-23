import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/timeline_snap_providers.dart';

class TimelineSnapToggle extends ConsumerWidget {
  const TimelineSnapToggle({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(timelineSnapSettingsProvider);
    final controller = ref.read(timelineSnapSettingsProvider.notifier);

    return Tooltip(
      message: settings.enabled ? 'Snapping on' : 'Snapping off',
      child: IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(
          Icons.linear_scale_rounded,
          size: 18,
          color: settings.enabled ? AppTheme.warning : AppTheme.textMuted,
        ),
        onPressed: controller.toggleEnabled,
      ),
    );
  }
}
