import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/source_preview/source_preview_models.dart';

class SourceAudioPlaceholder extends StatelessWidget {
  final SourcePreviewAsset asset;

  const SourceAudioPlaceholder({
    super.key,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing center circle with Audio icon
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF152A3A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B8D4).withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(
                color: const Color(0xFF00B8D4).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.audiotrack_rounded,
              size: 38,
              color: Color(0xFF00B8D4),
            ),
          ),

          const SizedBox(height: 24),

          // File Info
          Text(
            asset.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'AUDIO ONLY • ${asset.assetType.toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFF00B8D4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 24),

          // Waveform indicator visual lines
          _buildWaveformVisual(),
        ],
      ),
    );
  }

  Widget _buildWaveformVisual() {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(24, (index) {
          // Generate a wave shape
          final progress = index / 23;
          final heightMultiplier = (0.2 + 0.8 * (index % 3 == 0 ? 0.3 : (index % 2 == 0 ? 0.9 : 0.6)));
          final finalHeight = 24.0 * heightMultiplier * (progress < 0.5 ? progress * 2 : (1 - progress) * 2);

          return Container(
            width: 3,
            height: finalHeight.clamp(2.0, 32.0),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00B8D4).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}
