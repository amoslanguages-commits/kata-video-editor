import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/preview/native_preview_session.dart';
import 'package:nle_editor/presentation/providers/native_preview_providers.dart';

class NativePreviewSessionPanel extends ConsumerWidget {
  final String projectId;

  const NativePreviewSessionPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nativePreviewSessionProvider(projectId));
    final controller = ref.read(nativePreviewSessionProvider(projectId).notifier);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_display_rounded, color: AppTheme.accentPrimary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Native Preview Session',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _phaseLabel(state.phase),
            style: TextStyle(color: _phaseColor(state.phase), fontSize: 12),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.editorBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Center(
                child: Text(
                  'Native preview surface foundation\n${state.maxPreviewWidth}x${state.maxPreviewHeight} • ${state.qualityMode}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => controller.markPreparing().then((_) => controller.markReady()),
                icon: const Icon(Icons.power_settings_new_rounded),
                label: const Text('Prepare'),
              ),
              OutlinedButton.icon(
                onPressed: () => controller.markPlaying(),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play'),
              ),
              OutlinedButton.icon(
                onPressed: () => controller.markPaused(),
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pause'),
              ),
              OutlinedButton.icon(
                onPressed: () => controller.markStopped(),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _phaseLabel(NativePreviewSessionPhase phase) {
    switch (phase) {
      case NativePreviewSessionPhase.idle:
        return 'Idle — preview session not prepared yet.';
      case NativePreviewSessionPhase.preparing:
        return 'Preparing native preview session.';
      case NativePreviewSessionPhase.ready:
        return 'Ready — native preview session is prepared.';
      case NativePreviewSessionPhase.playing:
        return 'Playing native preview.';
      case NativePreviewSessionPhase.paused:
        return 'Paused native preview.';
      case NativePreviewSessionPhase.stopped:
        return 'Stopped native preview.';
      case NativePreviewSessionPhase.error:
        return 'Preview error.';
    }
  }

  static Color _phaseColor(NativePreviewSessionPhase phase) {
    switch (phase) {
      case NativePreviewSessionPhase.error:
        return AppTheme.error;
      case NativePreviewSessionPhase.playing:
      case NativePreviewSessionPhase.ready:
        return AppTheme.success;
      case NativePreviewSessionPhase.preparing:
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }
}
