import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/cache/cache_control_panel.dart';
import 'package:nle_editor/presentation/widgets/device/device_capability_card.dart';
import 'package:nle_editor/presentation/widgets/export/pro_export_panel.dart';
import 'package:nle_editor/presentation/widgets/proxy/proxy_workflow_panel.dart';

class ProToolsScreen extends ConsumerWidget {
  const ProToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProjectId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Pro Tools'),
        backgroundColor: AppTheme.editorBackground,
        actions: [
          IconButton(
            tooltip: 'Refresh device profile',
            onPressed: () => ref.invalidate(deviceCapabilityProfileProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const DeviceCapabilityCard(),
          const SizedBox(height: 16),
          const ProExportPanel(),
          const SizedBox(height: 16),
          const ProxyWorkflowPanel(),
          if (selectedProjectId != null) ...[
            const SizedBox(height: 16),
            CacheControlPanel(projectId: selectedProjectId),
          ] else ...[
            const SizedBox(height: 16),
            const _NoProjectCacheCard(),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NoProjectCacheCard extends StatelessWidget {
  const _NoProjectCacheCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache Control',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Open a project to inspect proxy, preview, and temporary render files.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
