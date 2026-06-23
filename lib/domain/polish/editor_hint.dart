class EditorHintId {
  EditorHintId._();

  static const String importMedia = 'import_media';
  static const String dragToTimeline = 'drag_to_timeline';
  static const String addText = 'add_text';
  static const String generateProxy = 'generate_proxy';
  static const String exportVideo = 'export_video';
  static const String diagnostics = 'diagnostics';
}

class EditorHint {
  final String id;
  final String title;
  final String message;
  final String actionLabel;

  const EditorHint({
    required this.id,
    required this.title,
    required this.message,
    required this.actionLabel,
  });
}

class EditorHintCatalog {
  EditorHintCatalog._();

  static const hints = <EditorHint>[
    EditorHint(
      id: EditorHintId.importMedia,
      title: 'Import your first media',
      message: 'Add videos, images, or audio before building your timeline.',
      actionLabel: 'Import Media',
    ),
    EditorHint(
      id: EditorHintId.dragToTimeline,
      title: 'Build your timeline',
      message: 'Tap a media item or drag it into the timeline to start editing.',
      actionLabel: 'Got it',
    ),
    EditorHint(
      id: EditorHintId.addText,
      title: 'Add creator captions',
      message: 'Use text styles to add titles, captions, and hooks.',
      actionLabel: 'Add Text',
    ),
    EditorHint(
      id: EditorHintId.generateProxy,
      title: 'Smooth heavy videos',
      message: 'Generate proxies for large videos to improve editing performance.',
      actionLabel: 'Generate Proxy',
    ),
    EditorHint(
      id: EditorHintId.exportVideo,
      title: 'Export your edit',
      message: 'Choose a preset and export your final video.',
      actionLabel: 'Export',
    ),
    EditorHint(
      id: EditorHintId.diagnostics,
      title: 'Fix problems fast',
      message: 'Use Diagnostics to repair missing media, failed jobs, or timeline issues.',
      actionLabel: 'Open Diagnostics',
    ),
  ];

  static EditorHint? byId(String id) {
    for (final hint in hints) {
      if (hint.id == id) return hint;
    }
    return null;
  }
}
