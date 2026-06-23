import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/overlays/overlay_template_factory.dart';
import 'package:nle_editor/presentation/providers/overlay_clip_providers.dart';

class CreateOverlayClipRequest {
  final String projectId;
  final String trackId;
  final int timelineStartMicros;
  final int durationMicros;
  final NleOverlayTemplateId template;

  const CreateOverlayClipRequest({
    required this.projectId,
    required this.trackId,
    required this.timelineStartMicros,
    required this.durationMicros,
    required this.template,
  });

  @override
  bool operator ==(Object other) {
    return other is CreateOverlayClipRequest &&
        other.projectId == projectId &&
        other.trackId == trackId &&
        other.timelineStartMicros == timelineStartMicros &&
        other.durationMicros == durationMicros &&
        other.template == template;
  }

  @override
  int get hashCode {
    return Object.hash(
      projectId,
      trackId,
      timelineStartMicros,
      durationMicros,
      template,
    );
  }
}

final createOverlayClipProvider = FutureProvider.autoDispose
    .family<String, CreateOverlayClipRequest>((ref, request) {
  return ref.watch(overlayClipRepositoryProvider).createOverlayClip(
        projectId: request.projectId,
        trackId: request.trackId,
        timelineStartMicros: request.timelineStartMicros,
        durationMicros: request.durationMicros,
        template: request.template,
      );
});
