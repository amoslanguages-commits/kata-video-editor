import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/presentation/providers/timeline_snap_providers.dart';

class TimelineSnapSettingsSheet extends ConsumerWidget {
  const TimelineSnapSettingsSheet({
    super.key,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      builder: (_) => const TimelineSnapSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(timelineSnapSettingsProvider);
    final controller = ref.read(timelineSnapSettingsProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PremiumSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: PremiumSpacing.lg),
            const Row(
              children: [
                Icon(
                  Icons.linear_scale_rounded,
                  color: AppTheme.warning,
                ),
                SizedBox(width: 10),
                Text(
                  'Snapping',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PremiumSpacing.lg),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                value: settings.enabled,
                onChanged: controller.setEnabled,
                title: const Text('Enable snapping'),
                subtitle: const Text(
                  'Use magnetic alignment while moving or trimming clips.',
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                value: settings.snapToPlayhead,
                onChanged: (_) => controller.togglePlayheadSnap(),
                title: const Text('Snap to playhead'),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                value: settings.snapToClipEdges,
                onChanged: (_) => controller.toggleClipEdgeSnap(),
                title: const Text('Snap to clip edges'),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                value: settings.snapToTimelineZero,
                onChanged: (_) => controller.toggleTimelineZeroSnap(),
                title: const Text('Snap to timeline start'),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                value: settings.snapToMarkers,
                onChanged: (_) => controller.toggleMarkerSnap(),
                title: const Text('Snap to markers'),
              ),
            ),
            const SizedBox(height: PremiumSpacing.sm),
            Row(
              children: [
                const Text(
                  'Sensitivity',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: settings.thresholdPx,
                    min: 4,
                    max: 32,
                    divisions: 14,
                    label: '${settings.thresholdPx.round()} px',
                    onChanged: controller.setThresholdPx,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
