import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/native_true_preview_providers.dart';
import 'package:nle_editor/presentation/controllers/native_true_preview_controller.dart';

class NativeTruePreviewView extends ConsumerStatefulWidget {
  final String projectId;

  const NativeTruePreviewView({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<NativeTruePreviewView> createState() =>
      _NativeTruePreviewViewState();
}

class _NativeTruePreviewViewState
    extends ConsumerState<NativeTruePreviewView> {
  bool _showLeftSeekIndicator = false;
  bool _showRightSeekIndicator = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(nativeTruePreviewControllerProvider(widget.projectId).notifier)
          .prepare();
    });
  }

  void _triggerSeek(int amountMicros) async {
    final editorState = ref.read(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);
    final timelineAsync = ref.read(realProjectTimelineProvider(widget.projectId));
    final durationMicros = timelineAsync.value?.durationMicros ?? (60 * 1000000);
    final controller = ref.read(nativeTruePreviewControllerProvider(widget.projectId).notifier);

    final target = (editorState.currentTimeMicros + amountMicros).clamp(0, durationMicros);
    editorNotifier.seekTo(target);
    await controller.renderFrame(target);
    HapticFeedback.mediumImpact();

    setState(() {
      if (amountMicros < 0) {
        _showLeftSeekIndicator = true;
      } else {
        _showRightSeekIndicator = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          if (amountMicros < 0) {
            _showLeftSeekIndicator = false;
          } else {
            _showRightSeekIndicator = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      nativeTruePreviewControllerProvider(widget.projectId),
    );
    final isScrubbing = ref.watch(editorStateProvider.select((s) => s.isScrubbing));

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (state.hasTexture)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: state.width.toDouble(),
                  height: state.height.toDouble(),
                  child: ImageFiltered(
                    imageFilter: isScrubbing 
                        ? ColorFilter.matrix([
                            1, 0, 0, 0, 0,
                            0, 1, 0, 0, 0,
                            0, 0, 1, 0, 0,
                            0, 0, 0, 0.8, 0, // Slight alpha fade to simulate draft mode
                          ])
                        : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                    child: Texture(
                      textureId: state.textureId!,
                    ),
                  ),
                ),
              ),
            )
          else
            const _PreviewPlaceholder(),

          // Double-tap-to-seek zones
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: () => _triggerSeek(-5000000),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: () => _triggerSeek(5000000),
                  ),
                ),
              ],
            ),
          ),

          // Left Seek Indicator Overlay
          Align(
            alignment: const Alignment(-0.5, 0.0),
            child: AnimatedOpacity(
              opacity: _showLeftSeekIndicator ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_rewind, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text(
                      '-5s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Seek Indicator Overlay
          Align(
            alignment: const Alignment(0.5, 0.0),
            child: AnimatedOpacity(
              opacity: _showRightSeekIndicator ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_forward, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text(
                      '+5s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 12,
            top: 12,
            child: Row(
              children: [
                _PreviewStatusBadge(state: state),
                if (isScrubbing) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PROXY 1/4',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (state.status == TruePreviewUiStatus.preparing)
            const CircularProgressIndicator(strokeWidth: 2),

          if (state.status == TruePreviewUiStatus.error)
            _PreviewErrorBox(
              message: state.errorMessage ?? 'Preview error',
            ),
        ],
      ),
    );
  }
}


class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.video_settings_rounded,
          color: AppTheme.textMuted,
          size: 42,
        ),
        SizedBox(height: 10),
        Text(
          'Preparing true preview...',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PreviewStatusBadge extends StatelessWidget {
  final TruePreviewUiState state;

  const _PreviewStatusBadge({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (state.status) {
      TruePreviewUiStatus.idle => 'Idle',
      TruePreviewUiStatus.preparing => 'Preparing',
      TruePreviewUiStatus.ready => 'Ready',
      TruePreviewUiStatus.playing => 'Playing',
      TruePreviewUiStatus.paused => 'Paused',
      TruePreviewUiStatus.error => 'Error',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        state.droppedFrames > 0
            ? '$label • ${state.droppedFrames} dropped'
            : label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PreviewErrorBox extends StatelessWidget {
  final String message;

  const _PreviewErrorBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(PremiumSpacing.lg),
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(PremiumRadius.md),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.45)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.error,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
