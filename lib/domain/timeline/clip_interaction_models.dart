class ClipInteractionException implements Exception {
  final String message;

  const ClipInteractionException(this.message);

  @override
  String toString() => message;
}

class ClipInteractionResult {
  final String clipId;
  final String action;
  final String? newClipId;

  const ClipInteractionResult({
    required this.clipId,
    required this.action,
    this.newClipId,
  });
}
