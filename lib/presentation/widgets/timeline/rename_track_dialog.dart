import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';

class RenameTrackDialog extends StatefulWidget {
  final MultitrackTrack track;

  const RenameTrackDialog({
    super.key,
    required this.track,
  });

  static Future<String?> show(
    BuildContext context, {
    required MultitrackTrack track,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameTrackDialog(track: track),
    );
  }

  @override
  State<RenameTrackDialog> createState() => _RenameTrackDialogState();
}

class _RenameTrackDialogState extends State<RenameTrackDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.track.name,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _error = 'Track name cannot be empty.';
      });
      return;
    }

    if (name.length > 40) {
      setState(() {
        _error = 'Track name is too long.';
      });
      return;
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PremiumRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(PremiumSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.track.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rename ${widget.track.label}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PremiumSpacing.lg),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 40,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  labelText: 'Track name',
                  errorText: _error,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PremiumRadius.md),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: PremiumSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
