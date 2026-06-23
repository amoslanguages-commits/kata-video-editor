import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';

class ClippingWarningStrip extends StatelessWidget {
  final NleClippingWarnings warnings;

  const ClippingWarningStrip({
    super.key,
    required this.warnings,
  });

  @override
  Widget build(BuildContext context) {
    if (!warnings.hasAnyWarning) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.success.withOpacity(0.30)),
        ),
        child: const Text(
          'No clipping',
          style: TextStyle(
            color: AppTheme.success,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    final items = <String>[];

    if (warnings.blackClipping) {
      items.add('Black ${warnings.blackClipPercent.toStringAsFixed(1)}%');
    }

    if (warnings.whiteClipping) {
      items.add('White ${warnings.whiteClipPercent.toStringAsFixed(1)}%');
    }

    if (warnings.redChannelClipping) {
      items.add('Red ${warnings.redClipPercent.toStringAsFixed(1)}%');
    }

    if (warnings.greenChannelClipping) {
      items.add('Green ${warnings.greenClipPercent.toStringAsFixed(1)}%');
    }

    if (warnings.blueChannelClipping) {
      items.add('Blue ${warnings.blueClipPercent.toStringAsFixed(1)}%');
    }

    if (warnings.overSaturated) {
      items.add('Sat ${warnings.saturationWarningPercent.toStringAsFixed(1)}%');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.warning.withOpacity(0.35)),
      ),
      child: Text(
        items.join(' • '),
        style: const TextStyle(
          color: AppTheme.warning,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
