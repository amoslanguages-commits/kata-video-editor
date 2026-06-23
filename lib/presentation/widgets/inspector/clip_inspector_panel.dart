import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/presentation/providers/clip_inspector_providers.dart';
import 'package:nle_editor/presentation/controllers/clip_inspector_controller.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_audio_section.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_crop_fit_section.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_slider_row.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_speed_section.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_text_section.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_transform_section.dart';
import 'package:nle_editor/presentation/widgets/color_grade/primary_grade_panel.dart';
import 'package:nle_editor/presentation/widgets/color_lut/lut_panel.dart';
import 'package:nle_editor/presentation/widgets/color_curves/color_curves_panel.dart';
import 'package:nle_editor/presentation/widgets/color_qualifier/hsl_qualifier_panel.dart';
import 'package:nle_editor/presentation/widgets/film_look/film_look_panel.dart';

class ClipInspectorPanel extends ConsumerWidget {
  final String projectId;

  const ClipInspectorPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedClipInspectorProvider(projectId));

    return selected.when(
      loading: () => const _InspectorLoading(),
      error: (error, stackTrace) => _InspectorError(error: error),
      data: (clip) {
        if (clip == null) {
          return const _NoClipSelected();
        }

        return _InspectorContent(
          projectId: projectId,
          clip: clip,
        );
      },
    );
  }
}

class _InspectorContent extends ConsumerWidget {
  final String projectId;
  final ClipInspectorState clip;

  const _InspectorContent({
    required this.projectId,
    required this.clip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      clipInspectorControllerProvider(projectId),
    );

    return ListView(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      children: [
        _InspectorHeader(
          clip: clip,
          onResetVisual: clip.isVisual
              ? () async {
                  await controller.resetVisualAdjustments(clip.clipId);
                }
              : null,
        ),
        const SizedBox(height: PremiumSpacing.md),
        if (clip.isVisual) ...[
          InspectorTransformSection(
            clip: clip,
            onPositionXChanged: (value) {
              controller.updateTransform(
                clipId: clip.clipId,
                positionX: value,
              );
            },
            onPositionYChanged: (value) {
              controller.updateTransform(
                clipId: clip.clipId,
                positionY: value,
              );
            },
            onScaleChanged: (value) {
              controller.updateTransform(
                clipId: clip.clipId,
                scale: value,
              );
            },
            onRotationChanged: (value) {
              controller.updateTransform(
                clipId: clip.clipId,
                rotation: value,
              );
            },
            onOpacityChanged: (value) {
              controller.updateTransform(
                clipId: clip.clipId,
                opacity: value,
              );
            },
          ),
          const SizedBox(height: PremiumSpacing.md),
          InspectorCropFitSection(
            clip: clip,
            onFitModeChanged: (mode) {
              controller.updateFitAndCrop(
                clipId: clip.clipId,
                fitMode: mode,
              );
            },
            onCropLeftChanged: (value) {
              controller.updateFitAndCrop(
                clipId: clip.clipId,
                cropLeft: value,
              );
            },
            onCropTopChanged: (value) {
              controller.updateFitAndCrop(
                clipId: clip.clipId,
                cropTop: value,
              );
            },
            onCropRightChanged: (value) {
              controller.updateFitAndCrop(
                clipId: clip.clipId,
                cropRight: value,
              );
            },
            onCropBottomChanged: (value) {
              controller.updateFitAndCrop(
                clipId: clip.clipId,
                cropBottom: value,
              );
            },
          ),
          const SizedBox(height: PremiumSpacing.md),
          _ColorTabsSection(
            clip: clip,
            controller: controller,
          ),
          const SizedBox(height: PremiumSpacing.md),
        ],
        InspectorSpeedSection(
          clip: clip,
          onSpeedChanged: (value) {
            controller.updateSpeed(
              clipId: clip.clipId,
              speed: value,
            );
          },
        ),
        if (clip.isAudio) ...[
          const SizedBox(height: PremiumSpacing.md),
          InspectorAudioSection(
            clip: clip,
            onVolumeChanged: (value) {
              controller.updateAudio(
                clipId: clip.clipId,
                volume: value,
              );
            },
            onFadeInChanged: (value) {
              controller.updateAudio(
                clipId: clip.clipId,
                fadeInMicros: value,
              );
            },
            onFadeOutChanged: (value) {
              controller.updateAudio(
                clipId: clip.clipId,
                fadeOutMicros: value,
              );
            },
          ),
        ],
        if (clip.isText) ...[
          const SizedBox(height: PremiumSpacing.md),
          InspectorTextSection(
            clip: clip,
            onTextChanged: (value) {
              controller.updateText(
                clipId: clip.clipId,
                textContent: value,
              );
            },
            onColorChanged: (hex) {
              controller.updateText(
                clipId: clip.clipId,
                colorHex: hex,
              );
            },
            onStyleJsonChanged: (json) {
              controller.updateText(
                clipId: clip.clipId,
                textStyleJson: json,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _InspectorHeader extends StatelessWidget {
  final ClipInspectorState clip;
  final VoidCallback? onResetVisual;

  const _InspectorHeader({
    required this.clip,
    this.onResetVisual,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: PremiumGradients.brandGlow,
            ),
            child: Icon(
              _iconForType(clip.clipType),
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clip.name.trim().isEmpty ? 'Selected Clip' : clip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${clip.clipType.toUpperCase()} • ${clip.readableDuration}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (onResetVisual != null)
            IconButton(
              tooltip: 'Reset visual settings',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: onResetVisual,
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
      case 'music':
      case 'voice':
        return Icons.graphic_eq_rounded;
      case 'text':
      case 'caption':
      case 'title':
        return Icons.title_rounded;
      case 'image':
      case 'photo':
        return Icons.image_rounded;
      case 'adjustment':
        return Icons.tune_rounded;
      case 'video':
      default:
        return Icons.movie_rounded;
    }
  }
}

class _NoClipSelected extends StatelessWidget {
  const _NoClipSelected();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PremiumSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              color: AppTheme.textMuted.withValues(alpha: 0.7),
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'Select a clip',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap a timeline clip to edit transform, speed, audio, text, and color.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectorLoading extends StatelessWidget {
  const _InspectorLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _InspectorError extends StatelessWidget {
  final Object error;

  const _InspectorError({
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Inspector error: $error',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.error),
      ),
    );
  }
}

class _ColorTabsSection extends StatefulWidget {
  final ClipInspectorState clip;
  final ClipInspectorController controller;

  const _ColorTabsSection({
    required this.clip,
    required this.controller,
  });

  @override
  State<_ColorTabsSection> createState() => _ColorTabsSectionState();
}

class _ColorTabsSectionState extends State<_ColorTabsSection> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton(0, 'Basic Color'),
                _buildTabButton(1, 'Pro Color'),
                _buildTabButton(2, 'Wheels'),
                _buildTabButton(3, 'LUT'),
                _buildTabButton(4, 'Curves'),
                _buildTabButton(5, 'Qualifiers'),
                _buildTabButton(6, 'Film Look'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          Padding(
            padding: const EdgeInsets.all(PremiumSpacing.md),
            child: _buildActiveTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final active = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppTheme.accentPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.textPrimary : AppTheme.textMuted,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return Column(
          children: [
            InspectorSliderRow(
              label: 'Brightness',
              value: widget.clip.brightness,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) {
                widget.controller.updateColor(
                  clipId: widget.clip.clipId,
                  brightness: value,
                );
              },
            ),
            InspectorSliderRow(
              label: 'Contrast',
              value: widget.clip.contrast,
              min: 0.0,
              max: 3.0,
              divisions: 300,
              onChanged: (value) {
                widget.controller.updateColor(
                  clipId: widget.clip.clipId,
                  contrast: value,
                );
              },
            ),
            InspectorSliderRow(
              label: 'Saturation',
              value: widget.clip.saturation,
              min: 0.0,
              max: 3.0,
              divisions: 300,
              onChanged: (value) {
                widget.controller.updateColor(
                  clipId: widget.clip.clipId,
                  saturation: value,
                );
              },
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            InspectorSliderRow(
              label: 'Exposure',
              value: widget.clip.exposure,
              min: -2.0,
              max: 2.0,
              divisions: 400,
              onChanged: (value) {
                widget.controller.updateColor(
                  clipId: widget.clip.clipId,
                  exposure: value,
                );
              },
            ),
            InspectorSliderRow(
              label: 'Temperature',
              value: widget.clip.temperature,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) {
                widget.controller.updateColor(
                  clipId: widget.clip.clipId,
                  temperature: value,
                );
              },
            ),
            InspectorSliderRow(
              label: 'Tint',
              value: widget.clip.tint,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) {
                widget.controller.updateColor(
                  clipId: widget.clip.clipId,
                  tint: value,
                );
              },
            ),
            InspectorSliderRow(
              label: 'Highlights',
              value: widget.clip.highlights,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) {
                widget.controller.updateColor(
                  clipId: widget.clip.clipId,
                  highlights: value,
                );
              },
            ),
            InspectorSliderRow(
              label: 'Shadows',
              value: widget.clip.shadows,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) {
                widget.controller.updateColor(
                  clipId: widget.clip.clipId,
                  shadows: value,
                );
              },
            ),
          ],
        );
      case 2:
        return SizedBox(
          height: 380,
          child: PrimaryGradePanel(
            selectedClipId: widget.clip.clipId,
          ),
        );
      case 3:
        return SizedBox(
          height: 380,
          child: LutPanel(
            selectedClipId: widget.clip.clipId,
          ),
        );
      case 4:
        return SizedBox(
          height: 480,
          child: ColorCurvesPanel(
            selectedClipId: widget.clip.clipId,
          ),
        );
      case 5:
        return SizedBox(
          height: 480,
          child: HslQualifierPanel(
            selectedClipId: widget.clip.clipId,
          ),
        );
      case 6:
        return SizedBox(
          height: 540,
          child: FilmLookPanel(
            selectedClipId: widget.clip.clipId,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
