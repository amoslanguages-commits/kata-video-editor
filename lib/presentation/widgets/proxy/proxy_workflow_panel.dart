import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/monetization_providers.dart';

class ProxyWorkflowPanel extends ConsumerWidget {
  const ProxyWorkflowPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final profileAsync = ref.watch(deviceCapabilityProfileProvider);
    final monetization = ref.watch(monetizationProvider);
    final rules = ref.watch(proPlanRulesProvider);
    final canBatchProxy = rules.canBatchProxy(monetization.entitlement);

    return settingsAsync.when(
      data: (settings) {
        return profileAsync.when(
          data: (profile) {
            final proxyRequired = profile.limits.proxyRequiredFor4k ||
                profile.recommendedProxyMode == 'always' ||
                profile.recommendedProxyMode == 'only_large_files';
            final proxyMode = settings.proxyMode;
            final autoProxyEnabled = settings.autoCreateProxies;

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
                          color: AppTheme.accentSecondary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.movie_filter_rounded,
                          color: AppTheme.accentSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proxy Workflow',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              proxyRequired
                                  ? 'Proxy-first editing recommended'
                                  : 'Original media is safe for normal projects',
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
                  _ProxyStep(
                    number: '1',
                    title: 'Import',
                    description: autoProxyEnabled
                        ? 'Heavy clips are prepared automatically after import.'
                        : 'Proxy generation is manual from the media panel.',
                    active: true,
                  ),
                  _ProxyStep(
                    number: '2',
                    title: 'Optimize',
                    description:
                        '${profile.limits.recommendedProxyHeight}p proxy target • mode: $proxyMode',
                    active: autoProxyEnabled || proxyRequired,
                  ),
                  _ProxyStep(
                    number: '3',
                    title: 'Edit smoothly',
                    description:
                        'Preview target: ${profile.limits.safePreviewHeight}p • ${profile.recommendedPreviewQuality}',
                    active: true,
                  ),
                  _ProxyStep(
                    number: '4',
                    title: 'Export original quality',
                    description: profile.limits.allow4kExport
                        ? '4K export can stay available on this device.'
                        : 'Export will adapt to ${profile.limits.maxExportHeight}p if needed.',
                    active: true,
                  ),
                  const SizedBox(height: 10),
                  _CapabilityRow(
                    label: 'Batch proxies',
                    value: canBatchProxy ? 'Available' : 'Pro feature',
                    color: canBatchProxy ? AppTheme.success : AppTheme.warning,
                  ),
                  _CapabilityRow(
                    label: 'Proxy requirement',
                    value: proxyRequired ? 'Recommended' : 'Optional',
                    color: proxyRequired ? AppTheme.accentPrimary : AppTheme.textMuted,
                  ),
                ],
              ),
            );
          },
          loading: () => const _ProxyLoadingPanel(),
          error: (error, stack) => _ProxyErrorPanel(message: 'Proxy profile unavailable: $error'),
        );
      },
      loading: () => const _ProxyLoadingPanel(),
      error: (error, stack) => _ProxyErrorPanel(message: 'Proxy settings unavailable: $error'),
    );
  }
}

class _ProxyStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final bool active;

  const _ProxyStep({
    required this.number,
    required this.title,
    required this.description,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.accentPrimary : AppTheme.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CapabilityRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProxyLoadingPanel extends StatelessWidget {
  const _ProxyLoadingPanel();

  @override
  Widget build(BuildContext context) {
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
          Text('Loading proxy workflow...', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _ProxyErrorPanel extends StatelessWidget {
  final String message;

  const _ProxyErrorPanel({required this.message});

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
