import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/utils/time_utils.dart';
import 'package:nle_editor/domain/transitions/transition_presets.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class ProjectTransitionsList extends ConsumerWidget {
  final String projectId;

  const ProjectTransitionsList({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transitionsAsync = ref.watch(projectTransitionsProvider(projectId));

    return transitionsAsync.when(
      data: (transitions) {
        if (transitions.isEmpty) {
          return const Center(
            child: Text(
              'No transitions yet.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: transitions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final transition = transitions[index];
            final preset = TransitionPresets.byId(transition.transitionType);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    color: AppTheme.accentPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${TimeUtils.formatMicros(transition.durationMicros)} • ${transition.easing}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      transition.isDisabled
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                    ),
                    onPressed: () async {
                      await ref.read(transitionCommandServiceProvider).disableTransition(
                            projectId: projectId,
                            transitionId: transition.id,
                            disabled: !transition.isDisabled,
                          );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppTheme.error,
                    onPressed: () async {
                      await ref.read(transitionCommandServiceProvider).removeTransition(
                            projectId: projectId,
                            transitionId: transition.id,
                          );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPrimary),
        );
      },
      error: (err, stack) {
        return Center(
          child: Text(
            'Transitions error: $err',
            style: const TextStyle(color: AppTheme.error),
          ),
        );
      },
    );
  }
}
