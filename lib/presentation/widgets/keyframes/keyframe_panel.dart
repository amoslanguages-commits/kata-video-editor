import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/utils/time_utils.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/keyframes/keyframe_parameters.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class KeyframePanel extends ConsumerStatefulWidget {
  const KeyframePanel({super.key});

  @override
  ConsumerState<KeyframePanel> createState() => _KeyframePanelState();
}

class _KeyframePanelState extends ConsumerState<KeyframePanel> {
  String _selectedParameter = 'transform.scale';
  String _selectedInterpolation = KeyframeInterpolation.linear;
  String _selectedEasing = KeyframeInterpolation.easeInOut;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(selectedProjectProvider).value;
    final editorState = ref.watch(editorStateProvider);
    final selectedClipAsync = ref.watch(selectedClipProvider);

    if (project == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: AppTheme.surfaceDark,
      child: selectedClipAsync.when(
        data: (clip) {
          if (clip == null) {
            return const _EmptyKeyframeState();
          }

          final keyframesAsync = ref.watch(clipKeyframesProvider(clip.id));

          return keyframesAsync.when(
            data: (keyframes) {
              final parameterKeyframes = keyframes
                  .where((keyframe) => keyframe.parameter == _selectedParameter)
                  .toList()
                ..sort((a, b) => a.timeMicros.compareTo(b.timeMicros));

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Header(
                    selectedParameter: _selectedParameter,
                    keyframeCount: parameterKeyframes.length,
                  ),
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: KeyframeParameters.all.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final parameter = KeyframeParameters.all[index];

                        return _ParameterChip(
                          parameter: parameter,
                          selected: parameter.id == _selectedParameter,
                          onTap: () {
                            setState(() {
                              _selectedParameter = parameter.id;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: _KeyframeMiniTimeline(
                      clip: clip,
                      keyframes: parameterKeyframes,
                      currentTimelineMicros: editorState.currentTimeMicros,
                      onSeek: (timelineMicros) {
                        ref.read(editorStateProvider.notifier).seekTo(timelineMicros);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _SmallDropdown(
                          value: _selectedInterpolation,
                          options: const {
                            KeyframeInterpolation.hold: 'Hold',
                            KeyframeInterpolation.linear: 'Linear',
                            KeyframeInterpolation.easeIn: 'Ease In',
                            KeyframeInterpolation.easeOut: 'Ease Out',
                            KeyframeInterpolation.easeInOut: 'Ease In-Out',
                            KeyframeInterpolation.smooth: 'Smooth',
                          },
                          onChanged: (value) {
                            setState(() {
                              _selectedInterpolation = value;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _SmallDropdown(
                          value: _selectedEasing,
                          options: const {
                            KeyframeInterpolation.linear: 'Linear Easing',
                            KeyframeInterpolation.easeIn: 'Ease In Curve',
                            KeyframeInterpolation.easeOut: 'Ease Out Curve',
                            KeyframeInterpolation.easeInOut: 'Ease In-Out',
                            KeyframeInterpolation.smooth: 'Smooth Spring',
                          },
                          onChanged: (value) {
                            setState(() {
                              _selectedEasing = value;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add/Update'),
                            onPressed: () async {
                              await _addOrUpdateKeyframe(
                                context: context,
                                projectId: project.id,
                                clipId: clip.id,
                                timelineMicros: editorState.currentTimeMicros,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.skip_previous_rounded, size: 18),
                            label: const Text('Prev'),
                            onPressed: () async {
                              await _seekPrevious(
                                clipId: clip.id,
                                timelineMicros: editorState.currentTimeMicros,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.skip_next_rounded, size: 18),
                            label: const Text('Next'),
                            onPressed: () async {
                              await _seekNext(
                                clipId: clip.id,
                                timelineMicros: editorState.currentTimeMicros,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text('Delete'),
                            onPressed: () async {
                              await _deleteNearest(
                                context: context,
                                projectId: project.id,
                                clipId: clip.id,
                                timelineMicros: editorState.currentTimeMicros,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _KeyframeList(
                    clip: clip,
                    keyframes: parameterKeyframes,
                  ),
                ],
              );
            },
            loading: () {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentPrimary),
              );
            },
            error: (err, stack) {
              return Center(
                child: Text(
                  'Keyframe error: $err',
                  style: const TextStyle(color: AppTheme.error),
                ),
              );
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentPrimary),
          );
        },
        error: (err, stack) {
          return Center(
            child: Text(
              'Selected clip error: $err',
              style: const TextStyle(color: AppTheme.error),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addOrUpdateKeyframe({
    required BuildContext context,
    required String projectId,
    required String clipId,
    required int timelineMicros,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(keyframeCommandServiceProvider).addOrUpdateKeyframeAtTimelineTime(
            projectId: projectId,
            clipId: clipId,
            parameter: _selectedParameter,
            timelineMicros: timelineMicros,
            interpolation: _selectedInterpolation,
            easing: _selectedEasing,
          );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Keyframe saved to render graph.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> _seekPrevious({
    required String clipId,
    required int timelineMicros,
  }) async {
    final time = await ref.read(keyframeCommandServiceProvider).previousKeyframeTimelineTime(
          clipId: clipId,
          parameter: _selectedParameter,
          timelineMicros: timelineMicros,
        );

    if (time != null) {
      await ref.read(editorStateProvider.notifier).seekTo(time);
    }
  }

  Future<void> _seekNext({
    required String clipId,
    required int timelineMicros,
  }) async {
    final time = await ref.read(keyframeCommandServiceProvider).nextKeyframeTimelineTime(
          clipId: clipId,
          parameter: _selectedParameter,
          timelineMicros: timelineMicros,
        );

    if (time != null) {
      await ref.read(editorStateProvider.notifier).seekTo(time);
    }
  }

  Future<void> _deleteNearest({
    required BuildContext context,
    required String projectId,
    required String clipId,
    required int timelineMicros,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(keyframeCommandServiceProvider).deleteNearestKeyframe(
            projectId: projectId,
            clipId: clipId,
            parameter: _selectedParameter,
            timelineMicros: timelineMicros,
          );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Keyframe deleted.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text(e.toString()),
        ),
      );
    }
  }
}

class _Header extends StatelessWidget {
  final String selectedParameter;
  final int keyframeCount;

  const _Header({
    required this.selectedParameter,
    required this.keyframeCount,
  });

  @override
  Widget build(BuildContext context) {
    final parameter = KeyframeParameters.byId(selectedParameter);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          const Icon(
            Icons.animation_rounded,
            color: AppTheme.accentPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${parameter.label} • $keyframeCount keyframes',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Text(
            'Graph only for now',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParameterChip extends StatelessWidget {
  final KeyframeParameter parameter;
  final bool selected;
  final VoidCallback onTap;

  const _ParameterChip({
    required this.parameter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentPrimary.withValues(alpha: 0.16)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.accentPrimary : AppTheme.borderSubtle,
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              parameter.label,
              style: TextStyle(
                color: selected ? AppTheme.accentPrimary : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              parameter.group,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const _SmallDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: AppTheme.surfaceElevated,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
          ),
        ),
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        items: options.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _KeyframeMiniTimeline extends StatelessWidget {
  final Clip clip;
  final List<Keyframe> keyframes;
  final int currentTimelineMicros;
  final ValueChanged<int> onSeek;

  const _KeyframeMiniTimeline({
    required this.clip,
    required this.keyframes,
    required this.currentTimelineMicros,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final duration = clip.timelineEndMicros - clip.timelineStartMicros;
    final playheadInside = (currentTimelineMicros - clip.timelineStartMicros).clamp(0, duration);

    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        final width = box?.size.width ?? 1;
        final fraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
        final seek = clip.timelineStartMicros + (duration * fraction).round();

        onSeek(seek);
      },
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
        ),
        child: CustomPaint(
          painter: _KeyframeTimelinePainter(
            keyframes: keyframes,
            durationMicros: duration,
            playheadMicros: playheadInside,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _KeyframeTimelinePainter extends CustomPainter {
  final List<Keyframe> keyframes;
  final int durationMicros;
  final int playheadMicros;

  _KeyframeTimelinePainter({
    required this.keyframes,
    required this.durationMicros,
    required this.playheadMicros,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.borderSubtle
      ..strokeWidth = 1;

    final keyPaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.fill;

    final playheadPaint = Paint()
      ..color = AppTheme.playhead
      ..strokeWidth = 2;

    final centerY = size.height / 2;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      linePaint,
    );

    for (final keyframe in keyframes) {
      final x = durationMicros <= 0
          ? 0.0
          : (keyframe.timeMicros / durationMicros).clamp(0.0, 1.0) * size.width;

      final path = Path()
        ..moveTo(x, centerY - 6)
        ..lineTo(x + 6, centerY)
        ..lineTo(x, centerY + 6)
        ..lineTo(x - 6, centerY)
        ..close();

      canvas.drawPath(path, keyPaint);
    }

    final playheadX = durationMicros <= 0
        ? 0.0
        : (playheadMicros / durationMicros).clamp(0.0, 1.0) * size.width;

    canvas.drawLine(
      Offset(playheadX, 4),
      Offset(playheadX, size.height - 4),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _KeyframeTimelinePainter oldDelegate) {
    return oldDelegate.keyframes != keyframes ||
        oldDelegate.durationMicros != durationMicros ||
        oldDelegate.playheadMicros != playheadMicros;
  }
}

class _KeyframeList extends StatelessWidget {
  final Clip clip;
  final List<Keyframe> keyframes;

  const _KeyframeList({
    required this.clip,
    required this.keyframes,
  });

  @override
  Widget build(BuildContext context) {
    if (keyframes.isEmpty) {
      return const Center(
        child: Text(
          'No keyframes for this parameter yet.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: keyframes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final keyframe = keyframes[index];
        final value = _decodeValue(keyframe.valueJson);
        final timelineTime = clip.timelineStartMicros + keyframe.timeMicros;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.diamond_rounded,
                color: AppTheme.accentPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  TimeUtils.formatMicros(timelineTime),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                keyframe.interpolation,
                style: const TextStyle(
                  color: AppTheme.textDisabled,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _decodeValue(String raw) {
    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        final value = decoded['value'];

        if (value is num) {
          if (value.abs() >= 10) {
            return value.toStringAsFixed(0);
          }

          return value.toStringAsFixed(2);
        }

        return value.toString();
      }
    } catch (_) {}

    return raw;
  }
}

class _EmptyKeyframeState extends StatelessWidget {
  const _EmptyKeyframeState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select a clip, then add keyframes to animate it.',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
