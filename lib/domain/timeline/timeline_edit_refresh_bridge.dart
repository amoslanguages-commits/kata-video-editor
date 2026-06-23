typedef InvalidateProjectTimelineCallback = void Function(String projectId);

typedef NativeTimelineGraphRefreshCallback = Future<void> Function(
  String projectId,
  String reason,
);

class TimelineEditRefreshBridge {
  final InvalidateProjectTimelineCallback invalidateTimeline;
  final NativeTimelineGraphRefreshCallback? refreshNativeGraph;

  const TimelineEditRefreshBridge({
    required this.invalidateTimeline,
    this.refreshNativeGraph,
  });

  Future<void> refresh({
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
