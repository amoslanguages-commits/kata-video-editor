import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';

class PremiumButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final bool secondary;

  const PremiumButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expanded = false,
    this.secondary = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;

    final child = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: PremiumMotion.fast,
      curve: PremiumMotion.curve,
      child: Container(
        width: widget.expanded ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: widget.secondary || !enabled
              ? null
              : PremiumGradients.cyanGlow,
          color: widget.secondary || !enabled
              ? AppTheme.surfaceElevated
              : null,
          borderRadius: BorderRadius.circular(PremiumRadius.pill),
          border: Border.all(
            color: widget.secondary
                ? AppTheme.borderSubtle
                : AppTheme.accentPrimary.withOpacity(0.35),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PremiumSpacing.xl,
          vertical: PremiumSpacing.md,
        ),
        child: Row(
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.textPrimary,
                ),
              )
            else if (widget.icon != null)
              Icon(
                widget.icon,
                color: AppTheme.textPrimary,
                size: 19,
              ),
            if (widget.icon != null || widget.loading)
              const SizedBox(width: PremiumSpacing.sm),
            Text(
              widget.label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _pressed = true);
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: child,
    );
  }
}
