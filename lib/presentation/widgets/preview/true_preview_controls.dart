import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/native_true_preview_providers.dart';
import 'package:nle_editor/presentation/controllers/native_true_preview_controller.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_glass_card.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_bounce_button.dart';

class TruePreviewControls extends ConsumerWidget {
  final String projectId;

  const TruePreviewControls({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nativeTruePreviewControllerProvider(projectId));
    final controller =
        ref.read(nativeTruePreviewControllerProvider(projectId).notifier);
    final editorState = ref.watch(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);
    final timelineAsync = ref.watch(realProjectTimelineProvider(projectId));
    final durationMicros =
        timelineAsync.value?.durationMicros ?? (60 * 1000000);

    final isPlaying = state.status == TruePreviewUiStatus.playing;

    return PremiumGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumBounceButton(
            onTap: () async {
              final target = (editorState.currentTimeMicros - 5000000)
                  .clamp(0, durationMicros);
              editorNotifier.seekTo(target);
              await controller.renderFrame(target);
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.replay_5, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          PremiumBounceButton(
            onTap: () async {
              if (isPlaying) {
                editorNotifier.pause();
              } else {
                editorNotifier.play();
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.accentPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PremiumBounceButton(
            onTap: () async {
              final target = (editorState.currentTimeMicros + 5000000)
                  .clamp(0, durationMicros);
              editorNotifier.seekTo(target);
              await controller.renderFrame(target);
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.forward_5, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

