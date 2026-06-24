import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/media_library/media_bin_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/source_preview_providers.dart';
import 'package:nle_editor/presentation/providers/dual_preview_layout_providers.dart';
import 'package:nle_editor/presentation/widgets/media_bin/media_asset_badge.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';
import 'package:nle_editor/presentation/helpers/permission_flow_helper.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';

class MediaPoolPanel extends ConsumerStatefulWidget {
  const MediaPoolPanel({super.key});

  @override
  ConsumerState<MediaPoolPanel> createState() => _MediaPoolPanelState();
}

class _MediaPoolPanelState extends ConsumerState<MediaPoolPanel> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  String? _selectedBinId; // Null means All Media
  String _selectedFileType = 'all'; // 'all', 'video', 'audio', 'image'
  NleMediaSortMode _sortMode = NleMediaSortMode.newest;
  NleMediaViewMode _viewMode = NleMediaViewMode.grid;

  NleMediaAsset? _selectedAssetForDetails;
  bool _binsInitialized = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAndInitBins(String projectId, List<NleMediaBin> currentBins) async {
    if (_binsInitialized || currentBins.isNotEmpty) return;
    _binsInitialized = true;

    final repository = ref.read(mediaAssetRepositoryProvider);
    final defaultBins = [
      NleMediaBin.root(id: const Uuid().v4(), projectId: projectId),
      NleMediaBin.defaultVideos(id: const Uuid().v4(), projectId: projectId),
      NleMediaBin.defaultAudio(id: const Uuid().v4(), projectId: projectId),
      NleMediaBin.defaultImages(id: const Uuid().v4(), projectId: projectId),
      NleMediaBin.defaultUnused(id: const Uuid().v4(), projectId: projectId),
    ];

    for (final bin in defaultBins) {
      await repository.saveBin(bin);
    }
    ref.invalidate(projectMediaBinsProvider(projectId));
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(selectedProjectProvider);

    return projectAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
      data: (project) {
        if (project == null) return const SizedBox.shrink();

        final binsAsync = ref.watch(projectMediaBinsProvider(project.id));
        final assetsAsync = ref.watch(projectMediaAssetsProvider(project.id));
        final clipsAsync = ref.watch(projectClipsProvider(project.id));

        final usedAssetIds = clipsAsync.value?.map((c) => c.assetId).whereType<String>().toSet() ?? {};

        // Trigger bin initialization if database has no bins
        binsAsync.whenData((bins) => _checkAndInitBins(project.id, bins));

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Sidebar: Bin Tree & Folders
            Container(
              width: 180,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E24),
                border: Border(
                  right: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
                ),
              ),
              child: binsAsync.when(
                loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const Center(child: Icon(Icons.error_outline_rounded)),
                data: (bins) {
                  final activeBin = bins.firstWhere((b) => b.id == _selectedBinId, orElse: () => NleMediaBin(
                    id: '', projectId: project.id, name: 'All Media', sortIndex: -1, smartBin: true, createdAt: DateTime.now(), updatedAt: DateTime.now(), version: 1
                  ));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'COLLECTIONS',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.create_new_folder_rounded, size: 16, color: AppTheme.textMuted),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Create Bin',
                              onPressed: () => _showCreateBinDialog(context, project.id),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildBinTile(
                              icon: Icons.grid_view_rounded,
                              label: 'All Media',
                              isActive: _selectedBinId == null,
                              onTap: () => setState(() => _selectedBinId = null),
                            ),
                            ...bins.map((bin) {
                              final isSmart = bin.smartBin;
                              final icon = isSmart
                                  ? (bin.name == 'Videos'
                                      ? Icons.videocam_rounded
                                      : bin.name == 'Audio'
                                          ? Icons.audiotrack_rounded
                                          : bin.name == 'Images'
                                              ? Icons.image_rounded
                                              : Icons.bookmark_rounded)
                                  : Icons.folder_rounded;

                              return _buildBinTile(
                                icon: icon,
                                label: bin.name,
                                isActive: _selectedBinId == bin.id,
                                onTap: () => setState(() => _selectedBinId = bin.id),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Right Panel: Filter, Toolbar, Asset Grid
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: AppTheme.surfaceDark,
                    child: Column(
                      children: [
                        // Missing Media Alert Banner
                        assetsAsync.whenData((assets) {
                          final missingCount = assets.where((a) => a.isMissing).length;
                          if (missingCount > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: const Color(0xFF3D1F23),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$missingCount media file(s) missing from disk.',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => _showRelinkDialog(context, project.id, assets),
                                    child: const Text(
                                      'Relink...',
                                      style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }).value ?? const SizedBox.shrink(),

                        // Header / Toolbar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    _buildFilterTab('All', 'all'),
                                    _buildFilterTab('Videos', 'video'),
                                    _buildFilterTab('Audio', 'audio'),
                                    _buildFilterTab('Images', 'image'),
                                  ],
                                ),
                                const SizedBox(width: 12),
                              // Search Input
                              SizedBox(
                                width: 100, // Reduced from 140
                                height: 28,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 13),
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: AppTheme.surfaceElevated,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4), // Reduced from 8
                              // Sort menu
                              PopupMenuButton<NleMediaSortMode>(
                                icon: const Icon(Icons.sort_rounded, size: 18, color: AppTheme.textMuted),
                                tooltip: 'Sort Options',
                                onSelected: (mode) => setState(() => _sortMode = mode),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: NleMediaSortMode.newest, child: Text('Import Date (Newest)')),
                                  const PopupMenuItem(value: NleMediaSortMode.oldest, child: Text('Import Date (Oldest)')),
                                  const PopupMenuItem(value: NleMediaSortMode.nameAsc, child: Text('Name (A-Z)')),
                                  const PopupMenuItem(value: NleMediaSortMode.nameDesc, child: Text('Name (Z-A)')),
                                  const PopupMenuItem(value: NleMediaSortMode.duration, child: Text('Duration')),
                                  const PopupMenuItem(value: NleMediaSortMode.fileSize, child: Text('File Size')),
                                  const PopupMenuItem(value: NleMediaSortMode.usedFirst, child: Text('Used Media First')),
                                  const PopupMenuItem(value: NleMediaSortMode.unusedFirst, child: Text('Unused Media First')),
                                ],
                              ),
                              // View Toggle
                              IconButton(
                                icon: Icon(
                                  _viewMode == NleMediaViewMode.grid ? Icons.view_headline_rounded : Icons.grid_view_rounded,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: _viewMode == NleMediaViewMode.grid ? 'Switch to List' : 'Switch to Grid',
                                onPressed: () => setState(() => _viewMode = _viewMode == NleMediaViewMode.grid ? NleMediaViewMode.list : NleMediaViewMode.grid),
                              ),
                              const SizedBox(width: 4), // Reduced from 8
                              // Clean Unused Button
                              IconButton(
                                icon: const Icon(Icons.cleaning_services_rounded, size: 18, color: AppTheme.textMuted),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Cleanup Unused Media',
                                onPressed: () => _cleanupUnusedMedia(project.id, usedAssetIds),
                              ),
                              const SizedBox(width: 8),
                              // Import Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentPrimary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () async {
                                  try {
                                    final permissionType = AppPermissionType.mediaLibrary;

                                    final hasPerm = await PermissionFlowHelper.ensureWithDialog(
                                      context,
                                      ref,
                                      permissionType: permissionType,
                                      projectId: project.id,
                                    );
                                    if (!hasPerm) return;

                                    await ref.read(mediaImportServiceProvider).pickAndImportMedia(project.id);
                                    ref.invalidate(projectMediaAssetsProvider(project.id));
                                  } catch (e, st) {
                                    debugPrint('Import Error: $e\n$st');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to import: $e'),
                                          backgroundColor: AppTheme.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.add_rounded, size: 14),
                                label: const Text('Import', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        // Media Asset Grid/List View
                        Expanded(
                          child: assetsAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
                            error: (err, _) => Center(child: Text('Error loading assets: $err')),
                            data: (assets) {
                              // Apply usage tracking updates
                              _updateAssetsUsageInDb(assets, usedAssetIds);

                              // Local Filter
                              var filtered = assets;

                              // Filter by selected collection/bin
                              if (_selectedBinId != null) {
                                binsAsync.whenData((bins) {
                                  final currentBin = bins.firstWhere((b) => b.id == _selectedBinId);
                                  if (currentBin.smartBin) {
                                    final query = currentBin.smartQuery ?? '';
                                    if (query.startsWith('type:')) {
                                      final type = query.split(':')[1];
                                      filtered = filtered.where((a) => a.type.name == type).toList();
                                    } else if (query.startsWith('usage:')) {
                                      final usage = query.split(':')[1];
                                      if (usage == 'unused') {
                                        filtered = filtered.where((a) => !usedAssetIds.contains(a.id)).toList();
                                      }
                                    }
                                  }
                                });
                              }

                              // Filter by selected file type tab
                              if (_selectedFileType != 'all') {
                                filtered = filtered.where((a) => a.type.name == _selectedFileType).toList();
                              }

                              // Search Filter
                              if (_searchQuery.isNotEmpty) {
                                filtered = filtered.where((a) {
                                  final nameMatch = a.displayName.toLowerCase().contains(_searchQuery);
                                  final tagMatch = a.tags.any((t) => t.toLowerCase().contains(_searchQuery));
                                  return nameMatch || tagMatch;
                                }).toList();
                              }

                              // Sorting
                              filtered.sort((a, b) {
                                switch (_sortMode) {
                                  case NleMediaSortMode.oldest:
                                    return a.importedAt.compareTo(b.importedAt);
                                  case NleMediaSortMode.nameAsc:
                                    return a.displayName.compareTo(b.displayName);
                                  case NleMediaSortMode.nameDesc:
                                    return b.displayName.compareTo(a.displayName);
                                  case NleMediaSortMode.duration:
                                    return b.durationMicros.compareTo(a.durationMicros);
                                  case NleMediaSortMode.fileSize:
                                    return b.fileInfo.fileSizeBytes.compareTo(a.fileInfo.fileSizeBytes);
                                  case NleMediaSortMode.usedFirst:
                                    final aUsed = usedAssetIds.contains(a.id) ? 1 : 0;
                                    final bUsed = usedAssetIds.contains(b.id) ? 1 : 0;
                                    return bUsed.compareTo(aUsed);
                                  case NleMediaSortMode.unusedFirst:
                                    final aUsed = usedAssetIds.contains(a.id) ? 1 : 0;
                                    final bUsed = usedAssetIds.contains(b.id) ? 1 : 0;
                                    return aUsed.compareTo(bUsed);
                                  case NleMediaSortMode.type:
                                    return a.type.name.compareTo(b.type.name);
                                  case NleMediaSortMode.newest:
                                  default:
                                    return b.importedAt.compareTo(a.importedAt);
                                }
                              });

                              if (filtered.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No media assets found matching the criteria.',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                );
                              }

                              return _viewMode == NleMediaViewMode.grid
                                  ? GridView.builder(
                                      padding: const EdgeInsets.all(10),
                                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 140,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                        childAspectRatio: 1.0,
                                      ),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, idx) => _buildAssetGridTile(filtered[idx], usedAssetIds.contains(filtered[idx].id), project),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) => const Divider(color: AppTheme.borderSubtle, height: 1),
                                      itemBuilder: (context, idx) => _buildAssetListTile(filtered[idx], usedAssetIds.contains(filtered[idx].id), project),
                                    );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Asset Detail Inspector Side Drawer (Overlays grid)
                  if (_selectedAssetForDetails != null)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: _buildDetailsPanel(_selectedAssetForDetails!, usedAssetIds.contains(_selectedAssetForDetails!.id), project.id),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBinTile({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: isActive ? AppTheme.accentPrimary.withOpacity(0.08) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.accentPrimary : AppTheme.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? AppTheme.accentPrimary : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final active = _selectedFileType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFileType = value),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? AppTheme.accentPrimary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppTheme.accentPrimary : Colors.transparent, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.accentPrimary : AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAssetGridTile(NleMediaAsset asset, bool isUsed, dynamic project) {
    final hasThumb = asset.thumbnailPath != null && asset.thumbnailPath!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        ref.read(sourcePreviewControllerProvider(project.id).notifier).loadAsset(asset);
        ref.read(dualPreviewLayoutControllerProvider.notifier).showSource();
        setState(() => _selectedAssetForDetails = asset);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _selectedAssetForDetails?.id == asset.id ? AppTheme.accentPrimary : AppTheme.borderSubtle,
              width: _selectedAssetForDetails?.id == asset.id ? 1.5 : 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5.5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasThumb)
                  Image.file(File(asset.thumbnailPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholderIcon(asset))
                else
                  _buildPlaceholderIcon(asset),

                // Asset status labels
                if (asset.isMissing)
                  Container(
                    color: Colors.black45,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_rounded, color: AppTheme.error, size: 24),
                  ),

                // Checkmark for timeline usage
                if (isUsed)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 9),
                    ),
                  ),

                // Proxy status badge
                if (asset.type == NleMediaAssetType.video)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _buildProxyBadge(asset.proxyStatus),
                  ),

                // File duration / type indicator
                Positioned(
                  bottom: 4,
                  right: 4,
                  left: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MediaAssetBadge(fileType: asset.type.name),
                      if (asset.durationMicros > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                          child: Text(
                            _formatDuration(asset.durationMicros),
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetListTile(NleMediaAsset asset, bool isUsed, dynamic project) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(4)),
        child: asset.thumbnailPath != null
            ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(asset.thumbnailPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholderIcon(asset)))
            : _buildPlaceholderIcon(asset),
      ),
      title: Text(asset.displayName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${asset.type.name.toUpperCase()} • ${_formatBytes(asset.fileInfo.fileSizeBytes)}${asset.type == NleMediaAssetType.video ? ' • Proxy: ${asset.proxyStatus.name.toUpperCase()}' : ''}',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUsed) const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          Icon(asset.isMissing ? Icons.warning_amber_rounded : Icons.circle, color: asset.isMissing ? AppTheme.error : Colors.transparent, size: 12),
        ],
      ),
      selected: _selectedAssetForDetails?.id == asset.id,
      selectedTileColor: AppTheme.surfaceElevated,
      onTap: () {
        ref.read(sourcePreviewControllerProvider(project.id).notifier).loadAsset(asset);
        ref.read(dualPreviewLayoutControllerProvider.notifier).showSource();
        setState(() => _selectedAssetForDetails = asset);
      },
    );
  }

  Widget _buildPlaceholderIcon(NleMediaAsset asset) {
    final icon = switch (asset.type) {
      NleMediaAssetType.video => Icons.movie_rounded,
      NleMediaAssetType.audio => Icons.audiotrack_rounded,
      NleMediaAssetType.image => Icons.image_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
    return Center(child: Icon(icon, color: AppTheme.textMuted, size: 24));
  }

  Widget _buildDetailsPanel(NleMediaAsset asset, bool isUsed, String projectId) {
    final notesController = TextEditingController(text: asset.notes);
    final tagsController = TextEditingController(text: asset.tags.join(', '));

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E24),
        border: Border(left: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ASSET DETAIL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                  onPressed: () => setState(() => _selectedAssetForDetails = null),
                )
              ],
            ),
          ),
          const Divider(color: AppTheme.borderSubtle, height: 1),

          // Details List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _detailRow('Display Name', asset.displayName),
                _detailRow('Format/Mime', asset.fileInfo.extension.toUpperCase()),
                _detailRow('Size', _formatBytes(asset.fileInfo.fileSizeBytes)),
                if (asset.isVideo) ...[
                  _detailRow('Resolution', asset.videoInfo.resolutionLabel),
                  _detailRow('FPS', asset.videoInfo.fps.toStringAsFixed(2)),
                  _detailRow('Video Codec', asset.videoInfo.codec),
                ],
                if (asset.isAudio) ...[
                  _detailRow('Channels', asset.audioInfo.channelCount.toString()),
                  _detailRow('Sample Rate', '${asset.audioInfo.sampleRate} Hz'),
                  _detailRow('Audio Codec', asset.audioInfo.codec),
                ],
                _detailRow('Timeline Status', isUsed ? 'Used' : 'Unused'),
                const SizedBox(height: 12),
                
                // Tags Field
                const Text('Tags (comma separated)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                const SizedBox(height: 4),
                TextField(
                  controller: tagsController,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes Field
                const Text('Notes', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                const SizedBox(height: 4),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () async {
                    final tags = tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                    final updated = asset.copyWith(
                      notes: notesController.text.trim(),
                      tags: tags,
                    );
                    await ref.read(mediaAssetRepositoryProvider).saveAsset(updated);
                    setState(() => _selectedAssetForDetails = updated);
                    ref.invalidate(projectMediaAssetsProvider(projectId));
                  },
                  child: const Text('Save Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                if (asset.type == NleMediaAssetType.video) ...[
                  _detailRow('Proxy Status', asset.proxyStatus.name.toUpperCase()),
                  if (asset.proxyStatus == NleProxyStatus.none || asset.proxyStatus == NleProxyStatus.failed) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          side: const BorderSide(color: Colors.blueAccent, width: 0.5),
                        ),
                        icon: const Icon(Icons.speed_rounded, size: 14),
                        label: const Text('Generate Proxy'),
                        onPressed: () {
                          ref.read(proxyControllerProvider(projectId).notifier).generateProxyManual(asset.id);
                        },
                      ),
                    ),
                  ] else if (asset.proxyStatus == NleProxyStatus.queued || asset.proxyStatus == NleProxyStatus.generating) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orangeAccent,
                          side: const BorderSide(color: Colors.orangeAccent, width: 0.5),
                        ),
                        icon: const Icon(Icons.cancel, size: 14),
                        label: const Text('Cancel Proxy'),
                        onPressed: () async {
                          final state = ref.read(proxyControllerProvider(projectId));
                          final job = state.jobs.firstWhere((j) => j.assetId == asset.id);
                          await ref.read(proxyControllerProvider(projectId).notifier).cancelJob(job.id);
                        },
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                if (!isUsed)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error, width: 0.5),
                    ),
                    icon: const Icon(Icons.delete_rounded, size: 14),
                    label: const Text('Delete Asset'),
                    onPressed: () => _deleteAsset(asset, projectId),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDuration(int micros) {
    final secs = micros ~/ 1000000;
    final mins = secs ~/ 60;
    final remainingSecs = secs % 60;
    return '$mins:${remainingSecs.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  Future<void> _cleanupUnusedMedia(String projectId, Set<String> usedAssetIds) async {
    final repository = ref.read(mediaAssetRepositoryProvider);
    final assets = await repository.getAssets(projectId);
    final unused = assets.where((a) => !usedAssetIds.contains(a.id)).toList();

    if (unused.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unused media files to cleanup.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Cleanup Unused Media', style: TextStyle(color: Colors.white)),
        content: Text('Delete ${unused.length} unused assets and their copied files from the project? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final asset in unused) {
        if (asset.projectPath != null) {
          final file = File(asset.projectPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        await repository.deleteAsset(asset.id);
      }
      ref.invalidate(projectMediaAssetsProvider(projectId));
      setState(() => _selectedAssetForDetails = null);
    }
  }

  Future<void> _deleteAsset(NleMediaAsset asset, String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Asset', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${asset.displayName}"? This will delete the copied file on disk.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (asset.projectPath != null) {
        final file = File(asset.projectPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await ref.read(mediaAssetRepositoryProvider).deleteAsset(asset.id);
      ref.invalidate(projectMediaAssetsProvider(projectId));
      setState(() => _selectedAssetForDetails = null);
    }
  }

  Future<void> _updateAssetsUsageInDb(List<NleMediaAsset> assets, Set<String> usedAssetIds) async {
    final repository = ref.read(mediaAssetRepositoryProvider);
    for (final asset in assets) {
      final isUsed = usedAssetIds.contains(asset.id);
      final expectedState = isUsed ? NleMediaUsageState.used : NleMediaUsageState.unused;
      if (asset.usageState != expectedState) {
        await repository.setUsageState(assetId: asset.id, usageState: expectedState);
      }
    }
  }

  void _showCreateBinDialog(BuildContext context, String projectId) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Create Collection Bin', style: TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Bin Name (e.g. B-Roll, Interviews)',
            hintStyle: TextStyle(color: Colors.white30),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final bin = NleMediaBin(
                  id: const Uuid().v4(),
                  projectId: projectId,
                  name: name,
                  sortIndex: 10,
                  smartBin: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  version: 1,
                );
                await ref.read(mediaAssetRepositoryProvider).saveBin(bin);
                ref.invalidate(projectMediaBinsProvider(projectId));
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRelinkDialog(BuildContext context, String projectId, List<NleMediaAsset> assets) {
    final missing = assets.where((a) => a.isMissing).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Relink Missing Media', style: TextStyle(color: Colors.white, fontSize: 14)),
          content: SizedBox(
            width: 320,
            height: 240,
            child: ListView.builder(
              itemCount: missing.length,
              itemBuilder: (context, idx) {
                final asset = missing[idx];
                return ListTile(
                  dense: true,
                  title: Text(asset.displayName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(asset.originalPath ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                  trailing: IconButton(
                    icon: const Icon(Icons.link_rounded, color: AppTheme.accentPrimary),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.any);
                      if (result != null && result.files.single.path != null) {
                        final newPath = result.files.single.path!;
                        await ref.read(projectRepairServiceProvider).reconnectAsset(
                          assetId: asset.id,
                          newPath: newPath,
                        );
                        // Trigger copy helper if it's copiedIntoProject mode
                        if (asset.storageMode == NleMediaStorageMode.copiedIntoProject && asset.projectPath != null) {
                          try {
                            final destFile = File(asset.projectPath!);
                            if (!await destFile.parent.exists()) {
                              await destFile.parent.create(recursive: true);
                            }
                            await File(newPath).copy(asset.projectPath!);
                          } catch (_) {}
                        }
                        
                        ref.invalidate(projectMediaAssetsProvider(projectId));
                        setDialogState(() {
                          missing.removeAt(idx);
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  Widget _buildProxyBadge(NleProxyStatus status) {
    if (status == NleProxyStatus.none) return const SizedBox.shrink();

    Color bgColor = Colors.grey;
    String label = '';

    switch (status) {
      case NleProxyStatus.ready:
        bgColor = Colors.green.withOpacity(0.85);
        label = 'PROXY';
        break;
      case NleProxyStatus.queued:
      case NleProxyStatus.generating:
        bgColor = Colors.blue.withOpacity(0.85);
        label = 'OPTIMIZING';
        break;
      case NleProxyStatus.failed:
        bgColor = Colors.red.withOpacity(0.85);
        label = 'FAIL';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
      ),
    );
  }
}
