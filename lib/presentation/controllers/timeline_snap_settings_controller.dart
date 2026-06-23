import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/timeline/timeline_snap_models.dart';

class TimelineSnapSettingsController extends StateNotifier<TimelineSnapSettings> {
  TimelineSnapSettingsController() : super(const TimelineSnapSettings());

  void setEnabled(bool enabled) {
    state = state.copyWith(enabled: enabled);
  }

  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }

  void setThresholdPx(double thresholdPx) {
    state = state.copyWith(
      thresholdPx: thresholdPx.clamp(4.0, 32.0),
    );
  }

  void togglePlayheadSnap() {
    state = state.copyWith(
      snapToPlayhead: !state.snapToPlayhead,
    );
  }

  void toggleClipEdgeSnap() {
    state = state.copyWith(
      snapToClipEdges: !state.snapToClipEdges,
    );
  }

  void toggleTimelineZeroSnap() {
    state = state.copyWith(
      snapToTimelineZero: !state.snapToTimelineZero,
    );
  }

  void toggleMarkerSnap() {
    state = state.copyWith(
      snapToMarkers: !state.snapToMarkers,
    );
  }
}
