import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';

class ProBadge extends StatelessWidget {
  final bool compact;

  const ProBadge({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD36A),
            Color(0xFFFF8A00),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: Colors.black,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class PremiumLockOverlay extends StatelessWidget {
  final VoidCallback? onTap;

  const PremiumLockOverlay({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.46),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                SizedBox(height: 6),
                ProBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
