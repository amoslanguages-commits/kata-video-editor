// 33A-PRO: Audio Engine Foundation — Clip Audio Inspector Panel
//
// Shown in the inspector sidebar when an audio clip is selected.
// Allows editing: volume, pan, mute, fade-in, fade-out.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/presentation/providers/audio_providers.dart';
import 'package:nle_editor/presentation/widgets/audio/audio_waveform_renderer.dart';
import 'package:nle_editor/presentation/widgets/audio/audio_meter_widget.dart';

class ClipAudioInspector extends ConsumerWidget {
  final String projectId;
  final String clipId;
  final String trackId;

  const ClipAudioInspector({
    super.key,
    required this.projectId,
    required this.clipId,
    required this.trackId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the existing watchClip stream from editor_providers (watchClip on DB).
    final clipStream = ref.watch(
      StreamProvider.autoDispose.family<db.Clip?, String>(
        (r, id) => r.watch(audioRepositoryProvider).watchClip(id),
      )(clipId),
    );

    return clipStream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data:    (clip) {
        if (clip == null) return const SizedBox.shrink();
        return _ClipAudioPanel(
          projectId: projectId,
          clip:      clip,
          trackId:   trackId,
        );
      },
    );
  }
}

class _ClipAudioPanel extends ConsumerWidget {
  final String   projectId;
  final db.Clip  clip;
  final String   trackId;

  const _ClipAudioPanel({
    required this.projectId,
    required this.clip,
    required this.trackId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        ref.read(audioControllerProvider(projectId).notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.audio_file_outlined,
                  size: 16, color: Color(0xFF29D884)),
              const SizedBox(width: 8),
              const Text(
                'Audio',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              // Mute toggle
              _MuteToggle(
                isMuted: clip.isAudioMuted,
                onToggle: () => controller.setClipMuted(
                  trackId: trackId,
                  clipId:  clip.id,
                  isMuted: !clip.isAudioMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── Waveform preview ─────────────────────────────────────────
          if (clip.assetId != null)
            ClipShape(
              decoration: BoxDecoration(
                color:        Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AudioWaveformRenderer(
                  assetId: clip.assetId!,
                  height:  40,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ─── Volume ───────────────────────────────────────────────────
          _InspectorRow(
            label: 'Volume',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value:    clip.volume.clamp(0.0, 2.0),
                    min:      0.0,
                    max:      2.0,
                    divisions: 200,
                    label: '${(clip.volume * 100).round()}%',
                    activeColor: const Color(0xFF29D884),
                    onChanged: (v) => controller.setClipVolume(
                      trackId: trackId,
                      clipId:  clip.id,
                      volume:  v,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(clip.volume * 100).round()}%',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // ─── Pan ──────────────────────────────────────────────────────
          _InspectorRow(
            label: 'Pan',
            child: Row(
              children: [
                const Text('L', style: TextStyle(color: Colors.white38, fontSize: 10)),
                Expanded(
                  child: Slider(
                    value:    clip.audioPan.clamp(-1.0, 1.0),
                    min:      -1.0,
                    max:      1.0,
                    divisions: 200,
                    label: _panLabel(clip.audioPan),
                    activeColor: const Color(0xFF29D884),
                    onChanged: (v) => controller.setClipPan(
                      clipId: clip.id,
                      pan:    v,
                    ),
                  ),
                ),
                const Text('R', style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          // ─── Fades ───────────────────────────────────────────────────
          _FadeRow(
            label:         'Fade In',
            durationMicros: clip.fadeInMicros,
            onChanged:     (v) => controller.setClipFadeIn(
              clipId:         clip.id,
              durationMicros: v,
            ),
          ),

          const SizedBox(height: 8),

          _FadeRow(
            label:         'Fade Out',
            durationMicros: clip.fadeOutMicros,
            onChanged:     (v) => controller.setClipFadeOut(
              clipId:         clip.id,
              durationMicros: v,
            ),
          ),

          // ─── Volume bar ───────────────────────────────────────────────
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AudioVolumeIndicator(volume: clip.volume, width: 80),
            ],
          ),
        ],
      ),
    );
  }

  String _panLabel(double pan) {
    if (pan.abs() < 0.02) return 'C';
    final side = pan < 0 ? 'L' : 'R';
    return '${(pan.abs() * 100).round()}$side';
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _MuteToggle extends StatelessWidget {
  final bool         isMuted;
  final VoidCallback onToggle;

  const _MuteToggle({required this.isMuted, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isMuted ? Colors.amber.withAlpha(30) : Colors.transparent,
          border: Border.all(
            color: isMuted ? Colors.amber : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              size: 14,
              color: isMuted ? Colors.amber : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              isMuted ? 'Muted' : 'Active',
              style: TextStyle(
                color:    isMuted ? Colors.amber : Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _InspectorRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color:    Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _FadeRow extends StatelessWidget {
  final String   label;
  final int      durationMicros;
  final void Function(int) onChanged;

  const _FadeRow({
    required this.label,
    required this.durationMicros,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // max fade = 10 seconds
    const maxMicros = 10000000.0;
    final value = durationMicros.clamp(0, 10000000).toDouble();

    return _InspectorRow(
      label: label,
      child: Row(
        children: [
          Expanded(
            child: Slider(
              value:       value,
              min:         0,
              max:         maxMicros,
              divisions:   200,
              label:       _formatDuration(durationMicros),
              activeColor: const Color(0xFF29D884),
              onChanged:   (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              _formatDuration(durationMicros),
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int micros) {
    final ms = micros ~/ 1000;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000.0).toStringAsFixed(1)}s';
  }
}

/// A simple decoration wrapper.
class ClipShape extends StatelessWidget {
  final Decoration decoration;
  final Widget     child;

  const ClipShape({super.key, required this.decoration, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(decoration: decoration, child: child);
  }
}
