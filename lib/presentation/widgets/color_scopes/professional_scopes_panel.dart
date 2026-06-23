import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';
import 'package:nle_editor/presentation/providers/color_scope_providers.dart';
import 'package:nle_editor/presentation/widgets/color_scopes/clipping_warning_strip.dart';
import 'package:nle_editor/presentation/widgets/color_scopes/histogram_scope_painter.dart';
import 'package:nle_editor/presentation/widgets/color_scopes/rgb_parade_scope_painter.dart';
import 'package:nle_editor/presentation/widgets/color_scopes/vectorscope_painter.dart';
import 'package:nle_editor/presentation/widgets/color_scopes/waveform_scope_painter.dart';

class ProfessionalScopesPanel extends ConsumerWidget {
  const ProfessionalScopesPanel({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(colorScopeControllerProvider);
    final controller = ref.read(colorScopeControllerProvider.notifier);

    final settings = state.settings;
    final data = state.frameData;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070B14),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(PremiumSpacing.sm),
            child: Row(
              children: [
                const Text(
                  'Scopes',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<NleScopeType>(
                      segments: const [
                        ButtonSegment(
                          value: NleScopeType.waveform,
                          label: Text('Wave'),
                        ),
                        ButtonSegment(
                          value: NleScopeType.rgbParade,
                          label: Text('Parade'),
                        ),
                        ButtonSegment(
                          value: NleScopeType.vectorscope,
                          label: Text('Vector'),
                        ),
                        ButtonSegment(
                          value: NleScopeType.histogram,
                          label: Text('Hist'),
                        ),
                      ],
                      selected: {settings.activeType},
                      onSelectionChanged: (set) {
                        controller.setType(set.first);
                      },
                    ),
                  ),
                ),
                IconButton(
                  tooltip: state.live ? 'Stop scopes' : 'Start scopes',
                  onPressed: () {
                    if (state.live) {
                      controller.stopLive();
                    } else {
                      controller.startLive();
                    }
                  },
                  icon: Icon(
                    state.live
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                    color: state.live ? AppTheme.success : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (settings.showClippingWarnings)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ClippingWarningStrip(warnings: data.warnings),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(PremiumSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PremiumRadius.md),
                child: CustomPaint(
                  painter: _painterFor(settings, data),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: _ScopeOptionsRow(
              settings: settings,
              onSkinTone: controller.setSkinToneLine,
              onWarnings: controller.setClippingWarnings,
              onOverlay: controller.setOverlay,
            ),
          ),
        ],
      ),
    );
  }

  CustomPainter _painterFor(
    NleScopeSettings settings,
    NleScopeFrameData data,
  ) {
    switch (settings.activeType) {
      case NleScopeType.waveform:
        return WaveformScopePainter(
          points: data.waveform,
          showGrid: settings.showGrid,
        );

      case NleScopeType.rgbParade:
        return RgbParadeScopePainter(
          points: data.rgbParade,
          showGrid: settings.showGrid,
        );

      case NleScopeType.vectorscope:
        return VectorscopePainter(
          points: data.vectorscope,
          showGrid: settings.showGrid,
          showSkinToneLine: settings.showSkinToneLine,
        );

      case NleScopeType.histogram:
        return HistogramScopePainter(
          histogram: data.histogram,
          showGrid: settings.showGrid,
        );
    }
  }
}

class _ScopeOptionsRow extends StatelessWidget {
  final NleScopeSettings settings;
  final ValueChanged<bool> onSkinTone;
  final ValueChanged<bool> onWarnings;
  final ValueChanged<bool> onOverlay;

  const _ScopeOptionsRow({
    required this.settings,
    required this.onSkinTone,
    required this.onWarnings,
    required this.onOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        FilterChip(
          selected: settings.showSkinToneLine,
          label: const Text('Skin line'),
          onSelected: onSkinTone,
        ),
        FilterChip(
          selected: settings.showClippingWarnings,
          label: const Text('Warnings'),
          onSelected: onWarnings,
        ),
        FilterChip(
          selected: settings.showOverlay,
          label: const Text('Overlay'),
          onSelected: onOverlay,
        ),
      ],
    );
  }
}
