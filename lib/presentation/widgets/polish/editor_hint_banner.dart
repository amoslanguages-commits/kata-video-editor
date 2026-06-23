import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/polish/editor_hint.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';

class EditorHintBanner extends ConsumerWidget {
  final EditorHint hint;
  final VoidCallback? onAction;

  const EditorHintBanner({
    super.key,
    required this.hint,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(editorHintDismissedProvider(hint.id));

    return dismissed.when(
      data: (isDismissed) {
        if (isDismissed) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: PremiumMotion.normal,
          curve: PremiumMotion.curve,
          margin: const EdgeInsets.only(bottom: PremiumSpacing.md),
          padding: const EdgeInsets.all(PremiumSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.accentPrimary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(PremiumRadius.md),
            border: Border.all(
              color: AppTheme.accentPrimary.withOpacity(0.28),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppTheme.accentPrimary,
              ),
              const SizedBox(width: PremiumSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hint.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hint.message,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(hint.actionLabel),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  await ref.read(editorHintServiceProvider).dismiss(hint.id);
                  ref.invalidate(editorHintDismissedProvider(hint.id));
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
