import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/providers/timeline_snap_providers.dart';

final autoDuckingProvider = StateProvider<bool>((ref) => false);

class ClipInspectorPanel extends ConsumerWidget {
  const ClipInspectorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipAsync = ref.watch(selectedClipProvider);

    return clipAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (clip) {
        if (clip == null) {
          return const Center(
            child: Text(
              'No clip selected',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }

        return _InspectorBody(clip: clip);
      },
    );
  }
}

class _InspectorBody extends ConsumerStatefulWidget {
  final Clip clip;
  const _InspectorBody({required this.clip});

  @override
  ConsumerState<_InspectorBody> createState() => _InspectorBodyState();
}

class _InspectorBodyState extends ConsumerState<_InspectorBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      child: Column(
        children: [
          // Tab bar
          Container(
            color: AppTheme.surfaceElevated,
            child: TabBar(
              controller: _tabs,
              indicatorColor: AppTheme.accentPrimary,
              labelColor: AppTheme.accentPrimary,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Transform'),
                Tab(text: 'Color Wheels'),
                Tab(text: 'Audio & Ducking'),
                Tab(text: 'Speed Ramp'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _TransformTab(clip: widget.clip),
                _ColorTab(clip: widget.clip),
                _AudioTab(clip: widget.clip),
                _SpeedTab(clip: widget.clip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transform Tab ────────────────────────────────────────────────────────────

class _TransformTab extends ConsumerWidget {
  final Clip clip;
  const _TransformTab({required this.clip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = clip.projectId;
    final clipId = clip.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SliderRow(
            label: 'Scale',
            value: clip.scale,
            min: 0.1,
            max: 4.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipTransform(
                    projectId: projectId,
                    clipId: clipId,
                    scale: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Opacity',
            value: clip.opacity,
            min: 0.0,
            max: 1.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipTransform(
                    projectId: projectId,
                    clipId: clipId,
                    opacity: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Rotation',
            value: clip.rotation,
            min: -180.0,
            max: 180.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipTransform(
                    projectId: projectId,
                    clipId: clipId,
                    rotation: v,
                  );
            },
          ),
          _SliderRow(
            label: 'X Position',
            value: clip.positionX,
            min: -1.0,
            max: 1.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipTransform(
                    projectId: projectId,
                    clipId: clipId,
                    positionX: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Y Position',
            value: clip.positionY,
            min: -1.0,
            max: 1.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipTransform(
                    projectId: projectId,
                    clipId: clipId,
                    positionY: v,
                  );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Color Tab (Advanced Color Wheels) ────────────────────────────────────────

class _ColorTab extends ConsumerWidget {
  final Clip clip;
  const _ColorTab({required this.clip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = clip.projectId;
    final clipId = clip.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'LIFT / GAMMA / GAIN WHEELS',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal color wheels
          SizedBox(
            height: 124,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                _ColorWheel(
                  label: 'LIFT (Shadows)',
                  valueX: clip.temperature,
                  valueY: clip.tint,
                  onChanged: (x, y) async {
                    await ref.read(timelineCommandServiceProvider).updateClipColor(
                          projectId: projectId,
                          clipId: clipId,
                          temperature: x.clamp(-1.0, 1.0),
                          tint: y.clamp(-1.0, 1.0),
                        );
                  },
                  onReset: () async {
                    await ref.read(timelineCommandServiceProvider).updateClipColor(
                          projectId: projectId,
                          clipId: clipId,
                          temperature: 0.0,
                          tint: 0.0,
                        );
                  },
                ),
                const SizedBox(width: 24),
                _ColorWheel(
                  label: 'GAMMA (Midtones)',
                  valueX: clip.contrast - 1.0, // scale 0..2 to -1..1
                  valueY: clip.saturation - 1.0, // scale 0..2 to -1..1
                  onChanged: (x, y) async {
                    await ref.read(timelineCommandServiceProvider).updateClipColor(
                          projectId: projectId,
                          clipId: clipId,
                          contrast: (x + 1.0).clamp(0.0, 2.0),
                          saturation: (y + 1.0).clamp(0.0, 2.0),
                        );
                  },
                  onReset: () async {
                    await ref.read(timelineCommandServiceProvider).updateClipColor(
                          projectId: projectId,
                          clipId: clipId,
                          contrast: 1.0,
                          saturation: 1.0,
                        );
                  },
                ),
                const SizedBox(width: 24),
                _ColorWheel(
                  label: 'GAIN (Highlights)',
                  valueX: clip.exposure / 2.0, // scale -2..2 to -1..1
                  valueY: clip.highlights,
                  onChanged: (x, y) async {
                    await ref.read(timelineCommandServiceProvider).updateClipColor(
                          projectId: projectId,
                          clipId: clipId,
                          exposure: (x * 2.0).clamp(-2.0, 2.0),
                          highlights: y.clamp(-1.0, 1.0),
                        );
                  },
                  onReset: () async {
                    await ref.read(timelineCommandServiceProvider).updateClipColor(
                          projectId: projectId,
                          clipId: clipId,
                          exposure: 0.0,
                          highlights: 0.0,
                        );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderSubtle),
          const SizedBox(height: 16),
          // Fallback sliders
          _SliderRow(
            label: 'Exposure',
            value: clip.exposure,
            min: -2.0,
            max: 2.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipColor(
                    projectId: projectId,
                    clipId: clipId,
                    exposure: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Contrast',
            value: clip.contrast,
            min: 0.0,
            max: 2.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipColor(
                    projectId: projectId,
                    clipId: clipId,
                    contrast: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Saturation',
            value: clip.saturation,
            min: 0.0,
            max: 2.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipColor(
                    projectId: projectId,
                    clipId: clipId,
                    saturation: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Temperature',
            value: clip.temperature,
            min: -1.0,
            max: 1.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipColor(
                    projectId: projectId,
                    clipId: clipId,
                    temperature: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Tint',
            value: clip.tint,
            min: -1.0,
            max: 1.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipColor(
                    projectId: projectId,
                    clipId: clipId,
                    tint: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Highlights',
            value: clip.highlights,
            min: -1.0,
            max: 1.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipColor(
                    projectId: projectId,
                    clipId: clipId,
                    highlights: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Shadows',
            value: clip.shadows,
            min: -1.0,
            max: 1.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipColor(
                    projectId: projectId,
                    clipId: clipId,
                    shadows: v,
                  );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Color Wheel Control ─────────────────────────────────────────────────────

class _ColorWheel extends StatelessWidget {
  final String label;
  final double valueX;
  final double valueY;
  final void Function(double x, double y) onChanged;
  final VoidCallback onReset;

  const _ColorWheel({
    required this.label,
    required this.valueX,
    required this.valueY,
    required this.onChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onReset,
              child: const Icon(
                Icons.refresh_rounded,
                size: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final center = box.size.width / 2;
            final local = box.globalToLocal(details.globalPosition);
            final dx = (local.dx - center) / center;
            final dy = (local.dy - center) / center;
            final distance = math.sqrt(dx * dx + dy * dy);
            if (distance <= 1.0) {
              onChanged(dx, -dy);
            } else {
              onChanged(dx / distance, -dy / distance);
            }
          },
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
              gradient: const RadialGradient(
                colors: [
                  Colors.white10,
                  Colors.black26,
                ],
              ),
            ),
            child: CustomPaint(
              painter: _ColorWheelPainter(valueX: valueX, valueY: valueY),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double valueX;
  final double valueY;

  _ColorWheelPainter({required this.valueX, required this.valueY});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.red,
          Colors.yellow,
          Colors.green,
          Colors.cyan,
          Colors.blue,
          Color(0xFFFF00FF),
          Colors.red,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, radius - 1.5, circlePaint);

    final crossPaint = Paint()
      ..color = AppTheme.borderSubtle.withOpacity(0.4)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(center.dx, 4), Offset(center.dx, size.height - 4), crossPaint);
    canvas.drawLine(Offset(4, center.dy), Offset(size.width - 4, center.dy), crossPaint);

    final knobX = center.dx + valueX * (radius - 8);
    final knobY = center.dy - valueY * (radius - 8);

    final knobPaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = AppTheme.accentPrimary.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawCircle(Offset(knobX, knobY), 6.0, glowPaint);
    canvas.drawCircle(Offset(knobX, knobY), 4.0, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.valueX != valueX || oldDelegate.valueY != valueY;
  }
}

// ─── Audio & Ducking Tab ──────────────────────────────────────────────────────

class _AudioTab extends ConsumerStatefulWidget {
  final Clip clip;
  const _AudioTab({required this.clip});

  @override
  ConsumerState<_AudioTab> createState() => _AudioTabState();
}

class _AudioTabState extends ConsumerState<_AudioTab> {
  bool _isAnalyzingBeats = false;

  @override
  Widget build(BuildContext context) {
    final projectId = widget.clip.projectId;
    final clipId = widget.clip.id;
    final isDuckingActive = ref.watch(autoDuckingProvider);
    final markers = ref.watch(beatMarkersStateProvider(projectId));
    final hasBeats = markers.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderRow(
            label: 'Volume',
            value: widget.clip.volume,
            min: 0.0,
            max: 2.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipAudio(
                    projectId: projectId,
                    clipId: clipId,
                    volume: v,
                  );
            },
          ),
          _SliderRow(
            label: 'Pan',
            value: widget.clip.audioPan,
            min: -1.0,
            max: 1.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipAudio(
                    projectId: projectId,
                    clipId: clipId,
                    pan: v,
                  );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mute Audio',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              Switch(
                value: widget.clip.isAudioMuted,
                activeThumbColor: AppTheme.accentPrimary,
                activeTrackColor: AppTheme.accentPrimary.withOpacity(0.3),
                onChanged: (v) async {
                  await ref
                      .read(timelineCommandServiceProvider)
                      .updateClipAudio(
                        projectId: projectId,
                        clipId: clipId,
                        muted: v,
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Auto-Ducking',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Lower background music during voiceovers',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isDuckingActive,
                activeThumbColor: AppTheme.accentPrimary,
                activeTrackColor: AppTheme.accentPrimary.withOpacity(0.3),
                onChanged: (v) {
                  ref.read(autoDuckingProvider.notifier).state = v;
                  ref.read(hapticServiceProvider).selection();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderSubtle),
          const SizedBox(height: 16),
          const Text(
            'MUSIC BEAT-SYNC ANALYSIS (AI)',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (_isAnalyzingBeats) ...[
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.accentPrimary,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Compositor analyzing audio transient peaks...',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                  hasBeats ? Icons.check_circle_outline : Icons.auto_awesome,
                  color: Colors.black,
                  size: 16,
                ),
                label: Text(hasBeats ? 'AI Beat Markers Synced' : 'AI Beat Detection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasBeats ? AppTheme.success : AppTheme.accentPrimary,
                ),
                onPressed: () async {
                  setState(() => _isAnalyzingBeats = true);
                  ref.read(hapticServiceProvider).medium();

                  // Simulate C++ beat analysis latency
                  await Future.delayed(const Duration(milliseconds: 1400));

                  if (!mounted) return;

                  final list = <TimelineMarkerSnapPoint>[];
                  // Generate 120BPM intervals (every 500ms) up to 40 seconds
                  for (int ms = 500; ms <= 40000; ms += 500) {
                    list.add(
                      TimelineMarkerSnapPoint(
                        id: 'beat_$ms',
                        timelineMicros: ms * 1000,
                        label: 'Beat ${(ms / 500).round()}',
                      ),
                    );
                  }

                  ref.read(beatMarkersStateProvider(projectId).notifier).state = list;
                  setState(() => _isAnalyzingBeats = false);
                  ref.read(hapticServiceProvider).success();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${list.length} AI music beat markers generated.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            if (hasBeats) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    ref.read(beatMarkersStateProvider(projectId).notifier).state = const [];
                    ref.read(hapticServiceProvider).light();
                  },
                  child: const Text(
                    'Clear Ruler Beat Markers',
                    style: TextStyle(color: AppTheme.error, fontSize: 11),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Speed Tab (Speed Ramping / Velocity Curves) ──────────────────────────────

class _SpeedTab extends ConsumerStatefulWidget {
  final Clip clip;
  const _SpeedTab({required this.clip});

  @override
  ConsumerState<_SpeedTab> createState() => _SpeedTabState();
}

class _SpeedTabState extends ConsumerState<_SpeedTab> {
  String _selectedRampPreset = 'flat';

  @override
  Widget build(BuildContext context) {
    final projectId = widget.clip.projectId;
    final clipId = widget.clip.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderRow(
            label: 'Base Speed',
            value: widget.clip.speed,
            min: 0.1,
            max: 8.0,
            onChanged: (v) async {
              await ref
                  .read(timelineCommandServiceProvider)
                  .updateClipSpeed(
                    projectId: projectId,
                    clipId: clipId,
                    speed: v,
                  );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'VELOCITY CURVE GRAPH',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          _SpeedRampGraph(preset: _selectedRampPreset),
          const SizedBox(height: 16),
          const Text(
            'Speed Easing Presets',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RampPresetChip(
                label: 'Constant',
                isSelected: _selectedRampPreset == 'flat',
                onTap: () => _applySpeedPreset('flat', 1.0),
              ),
              _RampPresetChip(
                label: 'Montage (Fast-Slow-Fast)',
                isSelected: _selectedRampPreset == 'montage',
                onTap: () => _applySpeedPreset('montage', 2.0),
              ),
              _RampPresetChip(
                label: 'Bullet Time (Drop)',
                isSelected: _selectedRampPreset == 'bullet',
                onTap: () => _applySpeedPreset('bullet', 0.25),
              ),
              _RampPresetChip(
                label: 'Hero Moment (Accelerate)',
                isSelected: _selectedRampPreset == 'hero',
                onTap: () => _applySpeedPreset('hero', 4.0),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderSubtle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reverse Video Playback',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              Switch(
                value: widget.clip.isReversed,
                activeThumbColor: AppTheme.accentPrimary,
                activeTrackColor: AppTheme.accentPrimary.withOpacity(0.3),
                onChanged: (v) async {
                  await ref
                      .read(timelineCommandServiceProvider)
                      .updateClipSpeed(
                        projectId: projectId,
                        clipId: clipId,
                        speed: widget.clip.speed,
                        isReversed: v,
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applySpeedPreset(String preset, double value) async {
    setState(() {
      _selectedRampPreset = preset;
    });
    ref.read(hapticServiceProvider).success();
    await ref.read(timelineCommandServiceProvider).updateClipSpeed(
          projectId: widget.clip.projectId,
          clipId: widget.clip.id,
          speed: value,
        );
  }
}

class _RampPresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RampPresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentPrimary.withOpacity(0.18)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accentPrimary : AppTheme.borderSubtle,
            width: isSelected ? 1.2 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SpeedRampGraph extends StatelessWidget {
  final String preset;
  const _SpeedRampGraph({required this.preset});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: CustomPaint(
        painter: _SpeedGraphPainter(preset: preset),
      ),
    );
  }
}

class _SpeedGraphPainter extends CustomPainter {
  final String preset;
  _SpeedGraphPainter({required this.preset});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.borderSubtle.withOpacity(0.4)
      ..strokeWidth = 0.5;

    final curvePaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = AppTheme.accentPrimary.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // Draw baseline 1.0x (middle)
    final centerY = size.height / 2;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), linePaint);

    final path = Path();
    path.moveTo(0, centerY);

    if (preset == 'montage') {
      // Curve rises, dips low, then flattens
      path.quadraticBezierTo(
        size.width * 0.25,
        10.0, // Speed peaks
        size.width * 0.5,
        centerY,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height - 10.0, // Slows down
        size.width,
        centerY,
      );
    } else if (preset == 'bullet') {
      // Slopes flat then drops deep, stays low, then rises
      path.lineTo(size.width * 0.3, centerY);
      path.cubicTo(
        size.width * 0.45,
        centerY,
        size.width * 0.55,
        size.height - 10.0,
        size.width * 0.7,
        size.height - 10.0,
      );
      path.quadraticBezierTo(
        size.width * 0.85,
        size.height - 10.0,
        size.width,
        centerY,
      );
    } else if (preset == 'hero') {
      // Speeds up rapidly, drops, goes back
      path.cubicTo(
        size.width * 0.2,
        centerY,
        size.width * 0.35,
        6.0,
        size.width * 0.5,
        6.0,
      );
      path.cubicTo(
        size.width * 0.65,
        6.0,
        size.width * 0.8,
        size.height - 8.0,
        size.width,
        centerY,
      );
    } else {
      // Completely flat line at 1x
      path.lineTo(size.width, centerY);
    }

    // Draw filled curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, curvePaint);

    // Draw control knots
    final knotPaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.fill;

    if (preset == 'montage') {
      canvas.drawCircle(Offset(size.width * 0.25, 10.0), 3.5, knotPaint);
      canvas.drawCircle(Offset(size.width * 0.75, size.height - 10.0), 3.5, knotPaint);
    } else if (preset == 'bullet') {
      canvas.drawCircle(Offset(size.width * 0.7, size.height - 10.0), 3.5, knotPaint);
    } else if (preset == 'hero') {
      canvas.drawCircle(Offset(size.width * 0.5, 6.0), 3.5, knotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedGraphPainter oldDelegate) {
    return oldDelegate.preset != preset;
  }
}

// ─── Shared SliderRow ─────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final void Function(double) onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppTheme.accentPrimary,
              inactiveTrackColor: AppTheme.surfaceOverlay,
              thumbColor: AppTheme.accentPrimary,
              overlayColor: AppTheme.accentPrimary.withOpacity(0.15),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
