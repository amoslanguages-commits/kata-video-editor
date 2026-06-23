import 'package:flutter/material.dart';

import 'package:nle_editor/core/release/offline_privacy_summary.dart';
import 'package:nle_editor/core/release/privacy_data_map.dart';
import 'package:nle_editor/core/theme/app_theme.dart';

class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Privacy & Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Text(
              OfflinePrivacySummary.longText,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...PrivacyDataMap.items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PrivacyChip(
                        label: item.storedOnDevice
                            ? 'Stored on device'
                            : 'Not stored locally',
                      ),
                      _PrivacyChip(
                        label: item.leavesDevice
                            ? 'May leave device'
                            : 'Does not leave device',
                      ),
                      _PrivacyChip(
                        label: item.userControlled
                            ? 'User controlled'
                            : 'System controlled',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Retention: ${item.retention}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyChip extends StatelessWidget {
  final String label;

  const _PrivacyChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppTheme.surfaceElevated,
      labelStyle: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
