import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/export/export_preset_builder_models.dart';
import 'package:nle_editor/presentation/providers/export_batch_provider.dart';
import 'package:nle_editor/presentation/providers/export_preset_builder_providers.dart';

class ExportBatchPanel extends ConsumerWidget {
  final String projectId;

  const ExportBatchPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(projectExportPresetsProvider(projectId));

    return Container(
      color: AppTheme.editorBackground,
      child: presetsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPrimary),
        ),
        error: (error, _) => Center(
          child: Text(
            'Batch export unavailable: $error',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
        data: (presets) {
          final builtIn = presets.where((preset) => preset.isBuiltIn).toList();
          final custom = presets.where((preset) => !preset.isBuiltIn).toList();
          final favorites = custom.where((preset) => preset.isFavorite).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _Header(),
              const SizedBox(height: 14),
              _BatchActionCard(
                title: 'Export platform pack',
                subtitle: 'Queue all built-in platform presets in one pass.',
                presets: builtIn,
                onStart: () => _startBatch(context, ref, builtIn),
              ),
              const SizedBox(height: 10),
              _BatchActionCard(
                title: 'Export favorites',
                subtitle: 'Queue custom presets marked with a star.',
                presets: favorites,
                onStart: favorites.isEmpty
                    ? null
                    : () => _startBatch(context, ref, favorites),
              ),
              const SizedBox(height: 10),
              _BatchActionCard(
                title: 'Export all custom presets',
                subtitle: 'Queue every custom export preset.',
                presets: custom,
                onStart: custom.isEmpty ? null : () => _startBatch(context, ref, custom),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startBatch(
    BuildContext context,
    WidgetRef ref,
    List<NleExportPresetSpec> presets,
  ) async {
    if (presets.isEmpty) return;
    try {
      final jobIds = await ref.read(exportBatchServiceProvider).startBatch(
            projectId: projectId,
            presets: presets,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Queued ${jobIds.length} export job(s).')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch export failed: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.queue_play_next_rounded, color: AppTheme.accentPrimary),
            SizedBox(width: 10),
            Text(
              'Batch Export',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Queue multiple export presets for the same project.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _BatchActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<NleExportPresetSpec> presets;
  final VoidCallback? onStart;

  const _BatchActionCard({
    required this.title,
    required this.subtitle,
    required this.presets,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '${presets.length} preset(s)',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Queue Batch'),
            ),
          ),
        ],
      ),
    );
  }
}
