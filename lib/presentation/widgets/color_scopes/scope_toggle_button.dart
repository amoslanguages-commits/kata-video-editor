import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/color_scope_providers.dart';

class ScopeToggleButton extends ConsumerWidget {
  const ScopeToggleButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(colorScopeControllerProvider);
    final controller = ref.read(colorScopeControllerProvider.notifier);

    return IconButton(
      tooltip: state.settings.enabled ? 'Hide scopes' : 'Show scopes',
      onPressed: () {
        controller.setEnabled(!state.settings.enabled);
      },
      icon: Icon(
        Icons.monitor_heart_rounded,
        color: state.settings.enabled ? AppTheme.accentPrimary : AppTheme.textMuted,
      ),
    );
  }
}
