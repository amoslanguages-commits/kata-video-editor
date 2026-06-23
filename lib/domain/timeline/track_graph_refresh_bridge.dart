typedef InvalidateTimelineCallback = void Function(String projectId);
typedef NativeTrackGraphRefreshCallback = Future<void> Function(
  String projectId,
  String reason,
);

class TrackGraphRefreshBridge {
  final InvalidateTimelineCallback invalidateTimeline;
  final NativeTrackGraphRefreshCallback? refreshNativeGraph;

  const TrackGraphRefreshBridge({
    required this.invalidateTimeline,
    this.refreshNativeGraph,
  });

  Future<void> refreshAfterTrackChange({
    required String projectId,
    required String reason,
  }) async {
    invalidateTimeline(projectId);

    final nativeRefresh = refreshNativeGraph;

    if (nativeRefresh != null) {
      await nativeRefresh(projectId, reason);
    }
  }
}
