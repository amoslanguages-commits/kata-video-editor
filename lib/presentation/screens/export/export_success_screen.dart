import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:nle_editor/core/copy/app_copy.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_button.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_card.dart';

class ExportSuccessScreen extends StatelessWidget {
  final String outputPath;
  final String presetName;
  final int? fileSizeBytes;
  final Duration? renderDuration;

  const ExportSuccessScreen({
    super.key,
    required this.outputPath,
    required this.presetName,
    this.fileSizeBytes,
    this.renderDuration,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(outputPath);
    final fileName = file.path.split(Platform.pathSeparator).last;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(AppCopy.exportSuccessTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(PremiumSpacing.lg),
        children: [
          PremiumCard(
            gradient: PremiumGradients.hero,
            glow: true,
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1),
                  duration: PremiumMotion.slow,
                  curve: PremiumMotion.entranceCurve,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.success.withOpacity(0.55),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppTheme.success,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: PremiumSpacing.xl),
                const Text(
                  AppCopy.exportSuccessTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: PremiumSpacing.sm),
                const Text(
                  AppCopy.exportSuccessBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PremiumSpacing.lg),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FILE INFORMATION',
                  style: TextStyle(
                    color: AppTheme.accentPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: PremiumSpacing.md),
                _InfoRow(label: 'Name', value: fileName),
                const Divider(height: 24, color: AppTheme.borderSubtle),
                _InfoRow(label: 'Preset', value: presetName),
                const Divider(height: 24, color: AppTheme.borderSubtle),
                _InfoRow(label: 'Size', value: _formatSize(fileSizeBytes)),
                const Divider(height: 24, color: AppTheme.borderSubtle),
                _InfoRow(label: 'Render Speed', value: _formatDuration(renderDuration)),
                const Divider(height: 24, color: AppTheme.borderSubtle),
                _InfoRow(label: 'Output Path', value: file.path, selectable: true),
              ],
            ),
          ),
          const SizedBox(height: PremiumSpacing.xxl),
          PremiumButton(
            label: 'Share Video',
            icon: Icons.ios_share_rounded,
            expanded: true,
            onPressed: () async {
              final xfile = XFile(outputPath);
              await Share.shareXFiles([xfile], text: 'My exported video from Kata!');
            },
          ),
          const SizedBox(height: PremiumSpacing.md),
          PremiumButton(
            label: 'Back to Studio',
            icon: Icons.home_rounded,
            expanded: true,
            secondary: true,
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool selectable;

  const _InfoRow({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        if (selectable)
          SelectableText(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.3,
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
