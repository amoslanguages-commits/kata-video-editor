// lib/presentation/providers/dual_preview_layout_providers.dart
//
// 29F: Global layout provider for dual-monitor mode.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/presentation/controllers/dual_preview_layout_controller.dart';

final dualPreviewLayoutControllerProvider = StateNotifierProvider<
    DualPreviewLayoutController,
    DualPreviewLayoutState>((ref) {
  return DualPreviewLayoutController();
});
