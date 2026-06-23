import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';

class InspectorSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const InspectorSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.accentPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PremiumSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
