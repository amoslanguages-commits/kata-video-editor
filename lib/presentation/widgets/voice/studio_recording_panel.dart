import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';
import 'package:nle_editor/domain/voice/voice_take_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/voice_recording_providers.dart';
import 'package:nle_editor/presentation/widgets/voice/voice_recording_meter_view.dart';

class StudioRecordingPanel extends ConsumerWidget {
  const StudioRecordingPanel({super.key});

  String _formatDuration(int micros) {
    final ms = (micros / 1000).round();
    final seconds = (ms / 1000).floor();
    final hundredths = ((ms % 1000) / 10).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;

    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = remainingSeconds.toString().padLeft(2, '0');
    final hundredthStr = hundredths.toString().padLeft(2, '0');

    return '$minStr:$secStr.$hundredthStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) {
      return const Center(
        child: Text(
          'Please select a project first.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final playhead = ref.watch(editorStateProvider.select((s) => s.currentTimeMicros));
    final args = VoiceRecordingControllerArgs(
      projectId: projectId,
      timelinePlayheadMicros: playhead,
    );

    final session = ref.watch(voiceRecordingControllerProvider(args));
    final controller = ref.read(voiceRecordingControllerProvider(args).notifier);

    return Container(
      color: AppTheme.surfaceDark,
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
              vertical: AppTheme.paddingMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.mic_rounded, color: AppTheme.accentPrimary),
                        SizedBox(width: 8),
                        Text(
                          'VOICE STUDIO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () {
                        // Close or switch tool back
                        ref.read(editorStateProvider.notifier).setTool('media');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (session.error != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingMedium,
                      vertical: AppTheme.paddingSmall,
                    ),
                    margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.error!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Live meter & elapsed time
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            session.status == NleVoiceRecordingStatus.recording
                                ? 'RECORDING'
                                : session.status.name.toUpperCase(),
                            style: TextStyle(
                              color: session.status == NleVoiceRecordingStatus.recording
                                  ? AppTheme.playhead
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(session.elapsedMicros),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      VoiceRecordingMeterView(meter: session.meter),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (session.status == NleVoiceRecordingStatus.recording) ...[
                      // Pause
                      _CircleButton(
                        icon: Icons.pause_rounded,
                        label: 'Pause',
                        color: Colors.amber.shade700,
                        onPressed: controller.pauseRecording,
                      ),
                      const SizedBox(width: 20),
                      // Stop / Save
                      _CircleButton(
                        icon: Icons.stop_rounded,
                        label: 'Save',
                        color: AppTheme.success,
                        onPressed: () => controller.stopRecording(insertIntoTimeline: true),
                      ),
                      const SizedBox(width: 20),
                      // Cancel / Discard
                      _CircleButton(
                        icon: Icons.close_rounded,
                        label: 'Discard',
                        color: AppTheme.error,
                        onPressed: controller.cancelRecording,
                      ),
                    ] else if (session.status == NleVoiceRecordingStatus.paused) ...[
                      // Resume
                      _CircleButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Resume',
                        color: AppTheme.accentPrimary,
                        onPressed: controller.resumeRecording,
                      ),
                      const SizedBox(width: 20),
                      // Stop / Save
                      _CircleButton(
                        icon: Icons.stop_rounded,
                        label: 'Save',
                        color: AppTheme.success,
                        onPressed: () => controller.stopRecording(insertIntoTimeline: true),
                      ),
                      const SizedBox(width: 20),
                      // Cancel
                      _CircleButton(
                        icon: Icons.close_rounded,
                        label: 'Discard',
                        color: AppTheme.error,
                        onPressed: controller.cancelRecording,
                      ),
                    ] else ...[
                      // Start Record Trigger
                      GestureDetector(
                        onTap: () => controller.startRecording(
                          cleanupPreset: NleVoiceCleanupPreset.cleanVoice,
                        ),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.playhead, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppTheme.playhead,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fiber_manual_record_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Settings & Take lists tabs
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TabBar(
                          dividerColor: Colors.transparent,
                          indicatorColor: AppTheme.accentPrimary,
                          labelColor: AppTheme.textPrimary,
                          unselectedLabelColor: AppTheme.textSecondary,
                          tabs: [
                            Tab(text: 'Settings'),
                            Tab(text: 'Takes'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Tab 1: Settings
                              _buildSettingsTab(session, controller),
                              // Tab 2: Takes list
                              _buildTakesTab(session, controller),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Countdown Overlay
          if (session.status == NleVoiceRecordingStatus.countingDown)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'GET READY',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CountdownNumberAnimation(seconds: session.countdownSeconds),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(
    NleVoiceRecordingSession session,
    VoiceRecordingController controller,
  ) {
    return ListView(
      children: [
        // Quality selector
        _DropdownTile<NleVoiceRecordingQuality>(
          label: 'Quality',
          value: session.quality,
          items: NleVoiceRecordingQuality.values,
          onChanged: (val) {
            if (val != null) controller.setQuality(val);
          },
          labelBuilder: (q) => q.name.toUpperCase(),
        ),

        // Countdown selector
        _DropdownTile<int>(
          label: 'Countdown Timer',
          value: session.countdownSeconds,
          items: const [0, 2, 3, 5, 10],
          onChanged: (val) {
            if (val != null) controller.setCountdownSeconds(val);
          },
          labelBuilder: (sec) => sec == 0 ? 'Off' : '$sec Seconds',
        ),

        // Monitoring
        _DropdownTile<NleVoiceMonitoringMode>(
          label: 'Voice Monitoring',
          value: session.monitoringMode,
          items: NleVoiceMonitoringMode.values,
          onChanged: (val) {
            if (val != null) controller.setMonitoringMode(val);
          },
          labelBuilder: (m) => m == NleVoiceMonitoringMode.off
              ? 'Off'
              : m == NleVoiceMonitoringMode.lowLatency
                  ? 'Low Latency'
                  : 'Safe Delayed',
        ),

        // If recording active, let user change cleanup preset live
        if (session.activeTakeId != null)
          _DropdownTile<NleVoiceCleanupPreset>(
            label: 'Voice Cleanup Filter',
            value: session.takes.where((t) => t.id == session.activeTakeId).firstOrNull?.cleanupPreset ?? NleVoiceCleanupPreset.none,
            items: NleVoiceCleanupPreset.values,
            onChanged: (val) {
              if (val != null) controller.setCleanupPreset(val);
            },
            labelBuilder: (preset) {
              switch (preset) {
                case NleVoiceCleanupPreset.none:
                  return 'No Cleanup Filter';
                case NleVoiceCleanupPreset.cleanVoice:
                  return 'Clean Voice';
                case NleVoiceCleanupPreset.podcastVoice:
                  return 'Podcast Voice';
                case NleVoiceCleanupPreset.noisyRoomCleanup:
                  return 'Noisy Room Cleanup';
                case NleVoiceCleanupPreset.loudSocialVoice:
                  return 'Loud Social Voice';
                case NleVoiceCleanupPreset.warmNarration:
                  return 'Warm Narration';
              }
            },
          ),
      ],
    );
  }

  Widget _buildTakesTab(
    NleVoiceRecordingSession session,
    VoiceRecordingController controller,
  ) {
    if (session.takes.isEmpty) {
      return const Center(
        child: Text(
          'No takes recorded yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      itemCount: session.takes.length,
      itemBuilder: (context, idx) {
        final take = session.takes[idx];
        final isActive = take.id == session.activeTakeId;
        final isInserted = take.inserted;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.surfaceOverlay : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            border: Border.all(
              color: isActive ? AppTheme.accentPrimary.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      take.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _formatDuration(take.durationMicros),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            take.cleanupPreset.name.toUpperCase(),
                            style: const TextStyle(color: AppTheme.accentPrimary, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isInserted)
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20)
              else
                IconButton(
                  icon: const Icon(Icons.add_to_photos_rounded, color: AppTheme.accentPrimary, size: 20),
                  tooltip: 'Insert to timeline',
                  onPressed: () => controller.insertExistingTake(take),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                tooltip: 'Delete take',
                onPressed: () => controller.deleteTake(take),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
          icon: Icon(icon, size: 24),
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) labelBuilder;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            alignment: Alignment.centerRight,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(labelBuilder(item), style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CountdownNumberAnimation extends StatefulWidget {
  final int seconds;
  const _CountdownNumberAnimation({required this.seconds});

  @override
  State<_CountdownNumberAnimation> createState() => _CountdownNumberAnimationState();
}

class _CountdownNumberAnimationState extends State<_CountdownNumberAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _CountdownNumberAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 2.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
      ),
      child: Text(
        '${widget.seconds}',
        style: const TextStyle(
          color: AppTheme.playhead,
          fontSize: 80,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
