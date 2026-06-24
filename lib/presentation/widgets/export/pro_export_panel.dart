import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/monetization_providers.dart';

class ProExportPanel extends ConsumerWidget {
  const ProExportPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final deviceAsync = ref.watch(deviceCapabilityProfileProvider);
    final monetization = ref.watch(monetizationProvider);
    final rules = ref.watch(proPlanRulesProvider);

    return settingsAsync.when(
      data: (settings) {
        return deviceAsync.when(
          data: (device) {
            final requestedHeight = settings.defaultResolutionHeight;
            final requestedWidth = _widthForHeight(
              requestedHeight,
              settings.defaultAspectRatio,
            );
            final clampedHeight = device.clampExportHeight(requestedHeight);
            final clampedFrameRate = device.clampExportFrameRate(settings.defaultFrameRate);
            final wantsNoWatermark = !settings.watermarkEnabledByDefault;
            final exportDecision = rules.checkExport(
              entitlement: monetization.entitlement,
              width: requestedWidth,
              height: requestedHeight,
              removeWatermarkRequested: wantsNoWatermark,
            );
            final codec = device.recommendedExportCodec(
              userRequestedHevc: settings.defaultExportCodec == 'hevc',
            );
            final reasons = <String>[
              if (clampedHeight != requestedHeight)
                'Resolution will adapt to ${clampedHeight}p on this device.',
              if (clampedFrameRate != settings.defaultFrameRate)
                'Frame rate will adapt to ${clampedFrameRate}fps.',
              if (!exportDecision.allowed && exportDecision.blockedReason != null)
                exportDecision.blockedReason!,
              if (exportDecision.watermarkRequired)
                'Watermark is required on the current plan.',
              if (settings.defaultExportCodec == 'hevc' && codec != 'hevc')
                'HEVC requested, but H.264 is safer for this device.',
            ];

            return _PanelShell(
              title: 'Pro Export',
              subtitle: exportDecision.allowed
                  ? 'Ready with adaptive device limits'
                  : 'Needs Pro or safer export settings',
              icon: Icons.rocket_launch_rounded,
              accent: exportDecision.allowed ? AppTheme.success : AppTheme.warning,
              children: [
                _MetricGrid(
                  items: [
                    _MetricItem(
                      label: 'Preset',
                      value: settings.defaultExportPreset,
                    ),
                    _MetricItem(
                      label: 'Resolution',
                      value: clampedHeight == requestedHeight
                          ? '${requestedHeight}p'
                          : '${requestedHeight}p → ${clampedHeight}p',
                    ),
                    _MetricItem(
                      label: 'Frame rate',
                      value: clampedFrameRate == settings.defaultFrameRate
                          ? '${settings.defaultFrameRate}fps'
                          : '${settings.defaultFrameRate}fps → ${clampedFrameRate}fps',
                    ),
                    _MetricItem(
                      label: 'Codec',
                      value: codec.toUpperCase(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatusPill(
                  label: monetization.entitlement.isPro ? 'Pro unlocked' : 'Free plan',
                  icon: monetization.entitlement.isPro
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: monetization.entitlement.isPro
                      ? AppTheme.accentPrimary
                      : AppTheme.textMuted,
                ),
                const SizedBox(height: 12),
                if (reasons.isEmpty)
                  const _GuidanceText('No adaptive changes needed for the current default export settings.')
                else
                  ...reasons.map((reason) => _GuidanceText(reason)),
              ],
            );
          },
          loading: () => const _LoadingPanel(title: 'Checking export capability...'),
          error: (error, stack) => _ErrorPanel(message: 'Export profile unavailable: $error'),
        );
      },
      loading: () => const _LoadingPanel(title: 'Loading export settings...'),
      error: (error, stack) => _ErrorPanel(message: 'Export settings unavailable: $error'),
    );
  }

  int _widthForHeight(int height, String aspectRatio) {
    switch (aspectRatio) {
      case '9:16':
        return (height * 9 / 16).round();
      case '1:1':
        return height;
      case '4:5':
        return (height * 4 / 5).round();
      case '21:9':
        return (height * 21 / 9).round();
      case '16:9':
      default:
        return (height * 16 / 9).round();
    }
  }
}

class _PanelShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.children,
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
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
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          width: 132,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
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

  const _MetricItem({required this.label, required this.value});
}

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceText extends StatelessWidget {
  final String text;

  const _GuidanceText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  final String title;

  const _LoadingPanel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accentPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.error)),
    );
  }
}
