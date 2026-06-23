import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/export/export_preset_builder_models.dart';
import 'package:nle_editor/domain/export/export_quality_advisor.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/export_preset_builder_providers.dart';
import 'package:nle_editor/presentation/providers/export_readiness_provider.dart';
import 'package:nle_editor/presentation/providers/monetization_providers.dart';

class ExportPresetBuilderPanel extends ConsumerStatefulWidget {
  final String projectId;

  const ExportPresetBuilderPanel({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ExportPresetBuilderPanel> createState() =>
      _ExportPresetBuilderPanelState();
}

class _ExportPresetBuilderPanelState
    extends ConsumerState<ExportPresetBuilderPanel> {
  static const _uuid = Uuid();

  final _nameController = TextEditingController(text: 'My Export Preset');
  final _widthController = TextEditingController(text: '1080');
  final _heightController = TextEditingController(text: '1920');
  final _bitrateController = TextEditingController(text: '12');

  int _frameRate = 30;
  String _format = 'mp4';
  String _platform = 'Custom';
  bool _removeWatermark = false;
  bool _saving = false;
  String? _exportingPresetId;

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _bitrateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presetsAsync = ref.watch(projectExportPresetsProvider(widget.projectId));

    return Container(
      color: AppTheme.editorBackground,
      child: presetsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPrimary),
        ),
        error: (error, _) => Center(
          child: Text(
            'Export presets unavailable: $error',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
        data: (presets) {
          final builtIn = presets.where((preset) => preset.isBuiltIn).toList();
          final custom = presets.where((preset) => !preset.isBuiltIn).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _PresetHeader(),
              const SizedBox(height: 14),
              _BuilderCard(
                saving: _saving,
                nameController: _nameController,
                widthController: _widthController,
                heightController: _heightController,
                bitrateController: _bitrateController,
                frameRate: _frameRate,
                format: _format,
                platform: _platform,
                removeWatermark: _removeWatermark,
                onFrameRateChanged: (value) => setState(() => _frameRate = value),
                onFormatChanged: (value) => setState(() => _format = value),
                onPlatformChanged: (value) => setState(() => _platform = value),
                onWatermarkChanged: (value) => setState(() => _removeWatermark = value),
                onSave: _savePreset,
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Built-in Platform Presets'),
              const SizedBox(height: 10),
              ...builtIn.map(
                (preset) => _PresetCard(
                  preset: preset,
                  isExporting: _exportingPresetId == preset.id,
                  onUse: () => _startExportWithPreset(preset),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle('My Custom Presets'),
              const SizedBox(height: 10),
              if (custom.isEmpty)
                const _EmptyCustomPresets()
              else
                ...custom.map(
                  (preset) => _PresetCard(
                    preset: preset,
                    isExporting: _exportingPresetId == preset.id,
                    onUse: () => _startExportWithPreset(preset),
                    onRemove: () => _removePreset(preset.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _savePreset() async {
    final name = _nameController.text.trim();
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    final bitrate = int.tryParse(_bitrateController.text.trim());

    if (name.isEmpty || width == null || height == null || bitrate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a name, width, height, and bitrate.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final preset = NleExportPresetSpec(
      id: 'custom_${_uuid.v4()}',
      name: name,
      description: 'Custom $_platform export preset.',
      platform: _platform,
      width: width,
      height: height,
      frameRate: _frameRate,
      bitrateMbps: bitrate,
      format: _format,
      removeWatermark: _removeWatermark,
      isBuiltIn: false,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(exportPresetStoreServiceProvider).saveCustomPreset(
            projectId: widget.projectId,
            preset: preset,
          );
      ref.invalidate(projectExportPresetsProvider(widget.projectId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export preset saved.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startExportWithPreset(NleExportPresetSpec preset) async {
    final readiness = ref.read(exportReadinessProvider(widget.projectId));
    if (!readiness.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(readiness.userMessage),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final monetization = ref.read(monetizationProvider);
    final rules = ref.read(proPlanRulesProvider);
    final decision = rules.checkExport(
      entitlement: monetization.entitlement,
      width: preset.width,
      height: preset.height,
      removeWatermarkRequested: preset.removeWatermark,
    );

    if (!decision.allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This export preset requires a premium export upgrade.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final device = await ref.read(deviceCapabilityProfileProvider.future);
    final qualityReport = const ExportQualityAdvisor().check(
      preset: preset,
      device: device,
    );

    if (qualityReport.hasIssues) {
      final shouldContinue = await _showQualityAdvisorDialog(qualityReport);
      if (!shouldContinue) return;
    }

    setState(() => _exportingPresetId = preset.id);
    try {
      await ref.read(nativeExportServiceProvider).startExport(
            projectId: widget.projectId,
            settings: preset.exportSettings,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${preset.name} export started.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed to start: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPresetId = null);
    }
  }

  Future<bool> _showQualityAdvisorDialog(ExportQualityReport report) async {
    if (!mounted) return false;
    final blocks = report.shouldStop;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text(blocks ? 'Export Not Recommended' : 'Export Quality Advisor'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: report.issues.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final issue = report.issues[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    issue.stop ? Icons.block_rounded : Icons.warning_amber_rounded,
                    color: issue.stop ? AppTheme.error : AppTheme.warning,
                  ),
                  title: Text(issue.title),
                  subtitle: Text(issue.message),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(blocks ? 'OK' : 'Cancel'),
            ),
            if (!blocks)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue Export'),
              ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _removePreset(String presetId) async {
    await ref.read(exportPresetStoreServiceProvider).deleteCustomPreset(
          projectId: widget.projectId,
          presetId: presetId,
        );
    ref.invalidate(projectExportPresetsProvider(widget.projectId));
  }
}

class _PresetHeader extends StatelessWidget {
  const _PresetHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune_rounded, color: AppTheme.accentPrimary),
            SizedBox(width: 10),
            Text(
              'Export Preset Builder',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Create reusable render settings for social platforms, 4K delivery, and custom workflows.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _BuilderCard extends StatelessWidget {
  final bool saving;
  final TextEditingController nameController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController bitrateController;
  final int frameRate;
  final String format;
  final String platform;
  final bool removeWatermark;
  final ValueChanged<int> onFrameRateChanged;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onPlatformChanged;
  final ValueChanged<bool> onWatermarkChanged;
  final VoidCallback onSave;

  const _BuilderCard({
    required this.saving,
    required this.nameController,
    required this.widthController,
    required this.heightController,
    required this.bitrateController,
    required this.frameRate,
    required this.format,
    required this.platform,
    required this.removeWatermark,
    required this.onFrameRateChanged,
    required this.onFormatChanged,
    required this.onPlatformChanged,
    required this.onWatermarkChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Preset name'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widthController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Width'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: frameRate,
                  decoration: const InputDecoration(labelText: 'FPS'),
                  items: const [24, 25, 30, 50, 60]
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value fps'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onFrameRateChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: bitrateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bitrate Mbps'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: platform,
                  decoration: const InputDecoration(labelText: 'Platform'),
                  items: const ['Custom', 'TikTok', 'Instagram', 'YouTube', 'Cinema']
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onPlatformChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: format,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: const ['mp4', 'mov']
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onFormatChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: removeWatermark,
            onChanged: onWatermarkChanged,
            title: const Text('Request watermark-free export'),
            subtitle: const Text('Premium rules are still checked before export.'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: const Icon(Icons.save_rounded),
              label: Text(saving ? 'Saving...' : 'Save Custom Preset'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final NleExportPresetSpec preset;
  final bool isExporting;
  final VoidCallback onUse;
  final VoidCallback? onRemove;

  const _PresetCard({
    required this.preset,
    required this.isExporting,
    required this.onUse,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                preset.isBuiltIn ? Icons.verified_rounded : Icons.tune_rounded,
                color: preset.isBuiltIn ? AppTheme.accentPrimary : AppTheme.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${preset.resolutionLabel} • ${preset.frameRateLabel} • ${preset.bitrateLabel} • ${preset.format.toUpperCase()}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preset.description,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove preset',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, color: AppTheme.error),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isExporting ? null : onUse,
              icon: const Icon(Icons.rocket_launch_rounded),
              label: Text(isExporting ? 'Starting export...' : 'Start Export'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCustomPresets extends StatelessWidget {
  const _EmptyCustomPresets();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: const Text(
        'No custom presets yet. Save one above to reuse it later.',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}
