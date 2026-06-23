import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/services/timeline_command_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/domain/services/silence_removal_service.dart';
import 'dart:math';

class PieMenuOverlay extends ConsumerStatefulWidget {
  final Offset position;
  final String projectId;
  final String clipId;
  final VoidCallback onClose;

  const PieMenuOverlay({
    super.key,
    required this.position,
    required this.projectId,
    required this.clipId,
    required this.onClose,
  });

  @override
  ConsumerState<PieMenuOverlay> createState() => _PieMenuOverlayState();
}

class _PieMenuOverlayState extends ConsumerState<PieMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _close() {
    _animController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background dismiss tap
        GestureDetector(
          onTap: _close,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        
        // The Pie Menu
        Positioned(
          left: widget.position.dx - 100, // Center on touch
          top: widget.position.dy - 100,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildPieButton(
                    angle: -pi / 2, // Top
                    icon: Icons.content_cut,
                    label: 'Split',
                    onTap: () async {
                      final state = ref.read(editorStateProvider);
                      await ref.read(timelineCommandServiceProvider).splitClip(
                        projectId: widget.projectId,
                        clipId: widget.clipId,
                        splitTimelineMicros: state.currentTimeMicros,
                      );
                      _close();
                    },
                  ),
                  _buildPieButton(
                    angle: 0, // Right
                    icon: Icons.content_copy,
                    label: 'Duplicate',
                    onTap: () {
                      // Call duplicate (to be implemented)
                      _close();
                    },
                  ),
                  _buildPieButton(
                    angle: pi / 2, // Bottom
                    icon: Icons.auto_awesome,
                    label: 'Auto Cut',
                    color: AppTheme.accentPrimary,
                    onTap: () async {
                      await ref.read(silenceRemovalServiceProvider).removeSilenceFromClip(
                        widget.projectId,
                        widget.clipId,
                      );
                      _close();
                    },
                  ),
                  _buildPieButton(
                    angle: pi, // Left
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.redAccent,
                    onTap: () async {
                      final state = ref.read(editorStateProvider);
                      await ref.read(timelineCommandServiceProvider).deleteClip(
                        projectId: widget.projectId,
                        clipId: widget.clipId,
                        ripple: state.magneticTimelineEnabled,
                      );
                      _close();
                    },
                  ),
                  // Center Dismiss
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceDark,
                        boxShadow: [
                          BoxShadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.close, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieButton({
    required double angle,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.textPrimary,
  }) {
    final radius = 75.0;
    final x = cos(angle) * radius;
    final y = sin(angle) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceMedium,
            border: Border.all(color: AppTheme.borderSubtle),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
