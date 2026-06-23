// lib/presentation/controllers/dual_preview_layout_controller.dart
//
// 29F: Controls which monitor is active in phone-portrait tab mode.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/domain/preview/preview_monitor.dart';

class DualPreviewLayoutState {
  final PreviewMonitor activeMonitor;

  const DualPreviewLayoutState({required this.activeMonitor});
  const DualPreviewLayoutState.initial() : activeMonitor = PreviewMonitor.program;

  DualPreviewLayoutState copyWith({PreviewMonitor? activeMonitor}) {
    return DualPreviewLayoutState(
      activeMonitor: activeMonitor ?? this.activeMonitor,
    );
  }
}

class DualPreviewLayoutController
    extends StateNotifier<DualPreviewLayoutState> {
  DualPreviewLayoutController()
      : super(const DualPreviewLayoutState.initial());

  void showSource()  => state = state.copyWith(activeMonitor: PreviewMonitor.source);
  void showProgram() => state = state.copyWith(activeMonitor: PreviewMonitor.program);
  void setActive(PreviewMonitor m) => state = state.copyWith(activeMonitor: m);
}
