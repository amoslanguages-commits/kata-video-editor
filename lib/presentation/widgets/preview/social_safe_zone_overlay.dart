import 'package:flutter/material.dart';
import 'package:nle_editor/core/theme/app_theme.dart';

enum SocialPlatform {
  tiktok,
  instagramReels,
  youtubeShorts,
}

class SocialSafeZoneOverlay extends StatelessWidget {
  final SocialPlatform platform;
  final bool isVisible;

  const SocialSafeZoneOverlay({
    super.key,
    this.platform = SocialPlatform.tiktok,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          
          // Only draw if we are in a vertical aspect ratio roughly 9:16
          if (width > height) return const SizedBox.shrink();

          return Stack(
            children: [
              // Safe Zone Border
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.accentPrimary.withOpacity(0.5),
                    width: 2.0,
                  ),
                ),
              ),
              
              // TikTok specific UI blockers
              if (platform == SocialPlatform.tiktok) ...[
                // Right side buttons area (Profile, Like, Comment, Share)
                Positioned(
                  right: width * 0.02,
                  bottom: height * 0.15,
                  width: width * 0.15,
                  height: height * 0.4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          'UI AREA',
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom description area
                Positioned(
                  left: width * 0.05,
                  bottom: height * 0.05,
                  width: width * 0.7,
                  height: height * 0.15,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'CAPTION AREA',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
