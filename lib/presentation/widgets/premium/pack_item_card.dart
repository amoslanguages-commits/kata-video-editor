import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/premium/creative_pack.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_badges.dart';

class PackItemCard extends StatelessWidget {
  final CreativePackItem item;
  final bool locked;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;

  const PackItemCard({
    super.key,
    required this.item,
    required this.locked,
    this.onTap,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: locked ? AppTheme.border.withOpacity(0.4) : AppTheme.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type.split('_').first.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.proOnly && !locked)
                      const ProBadge(compact: true),
                  ],
                ),
              ],
            ),
          ),
          if (locked)
            PremiumLockOverlay(
              onTap: onLockedTap,
            )
          else if (onTap != null)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
