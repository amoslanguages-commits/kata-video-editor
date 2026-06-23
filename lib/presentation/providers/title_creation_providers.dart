import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/titles/title_style_models.dart';
import 'package:nle_editor/presentation/providers/title_clip_providers.dart';

final createTitleClipProvider = FutureProvider.autoDispose
    .family<String, CreateTitleClipRequest>((ref, request) {
  return ref.watch(titleClipRepositoryProvider).createTitleClip(
        projectId: request.projectId,
        trackId: request.trackId,
        timelineStartMicros: request.timelineStartMicros,
        durationMicros: request.durationMicros,
        template: request.template,
      );
});

class CreateTitleClipRequest {
  final String projectId;
  final String trackId;
  final int timelineStartMicros;
  final int durationMicros;
  final NleTitleTemplateId template;

  const CreateTitleClipRequest({
    required this.projectId,
    required this.trackId,
    required this.timelineStartMicros,
    required this.durationMicros,
    required this.template,
  });

  @override
  bool operator ==(Object other) {
    return other is CreateTitleClipRequest &&
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
