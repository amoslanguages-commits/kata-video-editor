import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class DeviceCapabilityCard extends ConsumerWidget {
  const DeviceCapabilityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(deviceCapabilityProfileProvider);

    return profileAsync.when(
      data: (profile) {
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.memory_rounded,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Device Performance Profile',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _prettyTier(profile.tier),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(deviceCapabilityProfileProvider);
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: 'Preview',
                value: '${profile.recommendedPreviewQuality} • ${profile.limits.safePreviewHeight}p',
              ),
              _InfoRow(
                label: 'Proxy',
                value: '${profile.recommendedProxyMode} • ${profile.limits.recommendedProxyHeight}p',
              ),
              _InfoRow(
                label: 'Export limit',
                value:
                    '${profile.limits.maxExportHeight}p • ${profile.limits.maxExportFrameRate}fps',
              ),
              _InfoRow(
                label: 'Codec',
                value: profile.codecSupport.hevcEncode
                    ? 'H.264 + HEVC'
                    : 'H.264 safest',
              ),
              _InfoRow(
                label: 'Advanced effects',
                value: profile.limits.advancedEffectsEnabled ? 'Enabled' : 'Limited',
              ),
              _InfoRow(
                label: 'Source',
                value: profile.source,
              ),
              const SizedBox(height: 10),
              Text(
                profile.source == 'flutter_placeholder'
                    ? 'Using conservative fallback limits because native capability detection is unavailable on this platform.'
                    : 'Using native device and codec capability data with conservative safety limits for preview and export.',
                style: const TextStyle(
                  color: AppTheme.textDisabled,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
      loading: () {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentPrimary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Checking device profile...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        );
      },
      error: (err, stack) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Text(
            'Device profile unavailable: $err',
            style: const TextStyle(color: AppTheme.error),
          ),
        );
      },
    );
  }

  String _prettyTier(String tier) {
    switch (tier) {
      case 'low_end':
        return 'Low-end device profile';
      case 'mid_range':
        return 'Mid-range device profile';
      case 'high_end':
        return 'High-end device profile';
      case 'flagship':
        return 'Flagship device profile';
      default:
        return tier;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
