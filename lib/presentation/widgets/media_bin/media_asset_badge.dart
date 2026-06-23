import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';

class MediaAssetBadge extends StatelessWidget {
  final String fileType;

  const MediaAssetBadge({
    super.key,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (fileType.toLowerCase()) {
      case 'video':
        badgeColor = AppTheme.clipVideo;
        label = 'VIDEO';
        icon = Icons.videocam_rounded;
        break;
      case 'audio':
        badgeColor = AppTheme.clipAudio;
        label = 'AUDIO';
        icon = Icons.audiotrack_rounded;
        break;
      case 'image':
        badgeColor = AppTheme.clipImage;
        label = 'IMAGE';
        icon = Icons.image_rounded;
        break;
      default:
        badgeColor = AppTheme.textMuted;
        label = 'FILE';
        icon = Icons.insert_drive_file_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 10,
            color: badgeColor.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: badgeColor.withValues(alpha: 0.9),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
