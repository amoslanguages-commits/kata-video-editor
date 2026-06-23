import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/overlays/overlay_template_factory.dart';

class OverlayTemplateSheet extends StatelessWidget {
  final ValueChanged<NleOverlayTemplateId> onSelected;

  const OverlayTemplateSheet({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final templates = NleOverlayTemplateId.values;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PremiumSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Shape / Sticker',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              itemCount: templates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.75,
              ),
              itemBuilder: (context, index) {
                final template = templates[index];

                return _OverlayTemplateCard(
                  template: template,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(template);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayTemplateCard extends StatelessWidget {
  final NleOverlayTemplateId template;
  final VoidCallback onTap;

  const _OverlayTemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1320),
      borderRadius: BorderRadius.circular(PremiumRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PremiumRadius.lg),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(_icon(template), color: AppTheme.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _label(template),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(NleOverlayTemplateId template) {
    switch (template) {
      case NleOverlayTemplateId.rectangle:
        return Icons.crop_square_rounded;
      case NleOverlayTemplateId.circle:
        return Icons.circle_outlined;
      case NleOverlayTemplateId.line:
        return Icons.horizontal_rule_rounded;
      case NleOverlayTemplateId.arrow:
        return Icons.arrow_forward_rounded;
      case NleOverlayTemplateId.calloutBox:
        return Icons.chat_bubble_outline_rounded;
      case NleOverlayTemplateId.sticker:
        return Icons.emoji_emotions_outlined;
    }
  }

  String _label(NleOverlayTemplateId template) {
    switch (template) {
      case NleOverlayTemplateId.rectangle:
        return 'Rectangle';
      case NleOverlayTemplateId.circle:
        return 'Circle';
      case NleOverlayTemplateId.line:
        return 'Line';
      case NleOverlayTemplateId.arrow:
        return 'Arrow';
      case NleOverlayTemplateId.calloutBox:
        return 'Callout';
      case NleOverlayTemplateId.sticker:
        return 'Sticker';
    }
  }
}
