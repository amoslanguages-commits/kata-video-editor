import 'package:nle_editor/data/database/app_database.dart';

/// Represents the active visual content and text overlays at a given playhead position.
class TimelinePreviewItem {
  final Clip? primaryVisualClip;
  final Asset? primaryVisualAsset;
  final List<Clip> activeTextClips;

  const TimelinePreviewItem({
    required this.primaryVisualClip,
    required this.primaryVisualAsset,
    required this.activeTextClips,
  });

  bool get hasVisual =>
      primaryVisualClip != null && primaryVisualAsset != null;
}
