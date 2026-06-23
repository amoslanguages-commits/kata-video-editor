import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/domain/text/text_style_model.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_section_card.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_slider_row.dart';

class InspectorTextSection extends StatefulWidget {
  final ClipInspectorState clip;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onStyleJsonChanged;

  const InspectorTextSection({
    super.key,
    required this.clip,
    required this.onTextChanged,
    required this.onColorChanged,
    required this.onStyleJsonChanged,
  });

  @override
  State<InspectorTextSection> createState() => _InspectorTextSectionState();
}

class _InspectorTextSectionState extends State<InspectorTextSection> {
  late TextEditingController _textController;

  static const List<String> _colors = [
    '#FFFFFF',
    '#000000',
    '#FFE600',
    '#00E5FF',
    '#FF5E5E',
    '#00FF66',
    '#D946EF',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.clip.textContent);
  }

  @override
  void didUpdateWidget(InspectorTextSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clip.clipId != oldWidget.clip.clipId) {
      _textController.text = widget.clip.textContent;
    } else if (widget.clip.textContent != _textController.text) {
      final selection = _textController.selection;
      _textController.text = widget.clip.textContent;
      try {
        _textController.selection = selection;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = NleTextStyle.fromJsonString(widget.clip.textStyleJson);

    return InspectorSectionCard(
      icon: Icons.title_rounded,
      title: 'Text Style',
      children: [
        TextField(
          controller: _textController,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Enter text...',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF101827),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderSubtle),
            ),
          ),
          onChanged: widget.onTextChanged,
        ),
        const SizedBox(height: 12),
        InspectorSliderRow(
          label: 'Size',
          value: style.fontSize,
          min: 10.0,
          max: 100.0,
          divisions: 90,
          onChanged: (val) {
            final nextStyle = style.copyWith(fontSize: val);
            widget.onStyleJsonChanged(nextStyle.toJsonString());
          },
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Color',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _colors.length,
            itemBuilder: (context, index) {
              final colorHex = _colors[index];
              final isSelected = widget.clip.colorHex?.toUpperCase() ==
                      colorHex.toUpperCase() ||
                  (widget.clip.colorHex == null && colorHex == '#FFFFFF');

              return GestureDetector(
                onTap: () {
                  widget.onColorChanged(colorHex);
                  final nextStyle = style.copyWith(color: colorHex);
                  widget.onStyleJsonChanged(nextStyle.toJsonString());
                },
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _parseHex(colorHex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: _parseHex(colorHex).computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _parseHex(String hex) {
    var hexClean = hex.replaceAll('#', '');
    if (hexClean.length == 6) {
      hexClean = 'FF$hexClean';
    }
    final val = int.tryParse(hexClean, radix: 16);
    if (val != null) {
      return Color(val);
    }
    return Colors.white;
  }
}
