import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/constants/app_constants.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/utils/time_utils.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/device/device_capability_profile.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/device/device_capability_card.dart';
import 'package:nle_editor/presentation/widgets/storage/project_storage_panel.dart';

class ProControlCenterScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProControlCenterScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProControlCenterScreen> createState() =>
      _ProControlCenterScreenState();
}

class _ProControlCenterScreenState extends ConsumerState<ProControlCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectFuture = ref.watch(projectRepositoryProvider).getProject(widget.projectId);

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Pro Controls'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file_rounded), text: 'Export'),
            Tab(icon: Icon(Icons.movie_filter_rounded), text: 'Proxy'),
            Tab(icon: Icon(Icons.storage_rounded), text: 'Cache'),
          ],
        ),
      ),
      body: FutureBuilder<Project?>(
        future: projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentPrimary),
            );
          }
          final project = snapshot.data;
          if (project == null) {
            return const Center(
              child: Text(
                'Project not found.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _ProExportPanel(project: project),
              _ProProxyPanel(projectId: project.id),
              ProjectStoragePanel(projectId: project.id),
            ],
          );
        },
      ),
    );
  }
}

class _ProExportPanel extends ConsumerWidget {
  final Project project;

  const _ProExportPanel({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(deviceCapabilityProfileProvider);
    final export = ref.watch(exportStateProvider);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const DeviceCapabilityCard(),
        const SizedBox(height: 16),
        profileAsync.when(
          data: (profile) => _AdaptiveExportSummary(
            project: project,
            profile: profile,
          ),
          loading: () => const _ProCard(
            icon: Icons.memory_rounded,
            title: 'Adaptive export profile',
            child: LinearProgressIndicator(color: AppTheme.accentPrimary),
          ),
          error: (error, _) => _ProCard(
            icon: Icons.warning_rounded,
            title: 'Adaptive profile unavailable',
            child: Text(
              '$error',
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ProCard(
          icon: Icons.tune_rounded,
          title: 'Smart export presets',
          child: Column(
            children: AppConstants.exportPresets.entries.map((entry) {
              return _ExportPresetTile(
                project: project,
                presetKey: entry.key,
                preset: entry.value,
                exporting: export.isExporting,
                profile: profileAsync.value,
              );
            }).toList(),
          ),
        ),
        if (export.isExporting) ...[
          const SizedBox(height: 16),
          _ProCard(
            icon: Icons.hourglass_bottom_rounded,
            title: 'Export running',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: export.progress / 100,
                  color: AppTheme.accentPrimary,
                  backgroundColor: AppTheme.surfaceOverlay,
                ),
                const SizedBox(height: 10),
                Text(
                  '${export.stage} • ${export.progress}%',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => ref.read(exportStateProvider.notifier).cancelExport(),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Cancel export'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AdaptiveExportSummary extends StatelessWidget {
  final Project project;
  final DeviceCapabilityProfile profile;

  const _AdaptiveExportSummary({
    required this.project,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final allow4k = profile.limits.allow4kExport;
    final maxHeight = profile.limits.maxExportHeight;
    final maxFps = profile.limits.maxExportFrameRate;
    final proxyRequired = profile.limits.proxyRequiredFor4k || profile.isLowEnd;

    return _ProCard(
      icon: Icons.auto_awesome_rounded,
      title: 'Adaptive export guardrails',
      child: Column(
        children: [
          _MetricGrid(
            items: [
              _MetricItem('Max export', '${maxHeight}p'),
              _MetricItem('Frame rate', '${maxFps}fps'),
              _MetricItem('4K', allow4k ? 'Allowed' : 'Limited'),
              _MetricItem('Proxy', proxyRequired ? 'Recommended' : 'Optional'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Project: ${project.aspectRatio} • ${project.targetWidth}×${project.targetHeight} • ${project.targetFrameRate}fps',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ExportPresetTile extends ConsumerWidget {
  final Project project;
  final String presetKey;
  final Map<String, dynamic> preset;
  final bool exporting;
  final DeviceCapabilityProfile? profile;

  const _ExportPresetTile({
    required this.project,
    required this.presetKey,
    required this.preset,
    required this.exporting,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestedHeight = preset['resolution'] as int? ?? 1080;
    final resolvedHeight = profile?.clampExportHeight(requestedHeight) ?? requestedHeight;
    final resolvedFrameRate = profile?.clampExportFrameRate(project.targetFrameRate) ?? project.targetFrameRate;
    final targetWidth = _estimateWidth(project.aspectRatio, resolvedHeight);
    final clamped = resolvedHeight != requestedHeight || resolvedFrameRate != project.targetFrameRate;
    final requiresProxies = profile?.limits.proxyRequiredFor4k == true && requestedHeight >= 2160;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: clamped ? AppTheme.warning.withValues(alpha: 0.7) : AppTheme.borderSubtle,
          width: 0.7,
        ),
      ),
      child: ListTile(
        leading: Icon(
          requestedHeight >= 2160 ? Icons.high_quality_rounded : Icons.movie_creation_rounded,
          color: clamped ? AppTheme.warning : AppTheme.accentPrimary,
        ),
        title: Text(
          preset['label']?.toString() ?? presetKey,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          clamped
              ? 'Adaptive: ${targetWidth}×$resolvedHeight • ${resolvedFrameRate}fps'
              : '${preset['description']} • ${targetWidth}×$resolvedHeight',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        trailing: ElevatedButton(
          onPressed: exporting
              ? null
              : () {
                  ref.read(exportStateProvider.notifier).startExport(
                    projectId: project.id,
                    settings: {
                      'preset': presetKey,
                      'resolution': resolvedHeight,
                      'bitrate': preset['bitrate'],
                      'adaptiveExport': true,
                      'requestedResolution': requestedHeight,
                      'resolvedFrameRate': resolvedFrameRate,
                      'preferProxy': requiresProxies,
                    },
                  );
                },
          child: const Text('Export'),
        ),
      ),
    );
  }
}

class _ProProxyPanel extends ConsumerWidget {
  final String projectId;

  const _ProProxyPanel({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proxyControllerProvider(projectId));
    final controller = ref.read(proxyControllerProvider(projectId).notifier);
    final videoAssets = state.assets.where((asset) => asset.isVideo).toList();
    final ready = videoAssets.where((asset) => asset.proxyStatus == NleProxyStatus.ready).length;
    final queued = state.jobs.where((job) => job.status == NleProxyGenerationStatus.queued).length;
    final running = state.jobs.where((job) => job.status == NleProxyGenerationStatus.generating).length;

    if (state.loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary));
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (state.error != null)
          _WarningBanner(message: state.error!, color: AppTheme.error),
        if (state.message != null)
          _WarningBanner(
            message: state.message!,
            color: AppTheme.success,
            onDismiss: controller.clearMessage,
          ),
        _ProCard(
          icon: Icons.movie_filter_rounded,
          title: 'Proxy workflow',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricGrid(
                items: [
                  _MetricItem('Video assets', '${videoAssets.length}'),
                  _MetricItem('Ready', '$ready'),
                  _MetricItem('Queued', '$queued'),
                  _MetricItem('Running', state.running || running > 0 ? 'Yes' : 'No'),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use proxies for preview', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: const Text(
                  'Automatically choose edit-friendly media when available.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                value: state.settings.enabled,
                onChanged: controller.toggleProxyPreview,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-generate on import', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: const Text(
                  'Queue proxies for heavy videos as they enter the project.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                value: state.settings.autoGenerateOnImport,
                onChanged: controller.updateAutoGenerate,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pause while playing', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: const Text(
                  'Protect preview smoothness during playback.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                value: state.settings.pauseProxyGenerationDuringPlayback,
                onChanged: controller.togglePauseOnPlayback,
              ),
              const SizedBox(height: 10),
              _ProxyDropdown<NleProxyResolutionPreset>(
                label: 'Proxy resolution',
                value: state.settings.resolutionPreset,
                values: NleProxyResolutionPreset.values,
                labelFor: (value) => value.name.replaceFirst('p', '') + 'p',
                onChanged: controller.updateResolutionPreset,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.running ? null : controller.startQueue,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Run queue'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.running ? controller.stopQueue : null,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ProCard(
          icon: Icons.video_library_rounded,
          title: 'Assets needing proxies',
          child: Column(
            children: videoAssets.take(8).map((asset) {
              return _ProxyAssetRow(asset: asset, projectId: projectId);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _ProCard(
          icon: Icons.cleaning_services_rounded,
          title: 'Proxy cleanup',
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.deleteUnusedProxies,
                  icon: const Icon(Icons.auto_delete_rounded),
                  label: const Text('Unused'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeleteAll(context, controller),
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('All proxies'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, ProxyController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete all proxies?'),
        content: const Text(
          'This removes generated proxy files only. Original media is kept safe.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteAllProxies();
  }
}

class _ProxyAssetRow extends ConsumerWidget {
  final NleMediaAsset asset;
  final String projectId;

  const _ProxyAssetRow({
    required this.asset,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(proxyControllerProvider(projectId).notifier);
    final ready = asset.proxyStatus == NleProxyStatus.ready;
    final generating = asset.proxyStatus == NleProxyStatus.generating || asset.proxyStatus == NleProxyStatus.queued;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ready ? Icons.check_circle_rounded : Icons.movie_rounded,
        color: ready ? AppTheme.success : AppTheme.accentPrimary,
      ),
      title: Text(
        asset.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${asset.proxyStatus.name} • ${_resolutionLabel(asset)}',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing: TextButton(
        onPressed: ready || generating ? null : () => controller.generateProxyManual(asset.id),
        child: Text(ready ? 'Ready' : generating ? 'Queued' : 'Generate'),
      ),
    );
  }
}

class _ProxyDropdown<T extends Enum> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  const _ProxyDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: AppTheme.surfaceDark,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: values
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelFor(item)),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ProCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ProCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentPrimary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricItem> items;

  const _MetricGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          width: 132,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 5),
              Text(
                item.value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;

  const _MetricItem(this.label, this.value);
}

class _WarningBanner extends StatelessWidget {
  final String message;
  final Color color;
  final VoidCallback? onDismiss;

  const _WarningBanner({
    required this.message,
    required this.color,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 12)),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

int _estimateWidth(String aspectRatio, int height) {
  final width = switch (aspectRatio) {
    '9:16' => height * 9 ~/ 16,
    '1:1' => height,
    '4:5' => height * 4 ~/ 5,
    '21:9' => height * 21 ~/ 9,
    _ => height * 16 ~/ 9,
  };
  return (width ~/ 2) * 2;
}

String _resolutionLabel(NleMediaAsset asset) {
  final width = asset.videoInfo.width;
  final height = asset.videoInfo.height;
  if (width <= 0 || height <= 0) {
    return TimeUtils.formatFileSize(asset.fileInfo.fileSizeBytes);
  }
  return '${width}×$height • ${TimeUtils.formatFileSize(asset.fileInfo.fileSizeBytes)}';
}
