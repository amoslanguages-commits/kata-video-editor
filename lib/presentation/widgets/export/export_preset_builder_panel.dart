import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/export/export_filename_builder.dart';
import 'package:nle_editor/domain/export/export_filename_versioner.dart';
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
  String _filenamePattern = ExportFilenamePatterns.defaultPattern;
  bool _removeWatermark = false;
  bool _saving = false;
  String? _exportingPresetId;
  String? _editingPresetId;
  DateTime? _editingCreatedAt;

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

          return FutureBuilder(
            future: ref.read(projectRepositoryProvider).getProject(widget.projectId),
            builder: (context, snapshot) {
              final projectName = snapshot.data?.name ?? 'Project';
              final draftPreset = _draftPreset();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _PresetHeader(),
                  const SizedBox(height: 14),
                  _BuilderCard(
                    saving: _saving,
                    editing: _editingPresetId != null,
                    nameController: _nameController,
                    widthController: _widthController,
                    heightController: _heightController,
                    bitrateController: _bitrateController,
                    frameRate: _frameRate,
                    format: _format,
                    platform: _platform,
                    filenamePattern: _filenamePattern,
                    removeWatermark: _removeWatermark,
                    sizePreviewLabel: _estimateSizeLabel(snapshot.data?.durationMicros),
                    watermarkLabel: _watermarkLabel(),
                    draftFileName: _buildOutputFileName(draftPreset, projectName, pattern: _filenamePattern),
                    onFrameRateChanged: (value) => setState(() => _frameRate = value),
                    onFormatChanged: (value) => setState(() => _format = value),
                    onPlatformChanged: (value) => setState(() => _platform = value),
                    onFilenamePatternChanged: (value) => setState(() => _filenamePattern = value),
                    onWatermarkChanged: (value) => setState(() => _removeWatermark = value),
                    onSave: _savePreset,
                    onClearEdit: _clearEditMode,
                    onExportJson: _exportCustomPresetsJson,
                    onImportJson: _showImportPresetDialog,
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Built-in Platform Presets'),
                  const SizedBox(height: 10),
                  ...builtIn.map(
                    (preset) => _PresetCard(
                      preset: preset,
                      previewFileName: _buildOutputFileName(preset, projectName),
                      isExporting: _exportingPresetId == preset.id,
                      onUse: () => _startExportWithPreset(preset),
                      onClone: () => _clonePreset(preset),
                      onTest: () => _startTestExportFoundation(preset),
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
                        previewFileName: _buildOutputFileName(preset, projectName),
                        isExporting: _exportingPresetId == preset.id,
                        onUse: () => _startExportWithPreset(preset),
                        onEdit: () => _loadPresetForEdit(preset),
                        onClone: () => _clonePreset(preset),
                        onTest: () => _startTestExportFoundation(preset),
                        onRemove: () => _confirmRemovePreset(preset),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  NleExportPresetSpec _draftPreset() {
    final now = DateTime.now();
    return NleExportPresetSpec(
      id: _editingPresetId ?? 'draft',
      name: _nameController.text.trim().isEmpty ? 'Draft Preset' : _nameController.text.trim(),
      description: 'Draft export preset.',
      platform: _platform,
      width: int.tryParse(_widthController.text.trim()) ?? 1080,
      height: int.tryParse(_heightController.text.trim()) ?? 1920,
      frameRate: _frameRate,
      bitrateMbps: int.tryParse(_bitrateController.text.trim()) ?? 12,
      format: _format,
      removeWatermark: _removeWatermark,
      isBuiltIn: false,
      createdAt: _editingCreatedAt ?? now,
      updatedAt: now,
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
      id: _editingPresetId ?? 'custom_${_uuid.v4()}',
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
      createdAt: _editingCreatedAt ?? now,
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
          SnackBar(content: Text(_editingPresetId == null ? 'Export preset saved.' : 'Export preset updated.')),
        );
      }
      _clearEditMode();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clonePreset(NleExportPresetSpec source) async {
    final now = DateTime.now();
    final clonedName = '${source.name} Copy';
    final clone = source.copyWith(
      id: 'custom_${_uuid.v4()}',
      name: clonedName,
      description: 'Custom copy of ${source.name}.',
      isBuiltIn: false,
      createdAt: now,
      updatedAt: now,
    );

    setState(() {
      _nameController.text = clonedName;
      _widthController.text = source.width.toString();
      _heightController.text = source.height.toString();
      _bitrateController.text = source.bitrateMbps.toString();
      _frameRate = source.frameRate;
      _format = source.format;
      _platform = source.platform;
      _removeWatermark = source.removeWatermark;
      _editingPresetId = clone.id;
      _editingCreatedAt = clone.createdAt;
    });

    await ref.read(exportPresetStoreServiceProvider).saveCustomPreset(
          projectId: widget.projectId,
          preset: clone,
        );
    ref.invalidate(projectExportPresetsProvider(widget.projectId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloned ${source.name} into custom presets.')),
      );
    }
  }

  void _loadPresetForEdit(NleExportPresetSpec preset) {
    setState(() {
      _editingPresetId = preset.id;
      _editingCreatedAt = preset.createdAt;
      _nameController.text = preset.name;
      _widthController.text = preset.width.toString();
      _heightController.text = preset.height.toString();
      _bitrateController.text = preset.bitrateMbps.toString();
      _frameRate = preset.frameRate;
      _format = preset.format;
      _platform = preset.platform;
      _removeWatermark = preset.removeWatermark;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${preset.name}.')),
    );
  }

  void _clearEditMode() {
    if (!mounted) return;
    setState(() {
      _editingPresetId = null;
      _editingCreatedAt = null;
      _nameController.text = 'My Export Preset';
      _widthController.text = '1080';
      _heightController.text = '1920';
      _bitrateController.text = '12';
      _frameRate = 30;
      _format = 'mp4';
      _platform = 'Custom';
      _filenamePattern = ExportFilenamePatterns.defaultPattern;
      _removeWatermark = false;
    });
  }

  Future<void> _confirmRemovePreset(NleExportPresetSpec preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Custom Preset?'),
        content: Text('Delete "${preset.name}" from your custom export presets?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _removePreset(preset.id);
  }

  Future<void> _exportCustomPresetsJson() async {
    final custom = await ref.read(exportPresetStoreServiceProvider).loadCustomPresets(widget.projectId);
    final text = const JsonEncoder.withIndent('  ').convert(custom.map((item) => item.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom presets JSON copied.')),
      );
    }
  }

  Future<void> _showImportPresetDialog() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Import Preset JSON'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste preset JSON array here',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(text);
      final items = decoded is List ? decoded : [decoded];
      var count = 0;
      for (final item in items) {
        if (item is Map) {
          final mapped = item.map((key, value) => MapEntry(key.toString(), value));
          final preset = NleExportPresetSpec.fromJson(mapped).copyWith(isBuiltIn: false);
          await ref.read(exportPresetStoreServiceProvider).saveCustomPreset(
                projectId: widget.projectId,
                preset: preset,
              );
          count++;
        }
      }
      ref.invalidate(projectExportPresetsProvider(widget.projectId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count preset(s).')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $error'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _startTestExportFoundation(NleExportPresetSpec preset) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('5-second test export ready for ${preset.name}. Native trim hook can connect here.')),
    );
  }

  String _estimateSizeLabel(int? durationMicros) {
    final bitrate = int.tryParse(_bitrateController.text.trim()) ?? 0;
    if (durationMicros == null || durationMicros <= 0 || bitrate <= 0) return 'Size estimate unavailable';
    final seconds = durationMicros / 1000000.0;
    final bytes = seconds * bitrate * 1000000 / 8 * 1.18;
    const gb = 1024 * 1024 * 1024;
    const mb = 1024 * 1024;
    if (bytes >= gb) return 'Estimated output: ${(bytes / gb).toStringAsFixed(1)} GB';
    return 'Estimated output: ${(bytes / mb).ceil()} MB';
  }

  String _watermarkLabel() {
    return _removeWatermark
        ? 'Watermark-free export requested. Premium rules apply.'
        : 'Watermark will remain for free exports.';
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
    final project = await ref.read(projectRepositoryProvider).getProject(widget.projectId);
    final qualityReport = const ExportQualityAdvisor().check(
      preset: preset,
      device: device,
      durationMicros: project?.durationMicros,
    );

    if (qualityReport.hasIssues) {
      final shouldContinue = await _showQualityAdvisorDialog(qualityReport);
      if (!shouldContinue) return;
    }

    final projectName = project?.name ?? 'Project';
    final previewFileName = _buildOutputFileName(preset, projectName, pattern: _filenamePattern);
    final folders = await ref.read(projectStorageServiceProvider).getProjectFolders(widget.projectId);
    final finalOutputPath = await const ExportFilenameVersioner().uniquePath(
      directoryPath: folders.exports,
      fileName: previewFileName,
    );
    final finalOutputFileName = p.basename(finalOutputPath);

    if (finalOutputFileName != previewFileName) {
      final shouldContinue = await _showFilenameConflictDialog(
        requestedName: previewFileName,
        finalName: finalOutputFileName,
      );
      if (!shouldContinue) return;
    }

    final settings = {
      ...preset.exportSettings,
      'presetName': preset.name,
      'filenamePattern': _filenamePattern,
      'outputFileName': finalOutputFileName,
    };

    setState(() => _exportingPresetId = preset.id);
    try {
      await ref.read(nativeExportServiceProvider).startExport(
            projectId: widget.projectId,
            settings: settings,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${preset.name} export started: $finalOutputFileName')),
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

  String _buildOutputFileName(
    NleExportPresetSpec preset,
    String projectName, {
    String pattern = ExportFilenamePatterns.defaultPattern,
  }) {
    return const ExportFilenameBuilder().build(
      pattern: pattern,
      projectName: projectName,
      presetName: preset.name,
      platform: preset.platform,
      resolution: preset.resolutionLabel,
      extension: preset.format,
      version: (DateTime.now().millisecondsSinceEpoch % 99) + 1,
    );
  }

  Future<bool> _showFilenameConflictDialog({
    required String requestedName,
    required String finalName,
  }) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Filename Already Exists'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'An export with this filename already exists. The new export will be saved as a versioned file.',
              ),
              const SizedBox(height: 12),
              _ConflictName(label: 'Requested', value: requestedName),
              _ConflictName(label: 'New file', value: finalName),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return result ?? false;
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
  final bool editing;
  final TextEditingController nameController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController bitrateController;
  final int frameRate;
  final String format;
  final String platform;
  final String filenamePattern;
  final bool removeWatermark;
  final String sizePreviewLabel;
  final String watermarkLabel;
  final String draftFileName;
  final ValueChanged<int> onFrameRateChanged;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onPlatformChanged;
  final ValueChanged<String> onFilenamePatternChanged;
  final ValueChanged<bool> onWatermarkChanged;
  final VoidCallback onSave;
  final VoidCallback onClearEdit;
  final VoidCallback onExportJson;
  final VoidCallback onImportJson;

  const _BuilderCard({
    required this.saving,
    required this.editing,
    required this.nameController,
    required this.widthController,
    required this.heightController,
    required this.bitrateController,
    required this.frameRate,
    required this.format,
    required this.platform,
    required this.filenamePattern,
    required this.removeWatermark,
    required this.sizePreviewLabel,
    required this.watermarkLabel,
    required this.draftFileName,
    required this.onFrameRateChanged,
    required this.onFormatChanged,
    required this.onPlatformChanged,
    required this.onFilenamePatternChanged,
    required this.onWatermarkChanged,
    required this.onSave,
    required this.onClearEdit,
    required this.onExportJson,
    required this.onImportJson,
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
          if (editing) ...[
            Row(
              children: [
                const Icon(Icons.edit_rounded, color: AppTheme.warning, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Editing custom preset',
                    style: TextStyle(color: AppTheme.warning, fontSize: 12),
                  ),
                ),
                TextButton(onPressed: onClearEdit, child: const Text('New')),
              ],
            ),
            const SizedBox(height: 8),
          ],
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
                  items: const ['Custom', 'TikTok', 'Instagram', 'YouTube', 'Cinema', 'Short-form']
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
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: filenamePattern,
            decoration: const InputDecoration(labelText: 'Filename pattern'),
            items: const [
              ExportFilenamePatterns.defaultPattern,
              ExportFilenamePatterns.projectDate,
              ExportFilenamePatterns.projectPresetVersion,
              ExportFilenamePatterns.platformReady,
            ]
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) {
              if (value != null) onFilenamePatternChanged(value);
            },
          ),
          const SizedBox(height: 8),
          _InfoLine(icon: Icons.insert_drive_file_rounded, text: draftFileName),
          _InfoLine(icon: Icons.sd_storage_rounded, text: sizePreviewLabel),
          _InfoLine(icon: Icons.branding_watermark_rounded, text: watermarkLabel),
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
              icon: Icon(editing ? Icons.update_rounded : Icons.save_rounded),
              label: Text(saving ? 'Saving...' : editing ? 'Update Custom Preset' : 'Save Custom Preset'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExportJson,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Export JSON'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onImportJson,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Import JSON'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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

class _ConflictName extends StatelessWidget {
  final String label;
  final String value;

  const _ConflictName({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final NleExportPresetSpec preset;
  final String previewFileName;
  final bool isExporting;
  final VoidCallback onUse;
  final VoidCallback? onEdit;
  final VoidCallback? onClone;
  final VoidCallback? onTest;
  final VoidCallback? onRemove;

  const _PresetCard({
    required this.preset,
    required this.previewFileName,
    required this.isExporting,
    required this.onUse,
    this.onEdit,
    this.onClone,
    this.onTest,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = onEdit != null;
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
                  tooltip: 'Delete preset',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, color: AppTheme.error),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_rounded, color: AppTheme.textMuted, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    previewFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (isCustom)
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit'),
                ),
              if (onClone != null)
                OutlinedButton.icon(
                  onPressed: onClone,
                  icon: const Icon(Icons.copy_all_rounded),
                  label: Text(isCustom ? 'Duplicate' : 'Clone'),
                ),
              if (onTest != null)
                OutlinedButton.icon(
                  onPressed: onTest,
                  icon: const Icon(Icons.timer_rounded),
                  label: const Text('Test 5s'),
                ),
              ElevatedButton.icon(
                onPressed: isExporting ? null : onUse,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text(isExporting ? 'Starting...' : 'Export'),
              ),
            ],
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
        'No custom presets yet. Clone a built-in preset or save one above.',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}
