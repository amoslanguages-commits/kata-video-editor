// 33A-PRO: Audio Engine Foundation — Audio Track Lane Widget
//
// The timeline lane for a single audio track. Shows:
//  - Track label + role icon
//  - Mute / Solo buttons
//  - Volume knob (slider)
//  - Clips with waveform rendering

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/presentation/providers/audio_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/audio/audio_waveform_renderer.dart';

class AudioTrackLane extends ConsumerWidget {
  final String projectId;
  final db.Track track;

  const AudioTrackLane({
    super.key,
    required this.projectId,
    required this.track,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioControllerProvider(projectId));
    final isSelected = audioState.selectedTrackId == track.id;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1E2D3D)
            : const Color(0xFF141921),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withAlpha(18),
            width: 1,
          ),
          left: BorderSide(
            color: isSelected
                ? const Color(0xFF29D884)
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          ref
              .read(audioControllerProvider(projectId).notifier)
              .selectTrack(track.id);
        },
        child: Row(
          children: [
            // ─ Track header ────────────────────────────────────────────
            Container(
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TrackHeaderRow(
                    projectId: projectId,
                    track: track,
                  ),
                  const SizedBox(height: 4),
                  _VolumeSlider(
                    projectId: projectId,
                    track: track,
                  ),
                ],
              ),
            ),

            // ─ Clips area ──────────────────────────────────────────────
            Expanded(
              child: _AudioClipsArea(
                projectId: projectId,
                track: track,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Track Header Row ──────────────────────────────────────────────────────────

class _TrackHeaderRow extends ConsumerWidget {
  final String    projectId;
  final db.Track  track;

  const _TrackHeaderRow({required this.projectId, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Role icon
        Icon(
          _roleIcon(track.trackRole),
          size: 12,
          color: const Color(0xFF29D884),
        ),
        const SizedBox(width: 4),

        // Track name
        Expanded(
          child: Text(
            track.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 4),

        // Mute button
        _MuteButton(projectId: projectId, track: track),
        const SizedBox(width: 2),

        // Solo button
        _SoloButton(projectId: projectId, track: track),
      ],
    );
  }

  IconData _roleIcon(String? role) {
    switch (role) {
      case 'video_audio':
        return Icons.videocam_outlined;
      case 'voiceover':
        return Icons.mic_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'sfx':
        return Icons.graphic_eq;
      default:
        return Icons.audio_file_outlined;
    }
  }
}

// ── Mute / Solo Buttons ───────────────────────────────────────────────────────

class _MuteButton extends ConsumerWidget {
  final String   projectId;
  final db.Track track;

  const _MuteButton({required this.projectId, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AudioTrackButton(
      label:     'M',
      isActive:  track.isMuted,
      activeColor: Colors.amber,
      onTap: () {
        ref
            .read(audioControllerProvider(projectId).notifier)
            .toggleTrackMute(track.id);
      },
    );
  }
}

class _SoloButton extends ConsumerWidget {
  final String   projectId;
  final db.Track track;

  const _SoloButton({required this.projectId, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AudioTrackButton(
      label:      'S',
      isActive:   track.isSolo,
      activeColor: const Color(0xFF29D884),
      onTap: () {
        ref
            .read(audioControllerProvider(projectId).notifier)
            .toggleTrackSolo(track.id);
      },
    );
  }
}

class _AudioTrackButton extends StatelessWidget {
  final String  label;
  final bool    isActive;
  final Color   activeColor;
  final VoidCallback onTap;

  const _AudioTrackButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width:  20,
        height: 16,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color:       isActive ? Colors.black : Colors.white54,
            fontSize:    10,
            fontWeight:  FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Volume Slider ─────────────────────────────────────────────────────────────

class _VolumeSlider extends ConsumerWidget {
  final String   projectId;
  final db.Track track;

  const _VolumeSlider({required this.projectId, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Icon(Icons.volume_up, size: 10, color: Colors.white38),
        const SizedBox(width: 2),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight:    2,
              thumbShape:     const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape:   const RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor:   const Color(0xFF29D884),
              inactiveTrackColor: Colors.white12,
              thumbColor:         const Color(0xFF29D884),
              overlayColor:       const Color(0x2029D884),
            ),
            child: Slider(
              value:    track.volume.clamp(0.0, 2.0),
              min:      0.0,
              max:      2.0,
              onChanged: (v) {
                ref
                    .read(audioControllerProvider(projectId).notifier)
                    .setTrackVolume(trackId: track.id, volume: v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Clips Area ────────────────────────────────────────────────────────────────

class _AudioClipsArea extends ConsumerWidget {
  final String   projectId;
  final db.Track track;

  const _AudioClipsArea({required this.projectId, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the existing editor clip stream to get clips for this track.
    final editorClipsAsync = ref.watch(trackClipsProvider(track.id));

    return editorClipsAsync.when(
      loading: () => const SizedBox.expand(),
      error:   (_, __) => const SizedBox.expand(),
      data:    (clips) {
        if (clips.isEmpty) {
          return _EmptyTrackHint();
        }
        return _AudioClipList(
          projectId: projectId,
          trackId:   track.id,
          clips:     clips,
        );
      },
    );
  }
}

class _EmptyTrackHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Drop audio here',
        style: TextStyle(color: Colors.white24, fontSize: 11),
      ),
    );
  }
}

class _AudioClipList extends StatelessWidget {
  final String        projectId;
  final String        trackId;
  final List<db.Clip> clips;

  const _AudioClipList({
    required this.projectId,
    required this.trackId,
    required this.clips,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: clips.map((clip) {
            return _AudioClipTile(clip: clip);
          }).toList(),
        );
      },
    );
  }
}

class _AudioClipTile extends StatelessWidget {
  final db.Clip clip;

  const _AudioClipTile({required this.clip});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color:         const Color(0xFF1A3A2A),
        borderRadius:  BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF29D884).withAlpha(80),
          width: 1,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Waveform
          if (clip.assetId != null)
            Positioned.fill(
              child: AudioWaveformRenderer(
                assetId:        clip.assetId!,
                waveformColor:  const Color(0xFF29D884),
                backgroundColor: Colors.transparent,
              ),
            ),

          // Muted overlay
          if (clip.isAudioMuted)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.volume_off,
                  size: 14,
                  color: Colors.white54,
                ),
              ),
            ),

          // Fade-in indicator
          if (clip.fadeInMicros > 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black38, Colors.transparent],
                  ),
                ),
              ),
            ),

          // Fade-out indicator
          if (clip.fadeOutMicros > 0)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black38],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
