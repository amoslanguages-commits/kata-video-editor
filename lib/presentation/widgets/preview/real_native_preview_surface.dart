import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/preview/native_preview_session.dart';
import 'package:nle_editor/presentation/providers/real_native_preview_provider.dart';

class RealNativePreviewSurface extends ConsumerWidget {
  final String projectId;

  const RealNativePreviewSurface({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(realNativePreviewProvider(projectId));
    final controller = ref.read(realNativePreviewProvider(projectId).notifier);

    return Container(
      color: AppTheme.editorBackground,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _aspectRatio(state),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: state.surfaceId == null
                      ? _NativeRequiredMessage(state: state)
                      : Texture(textureId: state.surfaceId!),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _statusText(state),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: state.phase == NativePreviewSessionPhase.error
                          ? AppTheme.error
                          : AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: state.isBusy ? null : controller.prepare,
                  icon: const Icon(Icons.power_settings_new_rounded),
                  label: const Text('Prepare'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: state.surfaceId == null
                      ? null
                      : () => controller.requestFrame(state.playheadMicros),
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Frame'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _aspectRatio(NativePreviewSessionState state) {
    final width = state.surfaceWidth;
    final height = state.surfaceHeight;
    if (width == null || height == null || height == 0) return 16 / 9;
    return width / height;
  }

  String _statusText(NativePreviewSessionState state) {
    if (state.errorMessage != null) return state.errorMessage!;
    if (state.surfaceId == null) {
      return 'Native preview not ready. Press Prepare to request a real native surface.';
    }
    return 'Native surface #${state.surfaceId} ready • ${state.surfaceWidth}x${state.surfaceHeight}';
  }
}

class _NativeRequiredMessage extends StatelessWidget {
  final NativePreviewSessionState state;

  const _NativeRequiredMessage({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        state.phase == NativePreviewSessionPhase.error
            ? 'Native preview failed. No placeholder is shown.'
            : 'Waiting for real native preview surface. No placeholder preview is used.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}
