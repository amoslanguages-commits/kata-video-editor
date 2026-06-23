import 'package:flutter/material.dart' hide Clip;
import 'package:flutter/rendering.dart' as rendering;

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';

class MediaPoolLazyGrid extends StatelessWidget {
  final List<Asset> assets;
  final void Function(Asset asset)? onAssetTap;
  final void Function(Asset asset)? onGenerateProxy;

  const MediaPoolLazyGrid({
    super.key,
    required this.assets,
    this.onAssetTap,
    this.onGenerateProxy,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: assets.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final asset = assets[index];

        return RepaintBoundary(
          child: _MediaPoolTile(
            asset: asset,
            onTap: () => onAssetTap?.call(asset),
            onGenerateProxy: () => onGenerateProxy?.call(asset),
          ),
        );
      },
    );
  }
}

class _MediaPoolTile extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;
  final VoidCallback? onGenerateProxy;

  const _MediaPoolTile({
    required this.asset,
    this.onTap,
    this.onGenerateProxy,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = asset.fileType == 'video';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        clipBehavior: rendering.Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: AppTheme.surfaceElevated,
                alignment: Alignment.center,
                child: Icon(
                  isVideo ? Icons.movie_rounded : Icons.image_rounded,
                  color: AppTheme.textMuted,
                  size: 34,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      asset.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isVideo && asset.proxyStatus != 'ready')
                    IconButton(
                      tooltip: 'Generate proxy',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.speed_rounded,
                        size: 18,
                        color: AppTheme.warning,
                      ),
                      onPressed: onGenerateProxy,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
