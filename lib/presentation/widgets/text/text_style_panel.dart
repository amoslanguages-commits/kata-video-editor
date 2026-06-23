import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/text/text_style_model.dart';
import 'package:nle_editor/domain/text/text_style_presets.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class TextStylePanel extends ConsumerStatefulWidget {
  final Clip clip;
  const TextStylePanel({super.key, required this.clip});

  @override
  ConsumerState<TextStylePanel> createState() => _TextStylePanelState();
}

class _TextStylePanelState extends ConsumerState<TextStylePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _textController;

  static const List<String> _colors = [
    '#FFFFFF',
    '#000000',
    '#FFE600',
    '#F6E7C1',
    '#F7D36B',
    '#00E5FF',
    '#FF5E5E',
    '#00FF66',
    '#D946EF',
    '#94A3B8',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _textController =
        TextEditingController(text: widget.clip.textContent ?? '');
  }

  @override
  void didUpdateWidget(TextStylePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clip.id != oldWidget.clip.id) {
      _textController.text = widget.clip.textContent ?? '';
    } else if (widget.clip.textContent != _textController.text) {
      final selection = _textController.selection;
      _textController.text = widget.clip.textContent ?? '';
      try {
        _textController.selection = selection;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex, [double opacity = 1.0]) {
    var hexClean = hex.replaceAll('#', '');
    if (hexClean.length == 6) {
      hexClean = 'FF$hexClean';
    }
    final val = int.tryParse(hexClean, radix: 16);
    if (val != null) {
      return Color(val).withValues(alpha: opacity);
    }
    return Colors.white.withValues(alpha: opacity);
  }

  void _updateStyle(NleTextStyle style) {
    ref.read(textStyleCommandServiceProvider).updateTextStyle(
          projectId: widget.clip.projectId,
          clipId: widget.clip.id,
          style: style,
        );
  }

  @override
  Widget build(BuildContext context) {
    final style = NleTextStyle.fromJsonString(widget.clip.textStyle);
    final userPresetsAsync = ref.watch(localTextPresetsProvider);

    return Container(
      color: AppTheme.surfaceDark,
      child: Column(
        children: [
          // Header / Text input area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Enter text content...',
                        hintStyle:
                            TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (text) {
                        ref
                            .read(textStyleCommandServiceProvider)
                            .updateTextContent(
                              projectId: widget.clip.projectId,
                              clipId: widget.clip.id,
                              content: text,
                            );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                  tooltip: 'Save Style Preset',
                  onPressed: () => _showSavePresetDialog(context),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accentPrimary,
            labelColor: AppTheme.accentPrimary,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Presets'),
              Tab(text: 'Text & Font'),
              Tab(text: 'Stroke & Shadow'),
              Tab(text: 'Background & Layout'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Presets tab
                _buildPresetsTab(userPresetsAsync),

                // Text & Font tab
                _buildTextFontTab(style),

                // Stroke & Shadow tab
                _buildStrokeShadowTab(style),

                // Background & Layout tab
                _buildBackgroundLayoutTab(style),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Presets Tab ────────────────────────────────────────────────────────────
  Widget _buildPresetsTab(AsyncValue<List<LocalTextPreset>> userPresetsAsync) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Built-In Premium Styles',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: BuiltInTextStylePresets.all.length,
            itemBuilder: (context, index) {
              final preset = BuiltInTextStylePresets.all[index];
              return _buildPresetTile(
                name: preset.name,
                isPremium: preset.isPremium,
                style: preset.style,
                onTap: () {
                  ref.read(textStyleCommandServiceProvider).applyBuiltInPreset(
                        projectId: widget.clip.projectId,
                        clipId: widget.clip.id,
                        presetId: preset.id,
                      );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'My Custom Styles',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        userPresetsAsync.when(
          data: (presets) {
            final customPresets = presets.where((p) => !p.isBuiltIn).toList();
            if (customPresets.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: const Text(
                  'No custom presets saved yet.\nCreate a design and tap the bookmark icon above to save.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 11, height: 1.4),
                ),
              );
            }

            return SizedBox(
              height: 85,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: customPresets.length,
                itemBuilder: (context, index) {
                  final preset = customPresets[index];
                  final presetStyle =
                      NleTextStyle.fromJsonString(preset.styleJson);
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildPresetTile(
                          name: preset.name,
                          isPremium: preset.isPremium,
                          style: presetStyle,
                          onTap: () {
                            ref
                                .read(textStyleCommandServiceProvider)
                                .applyLocalPreset(
                                  projectId: widget.clip.projectId,
                                  clipId: widget.clip.id,
                                  presetId: preset.id,
                                );
                          },
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: InkWell(
                          onTap: () => _confirmDeletePreset(
                              context, preset.id, preset.name),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.surfaceOverlay,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 10, color: AppTheme.error),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 70,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 70,
            child: Center(
                child: Text('Error loading presets: $e',
                    style: const TextStyle(fontSize: 11))),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetTile({
    required String name,
    required bool isPremium,
    required NleTextStyle style,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        clipBehavior: ui.Clip.antiAlias,
        child: Stack(
          children: [
            Center(
              child: Stack(
                children: [
                  if (style.strokeWidth > 0)
                    Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: _getFontWeight(style.fontWeight),
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = style.strokeWidth * 0.5
                          ..color = _parseHex(style.strokeColor),
                      ),
                    ),
                  Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: _getFontWeight(style.fontWeight),
                      color: _parseHex(style.color),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
              ),
            ),
            if (isPremium)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Text & Font Tab ────────────────────────────────────────────────────────
  Widget _buildTextFontTab(NleTextStyle style) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Font size slider
        _buildSliderRow(
          label: 'Font Size',
          value: style.fontSize,
          min: 10.0,
          max: 100.0,
          onChanged: (v) => _updateStyle(style.copyWith(fontSize: v)),
        ),

        // Font Weight dropdown
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Font Weight',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              DropdownButton<int>(
                value: style.fontWeight,
                dropdownColor: AppTheme.surfaceElevated,
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 300, child: Text('Light')),
                  DropdownMenuItem(value: 400, child: Text('Regular')),
                  DropdownMenuItem(value: 600, child: Text('Semi Bold')),
                  DropdownMenuItem(value: 700, child: Text('Bold')),
                  DropdownMenuItem(value: 800, child: Text('Extra Bold')),
                  DropdownMenuItem(value: 900, child: Text('Black')),
                ],
                onChanged: (w) {
                  if (w != null) {
                    _updateStyle(style.copyWith(fontWeight: w));
                  }
                },
              ),
            ],
          ),
        ),

        // Color selector
        const Text(
          'Text Color',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        _buildColorSelectorRow(
          selectedColor: style.color,
          onColorSelected: (c) => _updateStyle(style.copyWith(color: c)),
        ),

        const SizedBox(height: 12),
        // Font Family dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Font Family',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            DropdownButton<String>(
              value: style.fontFamily,
              dropdownColor: AppTheme.surfaceElevated,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System Font')),
                DropdownMenuItem(value: 'monospace', child: Text('Monospace')),
                DropdownMenuItem(value: 'serif', child: Text('Serif')),
                DropdownMenuItem(
                    value: 'sans-serif', child: Text('Sans-Serif')),
              ],
              onChanged: (f) {
                if (f != null) {
                  _updateStyle(style.copyWith(fontFamily: f));
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 12),
        // Alignment selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Alignment',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Row(
              children: [
                _buildAlignButton(
                  icon: Icons.format_align_left_rounded,
                  isSelected: style.alignment == TextAlignmentOption.left,
                  onTap: () => _updateStyle(
                      style.copyWith(alignment: TextAlignmentOption.left)),
                ),
                const SizedBox(width: 4),
                _buildAlignButton(
                  icon: Icons.format_align_center_rounded,
                  isSelected: style.alignment == TextAlignmentOption.center,
                  onTap: () => _updateStyle(
                      style.copyWith(alignment: TextAlignmentOption.center)),
                ),
                const SizedBox(width: 4),
                _buildAlignButton(
                  icon: Icons.format_align_right_rounded,
                  isSelected: style.alignment == TextAlignmentOption.right,
                  onTap: () => _updateStyle(
                      style.copyWith(alignment: TextAlignmentOption.right)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPrimary : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.black : AppTheme.textSecondary,
        ),
      ),
    );
  }

  // ─── Stroke & Shadow Tab ────────────────────────────────────────────────────
  Widget _buildStrokeShadowTab(NleTextStyle style) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Stroke width slider
        _buildSliderRow(
          label: 'Stroke Width',
          value: style.strokeWidth,
          min: 0.0,
          max: 10.0,
          onChanged: (v) => _updateStyle(style.copyWith(strokeWidth: v)),
        ),

        if (style.strokeWidth > 0) ...[
          const Text(
            'Stroke Color',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          _buildColorSelectorRow(
            selectedColor: style.strokeColor,
            onColorSelected: (c) =>
                _updateStyle(style.copyWith(strokeColor: c)),
          ),
          const SizedBox(height: 16),
        ],

        // Shadow Toggle
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            title: const Text(
              'Drop Shadow',
              style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
            ),
            value: style.shadowEnabled,
            activeThumbColor: AppTheme.accentPrimary,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => _updateStyle(style.copyWith(shadowEnabled: v)),
          ),
        ),

        if (style.shadowEnabled) ...[
          const Text(
            'Shadow Color',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          _buildColorSelectorRow(
            selectedColor: style.shadowColor,
            onColorSelected: (c) =>
                _updateStyle(style.copyWith(shadowColor: c)),
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            label: 'Shadow Blur',
            value: style.shadowBlur,
            min: 0.0,
            max: 30.0,
            onChanged: (v) => _updateStyle(style.copyWith(shadowBlur: v)),
          ),
          _buildSliderRow(
            label: 'Offset X',
            value: style.shadowOffsetX,
            min: -15.0,
            max: 15.0,
            onChanged: (v) => _updateStyle(style.copyWith(shadowOffsetX: v)),
          ),
          _buildSliderRow(
            label: 'Offset Y',
            value: style.shadowOffsetY,
            min: -15.0,
            max: 15.0,
            onChanged: (v) => _updateStyle(style.copyWith(shadowOffsetY: v)),
          ),
        ],
      ],
    );
  }

  // ─── Background & Layout Tab ────────────────────────────────────────────────
  Widget _buildBackgroundLayoutTab(NleTextStyle style) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Background Toggle
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            title: const Text(
              'Text Background Box',
              style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
            ),
            value: style.backgroundEnabled,
            activeThumbColor: AppTheme.accentPrimary,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) =>
                _updateStyle(style.copyWith(backgroundEnabled: v)),
          ),
        ),

        if (style.backgroundEnabled) ...[
          const Text(
            'Background Color',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          _buildColorSelectorRow(
            selectedColor: style.backgroundColor,
            onColorSelected: (c) =>
                _updateStyle(style.copyWith(backgroundColor: c)),
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            label: 'Background Opacity',
            value: style.backgroundOpacity,
            min: 0.0,
            max: 1.0,
            onChanged: (v) =>
                _updateStyle(style.copyWith(backgroundOpacity: v)),
          ),
          _buildSliderRow(
            label: 'Box Padding',
            value: style.backgroundPadding,
            min: 0.0,
            max: 30.0,
            onChanged: (v) =>
                _updateStyle(style.copyWith(backgroundPadding: v)),
          ),
          _buildSliderRow(
            label: 'Corner Radius',
            value: style.backgroundRadius,
            min: 0.0,
            max: 30.0,
            onChanged: (v) => _updateStyle(style.copyWith(backgroundRadius: v)),
          ),
          const SizedBox(height: 12),
        ],

        // Spacing settings
        _buildSliderRow(
          label: 'Letter Spacing',
          value: style.letterSpacing,
          min: -5.0,
          max: 15.0,
          onChanged: (v) => _updateStyle(style.copyWith(letterSpacing: v)),
        ),
        _buildSliderRow(
          label: 'Line Spacing',
          value: style.lineSpacing,
          min: 0.5,
          max: 3.0,
          onChanged: (v) => _updateStyle(style.copyWith(lineSpacing: v)),
        ),

        const Divider(height: 24),

        // Text Animation dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Intro Animation',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            DropdownButton<String>(
              value: style.animation,
              dropdownColor: AppTheme.surfaceElevated,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                    value: TextAnimationType.none,
                    child: Text('None (Static)')),
                DropdownMenuItem(
                    value: TextAnimationType.fade, child: Text('Fade In')),
                DropdownMenuItem(
                    value: TextAnimationType.pop, child: Text('Pop Zoom')),
                DropdownMenuItem(
                    value: TextAnimationType.slideUp, child: Text('Slide Up')),
                DropdownMenuItem(
                    value: TextAnimationType.typewriter,
                    child: Text('Typewriter')),
                DropdownMenuItem(
                    value: TextAnimationType.karaoke,
                    child: Text('Karaoke Sync')),
              ],
              onChanged: (anim) {
                if (anim != null) {
                  _updateStyle(style.copyWith(animation: anim));
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // ─── Helpers & Custom Controls ──────────────────────────────────────────────
  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: AppTheme.accentPrimary,
              inactiveTrackColor: AppTheme.surfaceOverlay,
              thumbColor: AppTheme.accentPrimary,
              overlayColor: AppTheme.accentPrimary.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelectorRow({
    required String selectedColor,
    required ValueChanged<String> onColorSelected,
  }) {
    return SizedBox(
      height: 28,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        itemBuilder: (context, index) {
          final cHex = _colors[index];
          final color = _parseHex(cHex);
          final isSelected = selectedColor.toUpperCase() == cHex.toUpperCase();

          return GestureDetector(
            onTap: () => onColorSelected(cHex),
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentPrimary
                      : AppTheme.borderSubtle,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  FontWeight _getFontWeight(int weight) {
    if (weight >= 900) return FontWeight.w900;
    if (weight >= 800) return FontWeight.w800;
    if (weight >= 700) return FontWeight.w700;
    if (weight >= 600) return FontWeight.w600;
    if (weight >= 500) return FontWeight.w500;
    if (weight >= 400) return FontWeight.w400;
    if (weight >= 300) return FontWeight.w300;
    return FontWeight.normal;
  }

  void _showSavePresetDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Custom Style',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceDark,
        surfaceTintColor: Colors.transparent,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Give this style configuration a custom name so you can reuse it later.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'My Preset Name',
                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.borderSubtle)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.accentPrimary)),
              ),
              style: const TextStyle(fontSize: 13),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: AppTheme.accentPrimary,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await ref
                    .read(textStyleCommandServiceProvider)
                    .saveCurrentStyleAsPreset(
                      name: name,
                      category: 'Custom',
                      clip: widget.clip,
                    );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Style "$name" saved successfully!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePreset(
      BuildContext context, String presetId, String presetName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Preset',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceDark,
        surfaceTintColor: Colors.transparent,
        content: Text(
          'Are you sure you want to permanently delete style preset "$presetName"?',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref
                  .read(textStyleCommandServiceProvider)
                  .deleteLocalPreset(presetId);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Style preset deleted.'),
                    backgroundColor: AppTheme.surfaceOverlay,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
