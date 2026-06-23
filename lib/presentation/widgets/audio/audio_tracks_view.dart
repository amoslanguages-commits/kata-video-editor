// 33A-PRO: Audio Engine Foundation — Audio Tracks View
//
// The vertical stack of audio track lanes shown in the timeline editor.
// Placed below the video tracks in the main timeline scroll area.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/presentation/providers/audio_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/audio/audio_track_lane.dart';
import 'package:nle_editor/presentation/widgets/audio/audio_meter_widget.dart';

class AudioTracksView extends ConsumerWidget {
  final String projectId;

  const AudioTracksView({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(projectAudioTracksProvider(projectId));

    return tracksAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (e, _) => _errorWidget(e.toString()),
      data:    (tracks) {
        if (tracks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─ Section header ─────────────────────────────────────────
            _AudioSectionHeader(
              projectId:   projectId,
              trackCount:  tracks.length,
            ),

            // ─ Track lanes ────────────────────────────────────────────
            ...tracks.map(
              (track) => AudioTrackLane(
                projectId: projectId,
                track:     track,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _errorWidget(String message) {
    return Container(
      height: 40,
      color: Colors.red.withAlpha(20),
      alignment: Alignment.center,
      child: Text(
        'Audio tracks error: $message',
        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _AudioSectionHeader extends ConsumerWidget {
  final String projectId;
  final int    trackCount;

  const _AudioSectionHeader({
    required this.projectId,
    required this.trackCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 24,
      color: const Color(0xFF0C1117),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.queue_music, size: 12, color: Color(0xFF29D884)),
          const SizedBox(width: 6),
          Text(
            'AUDIO ($trackCount)',
            style: const TextStyle(
              color:       Color(0xFF29D884),
              fontSize:    10,
              fontWeight:  FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          // Master meter (compact)
          SizedBox(
            height: 20,
            child: AudioMasterMeter(projectId: projectId),
          ),
          const SizedBox(width: 8),
          // Auto-ducking toggle
          const _AutoDuckingButton(),
        ],
      ),
    );
  }
}

// ── Auto-Ducking Toggle ───────────────────────────────────────────────────────

class _AutoDuckingButton extends ConsumerWidget {
  const _AutoDuckingButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(autoDuckingProvider);

    return Tooltip(
      message: enabled ? 'Auto-ducking ON' : 'Auto-ducking OFF',
      child: GestureDetector(
        onTap: () {
          ref.read(autoDuckingProvider.notifier).state = !enabled;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: enabled
                ? const Color(0xFF29D884).withAlpha(30)
                : Colors.transparent,
            border: Border.all(
              color: enabled ? const Color(0xFF29D884) : Colors.white24,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'DUCK',
            style: TextStyle(
              color:      enabled ? const Color(0xFF29D884) : Colors.white38,
              fontSize:   9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

/// Shown in the timeline when no audio tracks exist yet.
class AudioTracksEmptyState extends StatelessWidget {
  const AudioTracksEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_circle_outline, size: 14, color: Colors.white24),
          SizedBox(width: 6),
          Text(
            'Import audio to add a track',
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
