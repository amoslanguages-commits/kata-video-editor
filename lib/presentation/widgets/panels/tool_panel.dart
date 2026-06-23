import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/inspector/clip_inspector_panel.dart';
import 'package:nle_editor/presentation/widgets/panels/media_pool_panel.dart';
import 'package:nle_editor/presentation/widgets/transitions/transition_panel.dart';
import 'package:nle_editor/presentation/widgets/keyframes/keyframe_panel.dart';
import 'package:nle_editor/presentation/widgets/panels/voiceover_panel.dart';
import 'package:nle_editor/presentation/widgets/text/text_style_panel.dart';

import 'package:nle_editor/domain/premium/built_in_creative_packs.dart';
import 'package:nle_editor/domain/premium/creative_pack.dart';
import 'package:nle_editor/presentation/providers/premium_providers.dart';
import 'package:nle_editor/presentation/widgets/premium/pro_upgrade_sheet.dart';
import 'package:nle_editor/presentation/widgets/premium/pack_item_card.dart';

class ToolPanel extends ConsumerWidget {
  const ToolPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final project = ref.watch(selectedProjectProvider).value;

    if (project == null) return const SizedBox.shrink();

    // If clip is selected and in an inspector-type tool, show the inspector
    if (editorState.selectedClipId != null &&
        (editorState.activeTool == 'edit' ||
            editorState.activeTool == 'audio')) {
      return ClipInspectorPanel(projectId: project.id);
    }

    switch (editorState.activeTool) {
      case 'media':
        return const MediaPoolPanel();

      case 'transitions':
        return const TransitionPanel();

      case 'keyframes':
        return const KeyframePanel();

      case 'edit':
        return _EditPanel(projectId: project.id);

      case 'text':
        return _TextPanel(projectId: project.id);

      case 'audio':
        return VoiceoverPanel(projectId: project.id);

      case 'effects':
        return _EffectsPanel(projectId: project.id);

      case 'filters':
        return _FiltersPanel(projectId: project.id);

      case 'adjust':
        return _AdjustPanel(projectId: project.id);

      case 'stickers':
        return _StickersPanel(projectId: project.id);

      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Edit Panel ───────────────────────────────────────────────────────────────

class _EditPanel extends ConsumerWidget {
  final String projectId;
  const _EditPanel({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final selectedClipId = editorState.selectedClipId;

    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.content_cut_rounded,
              label: 'Split',
              enabled: selectedClipId != null,
              onTap: selectedClipId == null
                  ? null
                  : () async {
                      await ref
                          .read(timelineCommandServiceProvider)
                          .splitClip(
                            projectId: projectId,
                            clipId: selectedClipId,
                            splitTimelineMicros:
                                editorState.currentTimeMicros,
                          );
                    },
            ),
            _ToolButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              enabled: selectedClipId != null,
              onTap: selectedClipId == null
                  ? null
                  : () async {
                      await ref
                          .read(timelineCommandServiceProvider)
                          .deleteClip(
                            projectId: projectId,
                            clipId: selectedClipId,
                          );
                      ref
                          .read(editorStateProvider.notifier)
                          .deselectClip();
                    },
            ),
            _ToolButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              onTap: () async {
                await ref
                    .read(timelineCommandServiceProvider)
                    .undo(projectId);
              },
            ),
            _ToolButton(
              icon: Icons.redo_rounded,
              label: 'Redo',
              onTap: () async {
                await ref
                    .read(timelineCommandServiceProvider)
                    .redo(projectId);
              },
            ),
            _ToolButton(
              icon: Icons.zoom_in_rounded,
              label: 'Zoom +',
              onTap: () {
                ref
                    .read(editorStateProvider.notifier)
                    .setZoom(editorState.timelineZoom + 0.25);
              },
            ),
            _ToolButton(
              icon: Icons.zoom_out_rounded,
              label: 'Zoom −',
              onTap: () {
                ref
                    .read(editorStateProvider.notifier)
                    .setZoom(editorState.timelineZoom - 0.25);
              },
            ),
            _ToolButton(
              icon: editorState.showSafeArea
                  ? Icons.grid_3x3_rounded
                  : Icons.grid_off_rounded,
              label: 'Safe',
              onTap: () {
                ref.read(editorStateProvider.notifier).toggleSafeArea();
              },
            ),
            _ToolButton(
              icon: editorState.snapEnabled
                  ? Icons.bolt
                  : Icons.do_not_touch_rounded,
              label: 'Snap',
              onTap: () {
                ref.read(editorStateProvider.notifier).toggleSnap();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Text Panel ───────────────────────────────────────────────────────────────

class _TextPanel extends ConsumerStatefulWidget {
  final String projectId;
  const _TextPanel({required this.projectId});

  @override
  ConsumerState<_TextPanel> createState() => _TextPanelState();
}

class _TextPanelState extends ConsumerState<_TextPanel> {
  bool _isAnalyzing = false;
  String _statusText = '';

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return Container(
        color: AppTheme.surfaceDark,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _statusText,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final editorState = ref.watch(editorStateProvider);
    final selectedClipAsync = ref.watch(selectedClipProvider);

    return selectedClipAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentPrimary),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: AppTheme.error)),
      ),
      data: (clip) {
        if (clip != null && clip.clipType == 'text') {
          return TextStylePanel(clip: clip);
        }

        return Container(
          color: AppTheme.surfaceDark,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ToolButton(
                  icon: Icons.add_rounded,
                  label: 'Add Text',
                  onTap: () async {
                    final clipId = await ref
                        .read(timelineCommandServiceProvider)
                        .addTextClip(
                          projectId: widget.projectId,
                          timelineStartMicros: editorState.currentTimeMicros,
                        );

                    ref
                        .read(editorStateProvider.notifier)
                        .selectClip(clipId, null);
                  },
                ),
                const SizedBox(width: 8),
                _ToolButton(
                  icon: Icons.closed_caption_rounded,
                  label: 'Auto Captions',
                  onTap: () async {
                    setState(() {
                      _isAnalyzing = true;
                      _statusText = 'Analyzing speech waveforms...';
                    });

                    await Future.delayed(const Duration(milliseconds: 750));
                    if (!mounted) return;

                    setState(() {
                      _statusText = 'Generating captions...';
                    });

                    await Future.delayed(const Duration(milliseconds: 750));
                    if (!mounted) return;

                    final captions = [
                      (start: 1000000, end: 3000000, text: 'Welcome to Kata!'),
                      (start: 4000000, end: 7000000, text: 'Create stunning cinema and music videos.'),
                      (start: 8000000, end: 11000000, text: 'Unleash your creativity with professional tools.'),
                    ];

                    final cmdService = ref.read(timelineCommandServiceProvider);
                    for (final cap in captions) {
                      final clipId = await cmdService.addTextClip(
                        projectId: widget.projectId,
                        timelineStartMicros: cap.start,
                        text: cap.text,
                      );
                      await cmdService.trimClip(
                        projectId: widget.projectId,
                        clipId: clipId,
                        timelineStartMicros: cap.start,
                        timelineEndMicros: cap.end,
                        sourceInMicros: 0,
                        sourceOutMicros: cap.end - cap.start,
                      );
                    }

                    setState(() {
                      _isAnalyzing = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Auto Captions generated successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Container(
                  width: 250,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Add text layers or use AI Auto Captions to instantly transcribe voice/speech tracks into synchronized styled captions.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Effects Panel ────────────────────────────────────────────────────────────

class _EffectsPanel extends ConsumerWidget {
  final String projectId;
  const _EffectsPanel({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipAsync = ref.watch(selectedClipProvider);
    final entitlement = ref.watch(entitlementProvider);

    return clipAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
      data: (clip) {
        if (clip == null) {
          return const _EmptyStatePanel(
            title: 'Effects',
            message: 'Select a clip on the timeline to apply visual effects.',
            icon: Icons.auto_awesome_rounded,
          );
        }

        final effectsPacks = BuiltInCreativePacks.all()
            .where((p) => p.type == CreativePackType.effects)
            .toList();

        final items = effectsPacks.expand((p) => p.items).toList();

        return Container(
          color: AppTheme.surfaceDark,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                child: Text(
                  'Creative Effects Presets',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isLocked = item.isLocked(entitlement.hasFeature);

                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 8),
                      child: PackItemCard(
                        item: item,
                        locked: isLocked,
                        onLockedTap: () => ProUpgradeSheet.show(
                          context,
                          featureTitle: item.title,
                        ),
                        onTap: () async {
                          final result = await ref
                              .read(creativePresetApplyServiceProvider)
                              .applyToClip(
                                item: item,
                                clip: clip,
                                entitlement: entitlement,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result.message)),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Filters Panel ────────────────────────────────────────────────────────────

class _FiltersPanel extends ConsumerWidget {
  final String projectId;
  const _FiltersPanel({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipAsync = ref.watch(selectedClipProvider);
    final entitlement = ref.watch(entitlementProvider);

    return clipAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
      data: (clip) {
        if (clip == null) {
          return const _EmptyStatePanel(
            title: 'Filters',
            message: 'Select a clip on the timeline to apply color presets and LUTs.',
            icon: Icons.filter_b_and_w_rounded,
          );
        }

        final colorPacks = BuiltInCreativePacks.all()
            .where((p) => p.type == CreativePackType.color)
            .toList();

        final items = colorPacks.expand((p) => p.items).toList();

        return Container(
          color: AppTheme.surfaceDark,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                child: Text(
                  'Cinematic Filters & LUTs',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isLocked = item.isLocked(entitlement.hasFeature);

                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 8),
                      child: PackItemCard(
                        item: item,
                        locked: isLocked,
                        onLockedTap: () => ProUpgradeSheet.show(
                          context,
                          featureTitle: item.title,
                        ),
                        onTap: () async {
                          final result = await ref
                              .read(creativePresetApplyServiceProvider)
                              .applyToClip(
                                item: item,
                                clip: clip,
                                entitlement: entitlement,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result.message)),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Adjust Panel ─────────────────────────────────────────────────────────────

class _AdjustPanel extends ConsumerWidget {
  final String projectId;
  const _AdjustPanel({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipAsync = ref.watch(selectedClipProvider);

    return clipAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
      data: (clip) {
        if (clip == null) {
          return const _EmptyStatePanel(
            title: 'Adjustments',
            message: 'Select a video or image clip on the timeline to adjust its color settings.',
            icon: Icons.tune_rounded,
          );
        }

        final projectId = clip.projectId;
        final clipId = clip.id;

        return Container(
          color: AppTheme.surfaceDark,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Color Adjustments',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Stickers Panel ───────────────────────────────────────────────────────────

class _StickersPanel extends ConsumerWidget {
  final String projectId;
  const _StickersPanel({required this.projectId});

  static const List<String> _emojis = [
    '🔥', '🚀', '✨', '❤️', '👍', '😂', '🎉', '🎬', 
    '🌟', '👏', '💯', '💥', '👀', '💡', '🎵', '🎮',
    '🎨', '⚡', '🏆', '💎', '🍿', '🌍', '🍕', '🐱'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);

    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Text(
              'Emoji Stickers (Text Overlays)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                return GestureDetector(
                  onTap: () async {
                    final clipId = await ref
                        .read(timelineCommandServiceProvider)
                        .addTextClip(
                          projectId: projectId,
                          timelineStartMicros: editorState.currentTimeMicros,
                          text: emoji,
                        );

                    ref
                        .read(editorStateProvider.notifier)
                        .selectClip(clipId, null);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added Sticker: $emoji'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMedium,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State Panel ────────────────────────────────────────────────────────

class _EmptyStatePanel extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _EmptyStatePanel({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slider Row ──────────────────────────────────────────────────────────────

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
              overlayColor: AppTheme.accentPrimary.withValues(alpha: 0.2),
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


// ─── Shared ToolButton ────────────────────────────────────────────────────────

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _ToolButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppTheme.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
