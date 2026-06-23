import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/native_bridge/native_preview_texture_controller.dart';

class NativePreviewTexture extends StatefulWidget {
  final NativePreviewTextureController controller;
  final String fallbackLabel;

  const NativePreviewTexture({
    super.key,
    required this.controller,
    this.fallbackLabel = "Native Preview",
  });

  @override
  State<NativePreviewTexture> createState() => _NativePreviewTextureState();
}

class _NativePreviewTextureState extends State<NativePreviewTexture> {
  @override
  void initState() {
    super.initState();
    widget.controller.textureIdNotifier.addListener(_onTextureChanged);
  }

  @override
  void dispose() {
    widget.controller.textureIdNotifier.removeListener(_onTextureChanged);
    super.dispose();
  }

  void _onTextureChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textureId = widget.controller.textureId;

    if (defaultTargetPlatform == TargetPlatform.android && textureId != null) {
      return Texture(textureId: textureId);
    }

    // Fallback display for web, desktop, or before texture is ready
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: AppTheme.surfaceDark,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videogame_asset_outlined,
                color: AppTheme.accentPrimary,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                widget.fallbackLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                textureId != null
                    ? "Texture ID: $textureId (Mocked)"
                    : "Initializing Native Surface...",
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
