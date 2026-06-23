// lib/domain/editor_history/editor_action_models.dart

enum EditorActionType {
  insertClip,
  deleteClip,
  moveClip,
  trimClip,
  splitClip,
  duplicateClip,
  updateClipInspector,
  updateTrackState,
  renameTrack,
  sourceInsert,
}

class EditorActionSnapshot {
  final String id;
  final EditorActionType type;
  final String label;
  final DateTime createdAt;

  /// JSON snapshot before the edit.
  final Map<String, dynamic> before;

  /// JSON snapshot after the edit.
  final Map<String, dynamic> after;

  const EditorActionSnapshot({
    required this.id,
    required this.type,
    required this.label,
    required this.createdAt,
    required this.before,
    required this.after,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
      'before': before,
      'after': after,
    };
  }

  factory EditorActionSnapshot.fromJson(Map<String, dynamic> json) {
    return EditorActionSnapshot(
      id: json['id']?.toString() ?? '',
      type: EditorActionType.values.firstWhere(
        (type) => type.name == json['type']?.toString(),
        orElse: () => EditorActionType.moveClip,
      ),
      label: json['label']?.toString() ?? 'Edit',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      before: Map<String, dynamic>.from(json['before'] as Map? ?? const {}),
      after: Map<String, dynamic>.from(json['after'] as Map? ?? const {}),
    );
  }
}
