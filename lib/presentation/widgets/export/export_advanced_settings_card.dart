import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/export/advanced_export_settings.dart';
import 'package:nle_editor/presentation/providers/advanced_export_settings_provider.dart';

class ExportAdvancedSettingsCard extends ConsumerStatefulWidget {
  final String projectId;

  const ExportAdvancedSettingsCard({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ExportAdvancedSettingsCard> createState() =>
      _ExportAdvancedSettingsCardState();
}

class _ExportAdvancedSettingsCardState
    extends ConsumerState<ExportAdvancedSettingsCard> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSavedSettings);
  }

  Future<void> _loadSavedSettings() async {
    final saved = await loadAdvancedExportSettings(widget.projectId);
    if (!mounted) return;
    ref.read(advancedExportSettingsProvider(widget.projectId).notifier).state = saved;
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(advancedExportSettingsProvider(widget.projectId));
    void set(String key, Object? value) {
      updateAdvancedExportSetting(ref, widget.projectId, key, value);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppTheme.accentPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Advanced Export Settings',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!_loaded)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Dropdown(
            label: 'Destination',
            value: settings['destinationMode']?.toString() ?? ExportDestinationModes.appExports,
            values: const [
              ExportDestinationModes.appExports,
              ExportDestinationModes.gallery,
              ExportDestinationModes.shareOnly,
              ExportDestinationModes.customFolder,
            ],
            onChanged: (value) => set('destinationMode', value),
          ),
          if (settings['destinationMode'] == ExportDestinationModes.customFolder) ...[
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Custom folder path'),
              controller: TextEditingController(
                text: settings['customDirectoryPath']?.toString() ?? '',
              ),
              onChanged: (value) => set('customDirectoryPath', value),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Dropdown(
                  label: 'Video codec',
                  value: settings['videoCodec']?.toString() ?? ExportVideoCodecs.h264,
                  values: const [
                    ExportVideoCodecs.h264,
                    ExportVideoCodecs.h265,
                    ExportVideoCodecs.proRes,
                  ],
                  onChanged: (value) => set('videoCodec', value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Dropdown(
                  label: 'Profile',
                  value: settings['encoderProfile']?.toString() ?? 'high',
                  values: const ['baseline', 'main', 'high'],
                  onChanged: (value) => set('encoderProfile', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _IntDropdown(
                  label: 'Audio kbps',
                  value: settings['audioBitrateKbps'] as int? ?? 192,
                  values: const [96, 128, 192, 256, 320],
                  onChanged: (value) => set('audioBitrateKbps', value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _IntDropdown(
                  label: 'Sample rate',
                  value: settings['audioSampleRate'] as int? ?? 48000,
                  values: const [44100, 48000],
                  onChanged: (value) => set('audioSampleRate', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Dropdown(
                  label: 'Color space',
                  value: settings['colorSpace']?.toString() ?? ExportColorSpaces.rec709,
                  values: const [
                    ExportColorSpaces.rec709,
                    ExportColorSpaces.rec2020,
                    ExportColorSpaces.displayP3,
                  ],
                  onChanged: (value) => set('colorSpace', value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Dropdown(
                  label: 'Color range',
                  value: settings['colorRange']?.toString() ?? 'limited',
                  values: const ['limited', 'full'],
                  onChanged: (value) => set('colorRange', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Metadata title'),
            controller: TextEditingController(
              text: settings['metadataTitle']?.toString() ?? '',
            ),
            onChanged: (value) => set('metadataTitle', value),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Metadata creator'),
            controller: TextEditingController(
              text: settings['metadataCreator']?.toString() ?? '',
            ),
            onChanged: (value) => set('metadataCreator', value),
          ),
          _Switch(
            title: 'Prefer hardware encoder',
            value: settings['preferHardwareEncoder'] != false,
            onChanged: (value) => set('preferHardwareEncoder', value),
          ),
          _Switch(
            title: 'Save to gallery',
            value: settings['saveToGallery'] == true,
            onChanged: (value) => set('saveToGallery', value),
          ),
          _Switch(
            title: 'Share after export',
            value: settings['shareAfterExport'] == true,
            onChanged: (value) => set('shareAfterExport', value),
          ),
          _Switch(
            title: 'Mute all audio',
            value: settings['muteAllAudio'] == true,
            onChanged: (value) => set('muteAllAudio', value),
          ),
          _Switch(
            title: 'Normalize audio',
            value: settings['normalizeAudio'] == true,
            onChanged: (value) => set('normalizeAudio', value),
          ),
          _Switch(
            title: 'HDR export',
            value: settings['hdrExport'] == true,
            onChanged: (value) => set('hdrExport', value),
          ),
          _Switch(
            title: 'Tone-map HDR to SDR',
            value: settings['toneMapHdrToSdr'] != false,
            onChanged: (value) => set('toneMapHdrToSdr', value),
          ),
          _Switch(
            title: 'Generate export thumbnail',
            value: settings['generateThumbnail'] != false,
            onChanged: (value) => set('generateThumbnail', value),
          ),
          _Switch(
            title: 'Completion notification',
            value: settings['showCompletionNotification'] != false,
            onChanged: (value) => set('showCompletionNotification', value),
          ),
          _Switch(
            title: 'Crash recovery',
            value: settings['recoverAfterCrash'] != false,
            onChanged: (value) => set('recoverAfterCrash', value),
          ),
          _Switch(
            title: 'Multi-track export QA',
            value: settings['enableMultiTrackQa'] != false,
            onChanged: (value) => set('enableMultiTrackQa', value),
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: values.contains(value) ? value : values.first,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _IntDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  const _IntDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: values.contains(value) ? value : values.first,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item.toString())))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _Switch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Switch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(title),
    );
  }
}
