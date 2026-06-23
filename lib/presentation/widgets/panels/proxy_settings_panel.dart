import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/controllers/proxy_controller.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';
import 'package:nle_editor/domain/proxy/proxy_job_models.dart';

class ProxySettingsPanel extends ConsumerWidget {
  final String projectId;

  const ProxySettingsPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proxyControllerProvider(projectId));
    final controller = ref.read(proxyControllerProvider(projectId).notifier);

    return Drawer(
      backgroundColor: const Color(0xFF1E1E2C),
      child: Column(
        children: [
          _buildHeader(context, state),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (state.message != null) ...[
                  _buildMessageBanner(state.message!, controller.clearMessage),
                  const SizedBox(height: 16),
                ],
                if (state.error != null) ...[
                  _buildErrorBanner(state.error!),
                  const SizedBox(height: 16),
                ],
                _buildSectionHeader('Workflow Settings'),
                _buildSwitchTile(
                  title: 'Enable Proxy Preview',
                  subtitle: 'Use low-res media for smoother timeline scrubbing',
                  value: state.settings.enabled,
                  onChanged: controller.toggleProxyPreview,
                ),
                _buildSwitchTile(
                  title: 'Auto-Generate on Import',
                  subtitle: 'Automatically transcode heavy media assets',
                  value: state.settings.autoGenerateOnImport,
                  onChanged: controller.updateAutoGenerate,
                ),
                _buildSwitchTile(
                  title: 'Pause during timeline playback',
                  subtitle: 'Freer CPU resources for preview frames rendering',
                  value: state.settings.pauseProxyGenerationDuringPlayback,
                  onChanged: controller.togglePauseOnPlayback,
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildSectionHeader('Proxy Specs Settings'),
                _buildDropdownTile<NleProxyResolutionPreset>(
                  title: 'Resolution Preset',
                  value: state.settings.resolutionPreset,
                  items: NleProxyResolutionPreset.values,
                  itemLabel: (preset) {
                    switch (preset) {
                      case NleProxyResolutionPreset.p360:
                        return '360p (Low Quality)';
                      case NleProxyResolutionPreset.p540:
                        return '540p (Medium Quality)';
                      case NleProxyResolutionPreset.p720:
                        return '720p (High Quality)';
                      case NleProxyResolutionPreset.p1080:
                        return '1080p (Full HD)';
                    }
                  },
                  onChanged: (val) {
                    if (val != null) controller.updateResolutionPreset(val);
                  },
                ),
                _buildDropdownTile<NleProxyStoragePolicy>(
                  title: 'Cache Storage Policy',
                  value: state.settings.storagePolicy,
                  items: NleProxyStoragePolicy.values,
                  itemLabel: (policy) {
                    switch (policy) {
                      case NleProxyStoragePolicy.keepUntilDeleted:
                        return 'Keep until manually deleted';
                      case NleProxyStoragePolicy.deleteWhenProjectCloses:
                        return 'Clear when project is closed';
                      case NleProxyStoragePolicy.deleteUnusedAfterCleanup:
                        return 'Clear unused proxies automatically';
                    }
                  },
                  onChanged: (val) {
                    if (val != null) controller.updateStoragePolicy(val);
                  },
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildSectionHeader('Proxy Storage Controls'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cleaning_services, size: 16, color: Colors.amberAccent),
                        label: const Text('Clear Unused', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          backgroundColor: const Color(0xFF2E2E3E),
                        ),
                        onPressed: state.loading ? null : controller.deleteUnusedProxies,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever, size: 16, color: Colors.redAccent),
                        label: const Text('Delete All', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          backgroundColor: const Color(0xFF2E2E3E),
                        ),
                        onPressed: state.loading ? null : controller.deleteAllProxies,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildSectionHeader('Transcoding Queue'),
                const SizedBox(height: 8),
                if (state.jobs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No transcoding tasks in queue',
                        style: TextStyle(color: Colors.white30, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...state.jobs.map((job) {
                    final asset = state.assets.firstWhere((a) => a.id == job.assetId,
                        orElse: () => NleMediaAsset(
                              id: job.assetId,
                              projectId: job.projectId,
                              displayName: 'Unknown Asset',
                              type: NleMediaAssetType.video,
                              importSource: NleMediaImportSource.filePicker,
                              storageMode: NleMediaStorageMode.referencedExternal,
                              availability: NleMediaAvailability.available,
                              originalPath: job.sourcePath,
                              proxyStatus: NleProxyStatus.none,
                              usageState: NleMediaUsageState.unused,
                              fileInfo: const NleMediaFileInfo(fileName: '', extension: '', fileSizeBytes: 0),
                              videoInfo: const NleMediaVideoInfo.empty(),
                              audioInfo: const NleMediaAudioInfo.empty(),
                              timecodeInfo: const NleMediaTimecodeInfo.empty(),
                              tags: [],
                              importedAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                              version: 1,
                            ));
                    return _buildJobItem(job, asset, controller);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProxyEditorState state) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      color: const Color(0xFF14141F),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proxy Assets Manager',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                'Milestone 34B-PRO Optimized Workflow',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          if (state.running)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
            )
          else
            const Icon(Icons.settings, color: Colors.white30, size: 18),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      value: value,
      activeColor: Colors.blueAccent,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                dropdownColor: const Color(0xFF1E1E2C),
                value: value,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item)),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBanner(String message, VoidCallback onDismiss) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobItem(NleProxyJob job, NleMediaAsset asset, ProxyController controller) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.query_builder;

    switch (job.status) {
      case NleProxyGenerationStatus.queued:
        statusColor = Colors.amber;
        statusIcon = Icons.hourglass_empty;
        break;
      case NleProxyGenerationStatus.generating:
        statusColor = Colors.blueAccent;
        statusIcon = Icons.cached;
        break;
      case NleProxyGenerationStatus.ready:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case NleProxyGenerationStatus.failed:
        statusColor = Colors.redAccent;
        statusIcon = Icons.error;
        break;
      case NleProxyGenerationStatus.cancelled:
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.cancel;
        break;
      default:
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF252535),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  asset.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (job.status == NleProxyGenerationStatus.generating || job.status == NleProxyGenerationStatus.queued)
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white54, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => controller.cancelJob(job.id),
                )
              else if (job.status == NleProxyGenerationStatus.failed)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blueAccent, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => controller.retryJob(job.id),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status: ${job.status.name}',
                style: TextStyle(color: statusColor, fontSize: 10),
              ),
              if (job.status == NleProxyGenerationStatus.generating)
                Text(
                  '${(job.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
            ],
          ),
          if (job.status == NleProxyGenerationStatus.generating) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: job.progress,
                backgroundColor: Colors.white10,
                color: Colors.blueAccent,
                minHeight: 3,
              ),
            ),
          ],
          if (job.error != null) ...[
            const SizedBox(height: 6),
            Text(
              job.error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 9),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
