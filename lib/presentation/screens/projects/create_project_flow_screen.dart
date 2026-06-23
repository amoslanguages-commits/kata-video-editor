import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/copy/app_copy.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/core/navigation/premium_page_route.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/screens/editor/editor_screen.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_button.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_card.dart';

class CreateProjectFlowScreen extends ConsumerStatefulWidget {
  const CreateProjectFlowScreen({
    super.key,
  });

  @override
  ConsumerState<CreateProjectFlowScreen> createState() =>
      _CreateProjectFlowScreenState();
}

class _CreateProjectFlowScreenState
    extends ConsumerState<CreateProjectFlowScreen> {
  final _nameController = TextEditingController();

  String _aspectRatio = '9:16';
  int _resolution = 1080;
  int _frameRate = 30;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Untitled Project';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(AppCopy.createProject),
      ),
      body: ListView(
        padding: const EdgeInsets.all(PremiumSpacing.lg),
        children: [
          PremiumCard(
            gradient: PremiumGradients.hero,
            glow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.movie_filter_rounded,
                  color: AppTheme.accentPrimary,
                  size: 38,
                ),
                SizedBox(height: PremiumSpacing.lg),
                Text(
                  AppCopy.createFirstProject,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: PremiumSpacing.sm),
                Text(
                  AppCopy.createProjectSubtitle,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.45,
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
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Project name',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                ),
                const SizedBox(height: PremiumSpacing.lg),
                _PresetSelector(
                  title: 'Aspect Ratio',
                  value: _aspectRatio,
                  options: const ['9:16', '16:9', '1:1', '4:5', '21:9'],
                  onChanged: (value) {
                    setState(() {
                      _aspectRatio = value;
                    });
                    ref.read(hapticServiceProvider).selection();
                  },
                ),
                const SizedBox(height: PremiumSpacing.md),
                _PresetSelector(
                  title: 'Resolution',
                  value: _resolution == 2160 ? '4K' : '${_resolution}p',
                  options: const ['720p', '1080p', '4K'],
                  onChanged: (value) {
                    setState(() {
                      if (value == '4K') {
                        _resolution = 2160;
                      } else {
                        _resolution = int.parse(value.replaceAll('p', ''));
                      }
                    });
                    ref.read(hapticServiceProvider).selection();
                  },
                ),
                const SizedBox(height: PremiumSpacing.md),
                _FrameRateSelector(
                  value: _frameRate,
                  onChanged: (value) {
                    setState(() => _frameRate = value);
                    ref.read(hapticServiceProvider).selection();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: PremiumSpacing.xl),
          PremiumButton(
            label: _creating ? 'Creating...' : AppCopy.createProject,
            icon: Icons.add_circle_rounded,
            expanded: true,
            loading: _creating,
            onPressed: _creating ? null : _createProject,
          ),
        ],
      ),
    );
  }

  Future<void> _createProject() async {
    setState(() => _creating = true);

    try {
      final projectId = await ref.read(projectServiceProvider).createProject(
            name: _nameController.text.trim().isEmpty
                ? 'Untitled Project'
                : _nameController.text.trim(),
            aspectRatio: _aspectRatio,
            resolution: _resolution,
            frameRate: _frameRate,
          );

      await ref.read(hapticServiceProvider).success();

      if (!mounted) return;

      ref.read(selectedProjectIdProvider.notifier).state = projectId;
      await ref.read(editorStateProvider.notifier).loadProject(projectId);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PremiumPageRoute(
          page: const EditorScreen(),
        ),
      );
    } catch (e) {
      await ref.read(hapticServiceProvider).warning();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create project: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }
}

class _PresetSelector extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _PresetSelector({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: PremiumSpacing.sm),
        Wrap(
          spacing: PremiumSpacing.sm,
          runSpacing: PremiumSpacing.sm,
          children: [
            for (final option in options)
              ChoiceChip(
                selected: value == option,
                label: Text(option),
                onSelected: (_) => onChanged(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _FrameRateSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _FrameRateSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _PresetSelector(
      title: 'Frame Rate',
      value: '${value}fps',
      options: const ['24fps', '30fps', '60fps'],
      onChanged: (option) {
        onChanged(int.parse(option.replaceAll('fps', '')));
      },
    );
  }
}
