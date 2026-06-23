// lib/presentation/widgets/preview/source_preview_view.dart
//
// 29F: Source Preview monitor UI.
//
// Shows the raw media clip, in/out point scrubber, timecode, play/pause and
// the "Send to Timeline" button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/utils/time_utils.dart';
import 'package:nle_editor/domain/source_preview/source_preview_models.dart';
import 'package:nle_editor/presentation/controllers/source_preview_controller.dart';
import 'package:nle_editor/presentation/providers/source_preview_providers.dart';
import 'package:nle_editor/presentation/widgets/preview/source_audio_placeholder.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_glass_card.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_bounce_button.dart';


class SourcePreviewView extends ConsumerWidget {
  final String projectId;

  /// Called when the user sends the in/out selection to the timeline.
  /// [clipId] is the id of the newly inserted clip.
  final void Function(String clipId)? onInserted;

  /// Timeline playhead micros — used to determine where on the timeline the
  /// clip is inserted when the user taps "Send to Timeline".
  final int timelinePlayheadMicros;

  const SourcePreviewView({
    super.key,
    required this.projectId,
    this.onInserted,
    this.timelinePlayheadMicros = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(sourcePreviewControllerProvider(projectId).notifier);
    final state = ref.watch(sourcePreviewControllerProvider(projectId));

    return Column(
      children: [
        // ── Preview canvas ─────────────────────────────────────────────────
        Expanded(
          child: _PreviewCanvas(state: state),
        ),

        // ── Source info bar ───────────────────────────────────────────────
        if (state.hasAsset)
          _SourceInfoBar(asset: state.asset!),

        // ── Scrubber + timecode ───────────────────────────────────────────
        if (state.hasAsset)
          _Scrubber(
            state: state,
            onScrub: (micros) => controller.renderFrame(micros),
          ),

        // ── Transport bar ─────────────────────────────────────────────────
        _TransportBar(
          state: state,
          controller: controller,
          projectId: projectId,
          timelinePlayheadMicros: timelinePlayheadMicros,
          onInserted: onInserted,
        ),
      ],
    );
  }
}

// ── Preview canvas ──────────────────────────────────────────────────────────

class _PreviewCanvas extends StatelessWidget {
  final SourcePreviewState state;

  const _PreviewCanvas({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: state.hasAsset
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Checkerboard background
                if (!state.asset!.isAudioOnly)
                  CustomPaint(painter: _CheckerPainter()),

                // Placeholder / texture
                Center(
                  child: state.asset!.isAudioOnly
                      ? SourceAudioPlaceholder(asset: state.asset!)
                      : (state.isPreviewReady
                          ? _NativeTexturePlaceholder(
                              textureId: state.textureId,
                              width: state.asset!.width.toDouble(),
                              height: state.asset!.height.toDouble(),
                            )
                          : _EmptyPreviewHint(asset: state.asset!)),
                ),

                // In/Out point indicator bar (top)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _InOutBar(state: state),
                ),

                // Timecode HUD (top-right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _Timecode(micros: state.playheadMicros),
                ),
              ],
            )
          : _NoAssetPlaceholder(),
    );
  }
}

class _NativeTexturePlaceholder extends StatelessWidget {
  final int? textureId;
  final double width;
  final double height;
  const _NativeTexturePlaceholder({
    this.textureId,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (textureId != null && textureId! >= 0) {
      return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: width > 0 ? width : 1280,
          height: height > 0 ? height : 720,
          child: Texture(textureId: textureId!),
        ),
      );
    }
    return const CircularProgressIndicator(color: AppTheme.accentPrimary);
  }
}

class _EmptyPreviewHint extends StatelessWidget {
  final SourcePreviewAsset asset;
  const _EmptyPreviewHint({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          asset.isAudioOnly ? Icons.audiotrack : Icons.play_circle_outline,
          color: Colors.white24,
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          asset.name,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _NoAssetPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_filter_outlined, color: Colors.white12, size: 48),
            SizedBox(height: 12),
            Text(
              'Tap a media bin clip\nto preview it here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── In/Out bar ─────────────────────────────────────────────────────────────

class _InOutBar extends StatelessWidget {
  final SourcePreviewState state;
  const _InOutBar({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.hasAsset || state.asset!.durationMicros == 0) {
      return const SizedBox.shrink();
    }

    final total = state.asset!.durationMicros.toDouble();
    final inFrac  = state.inPointMicros  / total;
    final outFrac = state.outPointMicros / total;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          height: 4,
          child: Stack(
            children: [
              // Full track
              Container(color: Colors.white10),
              // Selected range
              Positioned(
                left:  w * inFrac,
                width: w * (outFrac - inFrac),
                top:   0,
                bottom: 0,
                child: Container(color: AppTheme.accentPrimary.withOpacity(0.7)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Timecode HUD ───────────────────────────────────────────────────────────

class _Timecode extends StatelessWidget {
  final int micros;
  const _Timecode({required this.micros});

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      borderRadius: 8.0,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        TimeUtils.formatMicros(micros),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          color: AppTheme.accentPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Source info bar ────────────────────────────────────────────────────────

class _SourceInfoBar extends StatelessWidget {
  final SourcePreviewAsset asset;
  const _SourceInfoBar({required this.asset});

  @override
  Widget build(BuildContext context) {
    final dur = TimeUtils.formatMicros(asset.durationMicros);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: AppTheme.surface.withOpacity(0.9),
      child: Row(
        children: [
          Icon(
            asset.isAudioOnly
                ? Icons.audiotrack
                : (asset.assetType.toLowerCase() == 'image'
                    ? Icons.image_outlined
                    : Icons.videocam_outlined),
            size: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              asset.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            dur,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scrubber ───────────────────────────────────────────────────────────────

class _Scrubber extends ConsumerWidget {
  final SourcePreviewState state;
  final void Function(int micros) onScrub;

  const _Scrubber({required this.state, required this.onScrub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.asset == null || state.asset!.durationMicros <= 0) {
      return const SizedBox.shrink();
    }

    final total = state.asset!.durationMicros.toDouble();
    final progress = (state.playheadMicros / total).clamp(0.0, 1.0);
    final inFrac = (state.inPointMicros / total).clamp(0.0, 1.0);
    final outFrac = (state.outPointMicros / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // If asset has audio, we could show a mini waveform here.
          // For now we'll just show the scrubber with In/Out markers.
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Base track
                  Container(
                    height: 4,
                    width: w,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // In/Out Highlight
                  Positioned(
                    left: w * inFrac,
                    width: w * (outFrac - inFrac),
                    child: Container(
                      height: 4,
                      color: AppTheme.accentPrimary.withOpacity(0.4),
                    ),
                  ),
                  // In Marker
                  Positioned(
                    left: w * inFrac - 4,
                    child: Container(
                      width: 8,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentPrimary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(2),
                          bottomLeft: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Out Marker
                  Positioned(
                    left: w * outFrac - 4,
                    child: Container(
                      width: 8,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentPrimary,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // The actual interactive slider over top
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 24, // Make track invisible but clickable
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: Colors.white,
                      overlayColor: AppTheme.accentPrimary.withOpacity(0.15),
                    ),
                    child: Slider(
                      min: 0,
                      max: 1,
                      value: progress,
                      onChanged: (v) => onScrub((v * total).round()),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Transport bar ──────────────────────────────────────────────────────────

class _TransportBar extends ConsumerWidget {
  final SourcePreviewState state;
  final SourcePreviewController controller;
  final String projectId;
  final int timelinePlayheadMicros;
  final void Function(String clipId)? onInserted;

  const _TransportBar({
    required this.state,
    required this.controller,
    required this.projectId,
    required this.timelinePlayheadMicros,
    this.onInserted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAsset = state.hasAsset;
    final hasRange = state.hasValidRange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
      ),
      child: Row(
        children: [
          // ── In/Out controls ─────────────────────────────────────────────
          _iconBtn(
            Icons.first_page_rounded,
            'Go to In',
            hasAsset ? () => controller.renderFrame(state.inPointMicros) : null,
          ),
          _iconBtn(
            Icons.chevron_left_rounded,
            'Step Back',
            hasAsset ? () => controller.renderFrame(state.playheadMicros - 100000) : null,
          ),
          
          const Spacer(),

          // ── Play / Pause ────────────────────────────────────────────────
          PremiumBounceButton(
            onTap: hasAsset
                ? (state.isPlaying ? controller.pause : controller.play)
                : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasAsset
                    ? AppTheme.accentPrimary
                    : AppTheme.accentPrimary.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: hasAsset ? [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: Icon(
                state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),

          const Spacer(),

          _iconBtn(
            Icons.chevron_right_rounded,
            'Step Forward',
            hasAsset ? () => controller.renderFrame(state.playheadMicros + 100000) : null,
          ),
          _iconBtn(
            Icons.last_page_rounded,
            'Go to Out',
            hasAsset ? () => controller.renderFrame(state.outPointMicros) : null,
          ),
          
          const Spacer(),

          // ── Mark In/Out ─────────────────────────────────────────────
          _iconBtn(
            Icons.format_indent_increase_rounded,
            'Mark In',
            hasAsset ? controller.markIn : null,
            color: const Color(0xFF00B8D4),
          ),
          _iconBtn(
            Icons.format_indent_decrease_rounded,
            'Mark Out',
            hasAsset ? controller.markOut : null,
            color: const Color(0xFF00B8D4),
          ),
          _iconBtn(
            Icons.clear_rounded,
            'Clear In/Out',
            hasAsset ? controller.clearInOut : null,
            color: AppTheme.textSecondary,
          ),

          const SizedBox(width: 8),

          // ── In/Out duration label ───────────────────────────────────────
          if (hasRange)
            Text(
              TimeUtils.formatMicros(state.selectedDurationMicros),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),

          const SizedBox(width: 4),

          // ── Send to Timeline ────────────────────────────────────────────
          Flexible(
            child: _SendButton(
              enabled: hasRange,
              onTap: hasRange
                  ? () async {
                      try {
                        final clipId = await controller.insertToTimeline(
                          timelineStartMicros: timelinePlayheadMicros,
                        );
                        onInserted?.call(clipId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Clip added to timeline'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF1A3A2A),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not insert clip: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    String tooltip,
    VoidCallback? onTap, {
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: PremiumBounceButton(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: onTap != null
                ? (color ?? AppTheme.textPrimary)
                : AppTheme.textSecondary.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _SendButton({required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: PremiumBounceButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00B0CC)],
                  )
                : null,
            color: enabled ? null : AppTheme.borderSubtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward, size: 14, color: Colors.black),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Send to Timeline',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Checkerboard painter ────────────────────────────────────────────────────

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.02);
    const sq = 16.0;
    for (double y = 0; y < size.height; y += sq) {
      for (double x = 0; x < size.width; x += sq) {
        if ((x / sq).floor() % 2 == (y / sq).floor() % 2) {
          canvas.drawRect(Rect.fromLTWH(x, y, sq, sq), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

