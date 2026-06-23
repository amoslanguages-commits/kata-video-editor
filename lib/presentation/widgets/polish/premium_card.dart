import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final bool glow;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PremiumSpacing.lg),
    this.onTap,
    this.color,
    this.gradient,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(PremiumRadius.lg);

    return AnimatedContainer(
      duration: PremiumMotion.normal,
      curve: PremiumMotion.curve,
      decoration: BoxDecoration(
        color: gradient == null ? color ?? AppTheme.surface : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: glow ? PremiumShadows.glow(AppTheme.accentPrimary) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          borderRadius: borderRadius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
