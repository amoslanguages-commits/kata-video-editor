import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/device/device_capability_card.dart';
import 'package:nle_editor/presentation/widgets/storage/project_storage_panel.dart';
import 'package:nle_editor/presentation/screens/errors/error_log_screen.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';
import 'package:nle_editor/presentation/screens/release/release_checklist_screen.dart';
import 'package:nle_editor/presentation/screens/store_readiness/store_readiness_screen.dart';
import 'package:nle_editor/presentation/screens/polish/ux_review_checklist_screen.dart';
import 'package:nle_editor/presentation/widgets/beta/beta_feedback_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: AppTheme.surfaceDark,
                    title: const Text('Reset settings?'),
                    content: const Text(
                      'This will restore default editor, export, and performance settings.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                await ref.read(appSettingsProvider.notifier).reset();
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const DeviceCapabilityCard(),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'General',
                icon: Icons.settings_rounded,
                children: [
                  _DropdownSetting<String>(
                    label: 'Theme',
                    value: settings.themeMode,
                    options: const {
                      'dark': 'Dark',
                      'light': 'Light',
                      'system': 'System',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(themeMode: value),
                          );
                    },
                  ),
                  _DropdownSetting<String>(
                    label: 'Language',
                    value: settings.languageCode,
                    options: const {
                      'system': 'System',
                      'en': 'English',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(languageCode: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Haptics',
                    subtitle: 'Use subtle vibration for editing actions.',
                    value: settings.hapticsEnabled,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(hapticsEnabled: value),
                          );
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: 'New Project Defaults',
                icon: Icons.movie_creation_rounded,
                children: [
                  _DropdownSetting<String>(
                    label: 'Default aspect ratio',
                    value: settings.defaultAspectRatio,
                    options: const {
                      '9:16': '9:16 Shorts / Reels / TikTok',
                      '16:9': '16:9 YouTube',
                      '1:1': '1:1 Square',
                      '4:5': '4:5 Social post',
                      '21:9': '21:9 Cinematic',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(defaultAspectRatio: value),
                          );
                    },
                  ),
                  _DropdownSetting<int>(
                    label: 'Default resolution',
                    value: settings.defaultResolutionHeight,
                    options: const {
                      720: '720p Draft',
                      1080: '1080p Standard',
                      2160: '4K where supported',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(defaultResolutionHeight: value),
                          );
                    },
                  ),
                  _DropdownSetting<int>(
                    label: 'Default frame rate',
                    value: settings.defaultFrameRate,
                    options: const {
                      24: '24 fps',
                      25: '25 fps',
                      30: '30 fps',
                      50: '50 fps',
                      60: '60 fps',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(defaultFrameRate: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Watermark by default',
                    subtitle: 'Free projects start with watermark enabled.',
                    value: settings.watermarkEnabledByDefault,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(watermarkEnabledByDefault: value),
                          );
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Editor',
                icon: Icons.tune_rounded,
                children: [
                  _SwitchSetting(
                    label: 'Show safe area',
                    subtitle: 'Useful for Shorts, Reels, TikTok, and captions.',
                    value: settings.showSafeArea,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(showSafeArea: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Snap clips',
                    subtitle: 'Snap trims/moves to playhead and clip edges.',
                    value: settings.snapClips,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(snapClips: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Show waveforms',
                    subtitle: 'Display waveform previews on audio clips.',
                    value: settings.showWaveforms,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(showWaveforms: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Show thumbnails',
                    subtitle: 'Display video thumbnails on timeline clips.',
                    value: settings.showThumbnails,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(showThumbnails: value),
                          );
                    },
                  ),
                  _DropdownSetting<String>(
                    label: 'Timeline zoom',
                    value: settings.timelineZoomBehavior,
                    options: const {
                      'pinch_and_buttons': 'Pinch + buttons',
                      'buttons_only': 'Buttons only',
                      'pinch_only': 'Pinch only',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(timelineZoomBehavior: value),
                          );
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Performance',
                icon: Icons.speed_rounded,
                children: [
                  _DropdownSetting<String>(
                    label: 'Preview quality',
                    value: settings.previewQuality,
                    options: const {
                      'auto': 'Auto',
                      'draft': 'Draft',
                      'balanced': 'Balanced',
                      'high': 'High',
                      'adaptive': 'Adaptive',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(previewQuality: value),
                          );
                    },
                  ),
                  _DropdownSetting<String>(
                    label: 'Proxy mode',
                    value: settings.proxyMode,
                    options: const {
                      'auto': 'Auto',
                      'always': 'Always create proxies',
                      'only_large_files': 'Only for large files',
                      'never': 'Never',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(proxyMode: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Auto-create proxies',
                    subtitle: 'Generate edit-friendly files for heavy videos.',
                    value: settings.autoCreateProxies,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(autoCreateProxies: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Reduce performance on low battery',
                    subtitle: 'Lower preview load when battery is low.',
                    value: settings.reducePerformanceOnLowBattery,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(
                                reducePerformanceOnLowBattery: value),
                          );
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Autosave & Recovery',
                icon: Icons.history_rounded,
                children: [
                  _SwitchSetting(
                    label: 'Autosave',
                    subtitle: 'Save recovery snapshots while editing.',
                    value: settings.autoSaveEnabled,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(autoSaveEnabled: value),
                          );
                    },
                  ),
                  _DropdownSetting<int>(
                    label: 'Autosave frequency',
                    value: settings.autosaveFrequencySeconds,
                    options: const {
                      5: 'Every 5 seconds',
                      8: 'Every 8 seconds',
                      15: 'Every 15 seconds',
                      30: 'Every 30 seconds',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(autosaveFrequencySeconds: value),
                          );
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Export Defaults',
                icon: Icons.file_upload_rounded,
                children: [
                  _DropdownSetting<String>(
                    label: 'Export preset',
                    value: settings.defaultExportPreset,
                    options: const {
                      'draft': 'Draft',
                      'standard': 'Standard',
                      'high': 'High Quality',
                      'small': 'Small File',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(defaultExportPreset: value),
                          );
                    },
                  ),
                  _DropdownSetting<String>(
                    label: 'Export codec',
                    value: settings.defaultExportCodec,
                    options: const {
                      'h264': 'H.264 Compatibility',
                      'hevc': 'HEVC where supported',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(defaultExportCodec: value),
                          );
                    },
                  ),
                  _DropdownSetting<String>(
                    label: 'Video bitrate',
                    value: settings.defaultExportBitrate,
                    options: const {
                      '4M': '4 Mbps',
                      '8M': '8 Mbps',
                      '12M': '12 Mbps',
                      '20M': '20 Mbps',
                      '35M': '35 Mbps',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(defaultExportBitrate: value),
                          );
                    },
                  ),
                  _DropdownSetting<String>(
                    label: 'Audio bitrate',
                    value: settings.defaultAudioBitrate,
                    options: const {
                      '128k': '128 kbps',
                      '192k': '192 kbps',
                      '256k': '256 kbps',
                      '320k': '320 kbps',
                    },
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(defaultAudioBitrate: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Keep screen awake during export',
                    subtitle: 'Helps long exports finish safely.',
                    value: settings.keepScreenAwakeDuringExport,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) =>
                                s.copyWith(keepScreenAwakeDuringExport: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Save to gallery automatically',
                    subtitle: 'Add completed exports to the phone gallery.',
                    value: settings.saveToGalleryAutomatically,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) =>
                                s.copyWith(saveToGalleryAutomatically: value),
                          );
                    },
                  ),
                  _SwitchSetting(
                    label: 'Ask before overwrite',
                    subtitle: 'Protect existing export files.',
                    value: settings.askBeforeOverwrite,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).update(
                            (s) => s.copyWith(askBeforeOverwrite: value),
                          );
                    },
                  ),
                ],
              ),
              if (selectedProjectId != null) ...[
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Current Project Storage',
                  icon: Icons.storage_rounded,
                  children: [
                    SizedBox(
                      height: 520,
                      child: ProjectStoragePanel(projectId: selectedProjectId),
                    ),
                  ],
                ),
              ],
              const _SettingsSection(
                title: 'Permissions',
                icon: Icons.lock_rounded,
                children: [
                  _PermissionSettingsTile(type: AppPermissionType.mediaLibrary),
                  _PermissionSettingsTile(type: AppPermissionType.gallerySave),
                  _PermissionSettingsTile(type: AppPermissionType.microphone),
                  _PermissionSettingsTile(
                      type: AppPermissionType.notifications),
                ],
              ),
              _SettingsSection(
                title: 'Beta Feedback',
                icon: Icons.feedback_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submit Feedback',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Report bugs, performance issues, or suggest new features.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            backgroundColor: AppTheme.surfaceElevated,
                            foregroundColor: AppTheme.accentPrimary,
                            side: const BorderSide(
                                color: AppTheme.borderSubtle, width: 0.5),
                          ),
                          onPressed: () {
                            BetaFeedbackDialog.show(context);
                          },
                          child: const Text('Send Feedback',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Diagnostics',
                icon: Icons.bug_report_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diagnostic Logs',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'View historical error logs and hardware warnings.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            backgroundColor: AppTheme.surfaceElevated,
                            foregroundColor: AppTheme.accentPrimary,
                            side: const BorderSide(
                                color: AppTheme.borderSubtle, width: 0.5),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ErrorLogScreen()),
                            );
                          },
                          child: const Text('View Logs',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (config.shouldShowInternalTools) ...[
                _SettingsSection(
                  title: 'Release Preparation',
                  icon: Icons.checklist_rtl_rounded,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Release Checklist',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Check production configurations, privacy disclosures, and QA status.',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              backgroundColor: AppTheme.surfaceElevated,
                              foregroundColor: AppTheme.accentPrimary,
                              side: const BorderSide(
                                  color: AppTheme.borderSubtle, width: 0.5),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ReleaseChecklistScreen()),
                              );
                            },
                            child: const Text('Open checklist',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child:
                          Divider(color: AppTheme.borderSubtle, thickness: 0.5),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Store Readiness',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Check store description metadata, visual plans, rating prep, and testing phases.',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              backgroundColor: AppTheme.surfaceElevated,
                              foregroundColor: AppTheme.accentPrimary,
                              side: const BorderSide(
                                  color: AppTheme.borderSubtle, width: 0.5),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const StoreReadinessScreen()),
                              );
                            },
                            child: const Text('Store readiness',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child:
                          Divider(color: AppTheme.borderSubtle, thickness: 0.5),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UX Review Checklist',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Check premium design tokens, micro-interactions, copy, accessibility, and gating rules.',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              backgroundColor: AppTheme.surfaceElevated,
                              foregroundColor: AppTheme.accentPrimary,
                              side: const BorderSide(
                                  color: AppTheme.borderSubtle, width: 0.5),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const UxReviewChecklistScreen()),
                              );
                            },
                            child: const Text('UX Review',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const _PrivacyPromiseCard(),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentPrimary),
          );
        },
        error: (err, stack) {
          return Center(
            child: Text(
              'Settings error: $err',
              style: const TextStyle(color: AppTheme.error),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.accentPrimary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _DropdownSetting<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _DropdownSetting({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<T>(
              initialValue: value,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceElevated,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
              ),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              items: options.entries.map((entry) {
                return DropdownMenuItem<T>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSetting({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.accentPrimary,
        title: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _PrivacyPromiseCard extends StatelessWidget {
  const _PrivacyPromiseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPrimary.withValues(alpha: 0.18),
            AppTheme.accentSecondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_rounded,
            color: AppTheme.accentPrimary,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Privacy promise: your videos and projects stay on your device. Core editing does not require cloud rendering, server storage, or video upload.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionSettingsTile extends ConsumerWidget {
  final String type;

  const _PermissionSettingsTile({
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purpose = AppPermissionPurposes.forType(type);
    final stateAsync = ref.watch(appPermissionStateProvider(type));

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: const Icon(
          Icons.lock_rounded,
          color: AppTheme.accentPrimary,
        ),
        title: Text(
          purpose.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: stateAsync.when(
          data: (state) {
            return Text(
              state.hasAccess
                  ? state.isLimited
                      ? 'Limited access'
                      : 'Allowed'
                  : 'Not allowed',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            );
          },
          loading: () => const Text(
            'Checking...',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          error: (_, __) => const Text(
            'Could not check',
            style: TextStyle(color: AppTheme.error, fontSize: 11),
          ),
        ),
        trailing: TextButton(
          onPressed: () async {
            final current =
                await ref.read(appPermissionServiceProvider).check(type);

            if (current.shouldOpenSettings) {
              await ref.read(appPermissionServiceProvider).openSettings();
            } else {
              await ref.read(appPermissionServiceProvider).request(
                    type,
                    source: 'settings_permissions',
                  );
            }

            ref.invalidate(appPermissionStateProvider(type));
          },
          child: const Text('Manage'),
        ),
      ),
    );
  }
}
