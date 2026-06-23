import 'package:flutter/material.dart';

import 'package:nle_editor/presentation/widgets/preview/real_native_preview_surface.dart';

class NativeTruePreviewView extends StatelessWidget {
  final String projectId;

  const NativeTruePreviewView({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return RealNativePreviewSurface(projectId: projectId);
  }
}
