import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_bounce_button.dart';

class PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double? iconSize;

  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
      color: color ?? AppTheme.textSecondary,
      iconSize: iconSize,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );

    if (onPressed == null) {
      return button;
    }

    return PremiumBounceButton(
      onTap: onPressed,
      child: IgnorePointer(
        child: button,
      ),
    );
  }
}
