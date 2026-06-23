import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/transitions/transition_presets.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class TransitionPanel extends ConsumerStatefulWidget {
  const TransitionPanel({super.key});

  @override
  ConsumerState<TransitionPanel> createState() => _TransitionPanelState();
}

class _TransitionPanelState extends ConsumerState<TransitionPanel> {
  String _selectedPreset = 'dissolve';
  double _durationMs = 500;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(selectedProjectProvider).value;
    final selectedClipAsync = ref.watch(selectedClipProvider);

    if (project == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: AppTheme.surfaceDark,
      child: selectedClipAsync.when(
        data: (clip) {
          if (clip == null) {
            return const _EmptyTransitionState();
          }

          return FutureBuilder<List<Clip>>(
            future: ref.watch(timelineRepositoryProvider).getTrackClips(clip.trackId),
            builder: (context, snapshot) {
              final trackClips = snapshot.data ?? [];

              final pair = _findAdjacentClips(
                selectedClip: clip,
                trackClips: trackClips,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    presetId: _selectedPreset,
                    durationMs: _durationMs.round(),
                  ),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: TransitionPresets.all.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final preset = TransitionPresets.all[index];

                        return _TransitionPresetTile(
                          preset: preset,
                          selected: preset.id == _selectedPreset,
                          onTap: () {
                            setState(() {
                              _selectedPreset = preset.id;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Text(
                          'Duration',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _durationMs,
                            min: 100,
                            max: 2000,
                            divisions: 19,
                            activeColor: AppTheme.accentPrimary,
                            onChanged: (value) {
                              setState(() {
                                _durationMs = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 54,
                          child: Text(
                            '${_durationMs.round()}ms',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.keyboard_arrow_left_rounded),
                            label: const Text('Before'),
                            onPressed: pair.previous == null
                                ? null
                                : () async {
                                    await _addTransition(
                                      context: context,
                                      projectId: project.id,
                                      outgoingClipId: pair.previous!.id,
                                      incomingClipId: clip.id,
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.keyboard_arrow_right_rounded),
                            label: const Text('After'),
                            onPressed: pair.next == null
                                ? null
                                : () async {
                                    await _addTransition(
                                      context: context,
                                      projectId: project.id,
                                      outgoingClipId: clip.id,
                                      incomingClipId: pair.next!.id,
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              'Transition error: $err',
              style: const TextStyle(color: AppTheme.error),
            ),
          );
        },
      ),
    );
  }

  _AdjacentClipPair _findAdjacentClips({
    required Clip selectedClip,
    required List<Clip> trackClips,
  }) {
    final sorted = [...trackClips]
      ..sort((a, b) => a.timelineStartMicros.compareTo(b.timelineStartMicros));

    Clip? previous;
    Clip? next;

    for (final clip in sorted) {
      if (clip.id == selectedClip.id) {
        continue;
      }

      if (clip.timelineEndMicros <= selectedClip.timelineStartMicros) {
        previous = clip;
      }

      if (clip.timelineStartMicros >= selectedClip.timelineEndMicros) {
        next ??= clip;
      }
    }

    return _AdjacentClipPair(
      previous: previous,
      next: next,
    );
  }

  Future<void> _addTransition({
    required BuildContext context,
    required String projectId,
    required String outgoingClipId,
    required String incomingClipId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(transitionCommandServiceProvider).addOrUpdateTransition(
            projectId: projectId,
            outgoingClipId: outgoingClipId,
            incomingClipId: incomingClipId,
            transitionType: _selectedPreset,
            durationMicros: (_durationMs * 1000).round(),
          );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transition added to render graph.'),
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

class _AdjacentClipPair {
  final Clip? previous;
  final Clip? next;

  const _AdjacentClipPair({
    required this.previous,
    required this.next,
  });
}

class _Header extends StatelessWidget {
  final String presetId;
  final int durationMs;

  const _Header({
    required this.presetId,
    required this.durationMs,
  });

  @override
  Widget build(BuildContext context) {
    final preset = TransitionPresets.byId(presetId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          const Icon(
            Icons.compare_arrows_rounded,
            color: AppTheme.accentPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${preset.name} • ${durationMs}ms',
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

class _TransitionPresetTile extends StatelessWidget {
  final TransitionPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _TransitionPresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 112,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentPrimary.withValues(alpha: 0.16)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: selected ? AppTheme.accentPrimary : AppTheme.borderSubtle,
            width: selected ? 1.4 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconForPreset(preset.id),
              color: selected ? AppTheme.accentPrimary : AppTheme.textSecondary,
              size: 22,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppTheme.accentPrimary : AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (preset.isPremium)
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.warning,
                    size: 14,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              preset.category,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForPreset(String id) {
    switch (id) {
      case 'dissolve':
        return Icons.blur_on_rounded;
      case 'fade_black':
      case 'fade_white':
        return Icons.gradient_rounded;
      case 'slide_left':
      case 'slide_right':
      case 'push_up':
        return Icons.swipe_rounded;
      case 'wipe_left':
      case 'wipe_right':
        return Icons.layers_clear_rounded;
      case 'zoom_blur':
        return Icons.center_focus_strong_rounded;
      case 'flash':
        return Icons.flash_on_rounded;
      case 'glitch':
        return Icons.electric_bolt_rounded;
      default:
        return Icons.compare_arrows_rounded;
    }
  }
}

class _EmptyTransitionState extends StatelessWidget {
  const _EmptyTransitionState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select a clip, then add a transition before or after it.',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
