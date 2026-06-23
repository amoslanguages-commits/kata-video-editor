import 'dart:convert';

/// Represents the full editor session state captured when the app backgrounds
/// or when a deliberate save-now is triggered. Written to
/// `<project_root>/session_state.json`.
class ProjectSessionState {
  final String projectId;
  final int currentTimeMicros;
  final String? selectedClipId;
  final String? selectedTrackId;
  final String activeTool;
  final double timelineZoom;
  final bool showSafeArea;
  final bool snapEnabled;
  final bool previewWasPlaying;
  final DateTime savedAt;

  const ProjectSessionState({
    required this.projectId,
    required this.currentTimeMicros,
    required this.selectedClipId,
    required this.selectedTrackId,
    required this.activeTool,
    required this.timelineZoom,
    required this.showSafeArea,
    required this.snapEnabled,
    required this.previewWasPlaying,
    required this.savedAt,
  });

  ProjectSessionState copyWith({
    int? currentTimeMicros,
    String? selectedClipId,
    String? selectedTrackId,
    String? activeTool,
    double? timelineZoom,
    bool? showSafeArea,
    bool? snapEnabled,
    bool? previewWasPlaying,
    DateTime? savedAt,
  }) {
    return ProjectSessionState(
      projectId: projectId,
      currentTimeMicros: currentTimeMicros ?? this.currentTimeMicros,
      selectedClipId: selectedClipId ?? this.selectedClipId,
      selectedTrackId: selectedTrackId ?? this.selectedTrackId,
      activeTool: activeTool ?? this.activeTool,
      timelineZoom: timelineZoom ?? this.timelineZoom,
      showSafeArea: showSafeArea ?? this.showSafeArea,
      snapEnabled: snapEnabled ?? this.snapEnabled,
      previewWasPlaying: previewWasPlaying ?? this.previewWasPlaying,
      savedAt: savedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'currentTimeMicros': currentTimeMicros,
      'selectedClipId': selectedClipId,
      'selectedTrackId': selectedTrackId,
      'activeTool': activeTool,
      'timelineZoom': timelineZoom,
      'showSafeArea': showSafeArea,
      'snapEnabled': snapEnabled,
      'previewWasPlaying': previewWasPlaying,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory ProjectSessionState.fromJson(Map<String, dynamic> json) {
    return ProjectSessionState(
      projectId: json['projectId'] as String,
      currentTimeMicros: (json['currentTimeMicros'] as num?)?.round() ?? 0,
      selectedClipId: json['selectedClipId'] as String?,
      selectedTrackId: json['selectedTrackId'] as String?,
      activeTool: json['activeTool'] as String? ?? 'media',
      timelineZoom: (json['timelineZoom'] as num?)?.toDouble() ?? 1.0,
      showSafeArea: json['showSafeArea'] as bool? ?? true,
      snapEnabled: json['snapEnabled'] as bool? ?? true,
      previewWasPlaying: json['previewWasPlaying'] as bool? ?? false,
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ProjectSessionState.fromJsonString(String raw) {
    return ProjectSessionState.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
