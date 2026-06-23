import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/utils/time_utils.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/domain/text/text_style_model.dart';
import 'package:nle_editor/native_bridge/native_preview_texture_controller.dart';
import 'package:nle_editor/presentation/widgets/preview/native_preview_texture.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_glass_card.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_bounce_button.dart';



class PreviewArea extends ConsumerStatefulWidget {
  const PreviewArea({super.key});

  @override
  ConsumerState<PreviewArea> createState() => _PreviewAreaState();
}

class _PreviewAreaState extends ConsumerState<PreviewArea> {
  NativePreviewTextureController? _previewController;
  String? _initializedProjectId;
  bool _showLeftSeekIndicator = false;
  bool _showRightSeekIndicator = false;

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  void _syncPreviewTexture(String projectId, double width, double height, int playheadMicros) {
    if (_previewController == null || _initializedProjectId != projectId) {
      _previewController?.dispose();
      _previewController = NativePreviewTextureController(
        projectId: projectId,
        nativeBridge: ref.read(nativeBridgeProvider),
      );
      _initializedProjectId = projectId;
      _previewController!.initialize(width.toInt(), height.toInt()).then((_) {
        if (mounted) {
          setState(() {});
        }
        _previewController!.renderPlaceholder(
          label: "Native Preview Surface",
          playheadMicros: playheadMicros,
        );
      });
    } else {
      _previewController!.resize(width.toInt(), height.toInt()).ignore();
      _previewController!.renderPlaceholder(
        label: "Native Preview Surface",
        playheadMicros: playheadMicros,
      ).ignore();
    }
  }

  void _triggerSeek(String projectId, int amountMicros) async {
    final editorState = ref.read(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);
    final timelineAsync = ref.read(realProjectTimelineProvider(projectId));
    final durationMicros = timelineAsync.value?.durationMicros ?? (60 * 1000000);

    final target = (editorState.currentTimeMicros + amountMicros).clamp(0, durationMicros);
    editorNotifier.seekTo(target);
    if (_previewController != null) {
      await _previewController!.renderPlaceholder(
        label: "Native Preview Surface",
        playheadMicros: target,
      );
    }
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
    final projectAsync = ref.watch(selectedProjectProvider);
    final previewItem = ref.watch(timelinePreviewProvider);
    final editorState = ref.watch(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);
    final clip = ref.watch(selectedClipProvider).value;

    return projectAsync.when(
      data: (project) {
        if (project == null) return const SizedBox.shrink();

        // Determine target aspect ratio
        double aspectRatio = 16 / 9;
        if (project.aspectRatio == '9:16') aspectRatio = 9 / 16;
        if (project.aspectRatio == '1:1') aspectRatio = 1.0;
        if (project.aspectRatio == '4:5') aspectRatio = 4 / 5;
        if (project.aspectRatio == '21:9') aspectRatio = 21 / 9;

        return Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Preview canvas box with correct aspect ratio
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  color: AppTheme.surfaceDark,
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _syncPreviewTexture(
                            project.id,
                            w,
                            h,
                            editorState.currentTimeMicros,
                          );
                        });

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background grid/pattern
                            CustomPaint(
                              painter: CheckerboardPainter(),
                            ),

                            // Video/Texture display
                            if (_previewController != null)
                              Center(
                                child: NativePreviewTexture(
                                  controller: _previewController!,
                                  fallbackLabel: project.name,
                                ),
                              )
                            else
                              const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.accentPrimary,
                                ),
                              ),

                            // Double-tap-to-seek zones
                            Positioned.fill(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onDoubleTap: () => _triggerSeek(project.id, -5000000),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onDoubleTap: () => _triggerSeek(project.id, 5000000),
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


                            // Safe Area guides
                            if (editorState.showSafeArea)
                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: w * 0.1,
                                  vertical: h * 0.1,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 1,
                                  ),
                                ),
                              ),

                            // Text overlays layer
                            for (final textClip in previewItem.activeTextClips) (() {
                              final style = NleTextStyle.fromJsonString(textClip.textStyle);
                              final textColor = _parseHex(style.color);
                              final strokeColor = _parseHex(style.strokeColor);
                              final shadowColor = _parseHex(style.shadowColor);
                              final bgColor = _parseHex(style.backgroundColor, style.backgroundOpacity);

                              final shadows = style.shadowEnabled
                                  ? [
                                      Shadow(
                                        color: shadowColor,
                                        offset: Offset(style.shadowOffsetX, style.shadowOffsetY),
                                        blurRadius: style.shadowBlur,
                                      )
                                    ]
                                  : <Shadow>[];

                              final textFontFamily = style.fontFamily == 'system' ? null : style.fontFamily;

                              final textWidget = style.strokeWidth > 0
                                  ? Stack(
                                      children: [
                                        // Stroke back
                                        Text(
                                          textClip.textContent ?? '',
                                          textAlign: _getTextAlign(style.alignment),
                                          style: TextStyle(
                                            fontFamily: textFontFamily,
                                            fontSize: style.fontSize,
                                            fontWeight: _getFontWeight(style.fontWeight),
                                            letterSpacing: style.letterSpacing,
                                            height: style.lineSpacing,
                                            foreground: Paint()
                                              ..style = PaintingStyle.stroke
                                              ..strokeWidth = style.strokeWidth
                                              ..color = strokeColor,
                                            shadows: shadows,
                                          ),
                                        ),
                                        // Fill front
                                        Text(
                                          textClip.textContent ?? '',
                                          textAlign: _getTextAlign(style.alignment),
                                          style: TextStyle(
                                            fontFamily: textFontFamily,
                                            fontSize: style.fontSize,
                                            fontWeight: _getFontWeight(style.fontWeight),
                                            letterSpacing: style.letterSpacing,
                                            height: style.lineSpacing,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      textClip.textContent ?? '',
                                      textAlign: _getTextAlign(style.alignment),
                                      style: TextStyle(
                                        fontFamily: textFontFamily,
                                        fontSize: style.fontSize,
                                        fontWeight: _getFontWeight(style.fontWeight),
                                        letterSpacing: style.letterSpacing,
                                        height: style.lineSpacing,
                                        color: textColor,
                                        shadows: shadows,
                                      ),
                                    );

                              return Positioned(
                                left: (0.5 + textClip.positionX).clamp(0, 1) * w,
                                top: (0.5 + textClip.positionY).clamp(0, 1) * h,
                                child: FractionalTranslation(
                                  translation: const Offset(-0.5, -0.5),
                                  child: Transform.rotate(
                                    angle: textClip.rotation * math.pi / 180,
                                    child: Transform.scale(
                                      scale: textClip.scale,
                                      child: Opacity(
                                        opacity: textClip.opacity.clamp(0.0, 1.0),
                                        child: Container(
                                          padding: EdgeInsets.all(style.backgroundPadding),
                                          decoration: style.backgroundEnabled
                                              ? BoxDecoration(
                                                  color: bgColor,
                                                  borderRadius: BorderRadius.circular(style.backgroundRadius),
                                                )
                                              : null,
                                          child: textWidget,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } ()),

                            // Bounding Box Overlay for Selected Clip
                            if (editorState.selectedClipId != null &&
                                clip != null &&
                                (clip.clipType == 'video' ||
                                    clip.clipType == 'image' ||
                                    clip.clipType == 'text'))
                              _BoundingBoxOverlay(
                                clip: clip,
                                projectId: project.id,
                                canvasWidth: w,
                                canvasHeight: h,
                                boxWidth: clip.clipType == 'text' ? w * 0.7 : w,
                                boxHeight: clip.clipType == 'text' ? 50 : h,
                                ref: ref,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // HUD Overlay Controls (Replay, Play, Forward)
              Positioned(
                bottom: 16,
                child: PremiumGlassCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PremiumBounceButton(
                        onTap: () => editorNotifier.seekBackward(5000000),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.replay_5, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PremiumBounceButton(
                        onTap: editorNotifier.togglePlay,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            editorState.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PremiumBounceButton(
                        onTap: () => editorNotifier.seekForward(5000000),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.forward_5, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Timecode HUD (top right)
              Positioned(
                top: 16,
                right: 16,
                child: PremiumGlassCard(
                  borderRadius: 8,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    TimeUtils.formatMicros(editorState.currentTimeMicros),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentPrimary),
      ),
      error: (e, _) => Center(
        child: Text('Error loading project preview: $e', style: const TextStyle(color: AppTheme.error)),
      ),
    );
  }

  Color _parseHex(String hex, [double opacity = 1.0]) {
    var hexClean = hex.replaceAll('#', '');
    if (hexClean.length == 6) {
      hexClean = 'FF$hexClean';
    }
    final val = int.tryParse(hexClean, radix: 16);
    if (val != null) {
      return Color(val).withValues(alpha: opacity);
    }
    return Colors.white.withValues(alpha: opacity);
  }

  FontWeight _getFontWeight(int weight) {
    if (weight >= 900) return FontWeight.w900;
    if (weight >= 800) return FontWeight.w800;
    if (weight >= 700) return FontWeight.w700;
    if (weight >= 600) return FontWeight.w600;
    if (weight >= 500) return FontWeight.w500;
    if (weight >= 400) return FontWeight.w400;
    if (weight >= 300) return FontWeight.w300;
    return FontWeight.normal;
  }

  TextAlign _getTextAlign(String alignment) {
    switch (alignment) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }
}

class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.02);
    const sizeSquare = 16.0;

    for (double y = 0; y < size.height; y += sizeSquare) {
      for (double x = 0; x < size.width; x += sizeSquare) {
        if ((x / sizeSquare).floor() % 2 == (y / sizeSquare).floor() % 2) {
          canvas.drawRect(Rect.fromLTWH(x, y, sizeSquare, sizeSquare), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BoundingBoxOverlay extends StatefulWidget {
  final Clip clip;
  final String projectId;
  final double canvasWidth;
  final double canvasHeight;
  final double boxWidth;
  final double boxHeight;
  final WidgetRef ref;

  const _BoundingBoxOverlay({
    required this.clip,
    required this.projectId,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.boxWidth,
    required this.boxHeight,
    required this.ref,
  });

  @override
  State<_BoundingBoxOverlay> createState() => _BoundingBoxOverlayState();
}

class _BoundingBoxOverlayState extends State<_BoundingBoxOverlay> {
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final w = widget.canvasWidth;
    final h = widget.canvasHeight;
    final scale = clip.scale.isFinite && clip.scale > 0 ? clip.scale : 1.0;
    final rotation = clip.rotation.isFinite ? clip.rotation : 0.0;
    final positionX = clip.positionX.isFinite ? clip.positionX : 0.0;
    final positionY = clip.positionY.isFinite ? clip.positionY : 0.0;

    if (!w.isFinite ||
        !h.isFinite ||
        w <= 0 ||
        h <= 0 ||
        !widget.boxWidth.isFinite ||
        !widget.boxHeight.isFinite ||
        widget.boxWidth <= 0 ||
        widget.boxHeight <= 0) {
      return const SizedBox.shrink();
    }

    final centerX = (0.5 + positionX) * w;
    final centerY = (0.5 + positionY) * h;

    return Positioned(
      left: centerX,
      top: centerY,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.rotate(
          angle: rotation * math.pi / 180,
          child: Transform.scale(
            scale: scale,
            child: GestureDetector(
              onScaleStart: (details) {
                _baseScale = scale;
                _baseRotation = rotation;
                HapticFeedback.lightImpact();
              },
              onScaleUpdate: (details) {
                final newScale = (_baseScale * details.scale).clamp(0.1, 5.0);
                final newRotation = _baseRotation + (details.rotation * 180 / math.pi);

                widget.ref.read(timelineCommandServiceProvider).updateClipTransform(
                  projectId: widget.projectId,
                  clipId: clip.id,
                  scale: newScale,
                  rotation: newRotation,
                );
                HapticFeedback.selectionClick();
              },
              onPanUpdate: (details) {
                final dx = details.delta.dx;
                final dy = details.delta.dy;

                widget.ref.read(timelineCommandServiceProvider).updateClipTransform(
                  projectId: widget.projectId,
                  clipId: clip.id,
                  positionX: clip.positionX + dx / w,
                  positionY: clip.positionY + dy / h,
                );
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: widget.boxWidth,
                height: widget.boxHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyanAccent, width: 1.5),
                ),
                child: Stack(
                  clipBehavior: ui.Clip.none,
                  children: [
                    _buildHandle(0, 0),
                    _buildHandle(widget.boxWidth, 0),
                    _buildHandle(0, widget.boxHeight),
                    _buildHandle(widget.boxWidth, widget.boxHeight),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(double x, double y) {
    return Positioned(
      left: x - 6,
      top: y - 6,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.cyanAccent, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 2),
          ],
        ),
      ),
    );
  }
}
