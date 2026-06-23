import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/constants/app_constants.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/screens/editor/editor_screen.dart';

class NewProjectScreen extends ConsumerStatefulWidget {
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  final _nameController = TextEditingController(text: 'Untitled Project');
  String _selectedAspectRatio = '16:9';
  int _selectedFrameRate = 30;
  int _selectedResolution = 1080;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(appSettingsProvider).valueOrNull;
      if (settings != null) {
        setState(() {
          _selectedAspectRatio = settings.defaultAspectRatio;
          _selectedFrameRate = settings.defaultFrameRate;
          _selectedResolution = settings.defaultResolutionHeight;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('New Project'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Project Name'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                  borderSide: const BorderSide(color: AppTheme.accentPrimary),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Aspect Ratio'),
            const SizedBox(height: 12),
            _buildAspectRatioSelector(),
            const SizedBox(height: 32),
            _buildSectionTitle('Frame Rate'),
            const SizedBox(height: 12),
            _buildFrameRateSelector(),
            const SizedBox(height: 32),
            _buildSectionTitle('Resolution'),
            const SizedBox(height: 12),
            _buildResolutionSelector(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createProject,
                child: _isCreating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Create Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAspectRatioSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppConstants.aspectRatios.map((ratio) {
        final isSelected = ratio == _selectedAspectRatio;
        final label = AppConstants.aspectRatioLabels[ratio] ?? ratio;

        return GestureDetector(
          onTap: () => setState(() => _selectedAspectRatio = ratio),
          child: Container(
            width: 100,
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                  : AppTheme.surfaceElevated,
              borderRadius:
                  BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.borderSubtle,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentPrimary
                        : AppTheme.surfaceOverlay,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      ratio,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? AppTheme.accentPrimary
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrameRateSelector() {
    return Wrap(
      spacing: 12,
      children: AppConstants.frameRates.map((fps) {
        final isSelected = fps == _selectedFrameRate;
        return GestureDetector(
          onTap: () => setState(() => _selectedFrameRate = fps),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                  : AppTheme.surfaceElevated,
              borderRadius:
                  BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.borderSubtle,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Text(
              '$fps fps',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResolutionSelector() {
    return Wrap(
      spacing: 12,
      children: AppConstants.resolutions.map((res) {
        final isSelected = res == _selectedResolution;
        final label = res >= 2160 ? '4K' : '${res}p';
        return GestureDetector(
          onTap: () => setState(() => _selectedResolution = res),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                  : AppTheme.surfaceElevated,
              borderRadius:
                  BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.borderSubtle,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _createProject() async {
    setState(() => _isCreating = true);

    try {
      final projectId = await ref.read(projectServiceProvider).createProject(
            name: _nameController.text.trim(),
            aspectRatio: _selectedAspectRatio,
            resolution: _selectedResolution,
            frameRate: _selectedFrameRate,
          );

      if (mounted) {
        ref.read(selectedProjectIdProvider.notifier).state = projectId;
        await ref
            .read(editorStateProvider.notifier)
            .loadProject(projectId);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const EditorScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create project: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
