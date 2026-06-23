import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';

/// A premium, interactive horizontal divider that allows users to drag-to-resize
/// layout panels vertically with custom hover transitions and haptic feedback.
class ResizablePanelDivider extends ConsumerStatefulWidget {
  final double currentHeight;
  final double minHeight;
  final double maxHeight;
  final ValueChanged<double> onHeightChanged;
  final VoidCallback onDoubleTap;

  const ResizablePanelDivider({
    super.key,
    required this.currentHeight,
    required this.minHeight,
    required this.maxHeight,
    required this.onHeightChanged,
    required this.onDoubleTap,
  });

  @override
  ConsumerState<ResizablePanelDivider> createState() => _ResizablePanelDividerState();
}

class _ResizablePanelDividerState extends ConsumerState<ResizablePanelDivider> {
  bool _isHovered = false;
  bool _isDragging = false;
  late double _lastFeedbackHeight;

  @override
  Widget build(BuildContext context) {
    final activeColor = (_isHovered || _isDragging)
        ? AppTheme.accentPrimary
        : AppTheme.borderSubtle;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (details) {
          setState(() {
            _isDragging = true;
            _lastFeedbackHeight = widget.currentHeight;
          });
          ref.read(hapticServiceProvider).light();
        },
        onVerticalDragUpdate: (details) {
          final dy = details.primaryDelta ?? 0.0;
          final newHeight = widget.currentHeight - dy;
          final clampedHeight = newHeight.clamp(widget.minHeight, widget.maxHeight);

          if (clampedHeight != widget.currentHeight) {
            widget.onHeightChanged(clampedHeight);
            if ((clampedHeight - _lastFeedbackHeight).abs() >= 10.0) {
              ref.read(hapticServiceProvider).selection();
              _lastFeedbackHeight = clampedHeight;
            }
          } else {
            // Trigger warning vibration once when hitting boundaries
            final hitMin = newHeight <= widget.minHeight && widget.currentHeight > widget.minHeight;
            final hitMax = newHeight >= widget.maxHeight && widget.currentHeight < widget.maxHeight;
            if (hitMin || hitMax) {
              ref.read(hapticServiceProvider).warning();
            }
          }
        },
        onVerticalDragEnd: (_) {
          setState(() => _isDragging = false);
          ref.read(hapticServiceProvider).light();
        },
        onDoubleTap: () {
          widget.onDoubleTap();
          ref.read(hapticServiceProvider).success();
        },
        child: Container(
          height: 12.0,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full-width subtle line
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: _isDragging ? 2.0 : 1.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: activeColor,
                  boxShadow: _isDragging
                      ? [
                          BoxShadow(
                            color: AppTheme.accentPrimary.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
              // Center handle pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: (_isHovered || _isDragging) ? 48.0 : 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
