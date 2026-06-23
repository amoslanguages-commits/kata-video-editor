import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/services/voiceover_recording_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:flutter/services.dart';

class VoiceoverPanel extends ConsumerWidget {
  final String projectId;

  const VoiceoverPanel({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceoverRecordingServiceProvider);
    final voiceNotifier = ref.read(voiceoverRecordingServiceProvider.notifier);
    final editorState = ref.watch(editorStateProvider);

    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!voiceState.isRecording) ...[
            const Icon(Icons.mic_rounded, color: AppTheme.textMuted, size: 36),
            const SizedBox(height: 8),
            const Text(
              'Voiceover Recording',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Record real-time audio directly to the timeline playhead.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.fiber_manual_record_rounded,
                  color: Colors.red),
              label: const Text('Start Recording',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                HapticFeedback.heavyImpact();
                final success = await voiceNotifier.startRecording(
                  projectId: projectId,
                  timelineStartMicros: editorState.currentTimeMicros,
                );
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Could not start recording. Please check microphone permissions.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ] else ...[
            // Recording Active State
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recording: ${(voiceState.durationMicros / 1000000.0).toStringAsFixed(1)}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause / Resume
                IconButton(
                  icon: Icon(
                    voiceState.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: Colors.white,
                  ),
                  iconSize: 28,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (voiceState.isPaused) {
                      voiceNotifier.resumeRecording();
                    } else {
                      voiceNotifier.pauseRecording();
                    }
                  },
                ),
                const SizedBox(width: 24),
                // Stop & Save
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Save'),
                  onPressed: () async {
                    ref.read(hapticServiceProvider).success();
                    final clipId = await voiceNotifier.stopRecording();
                    if (clipId != null) {
                      ref
                          .read(editorStateProvider.notifier)
                          .selectClip(clipId, null);
                    }
                  },
                ),
                const SizedBox(width: 24),
                // Cancel / Discard
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Discard'),
                  onPressed: () {
                    ref.read(hapticServiceProvider).warning();
                    voiceNotifier.cancelRecording();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
