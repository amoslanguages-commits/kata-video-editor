class ExportRoutingMode {
  static const String passThrough = 'pass_through';
  static const String composited = 'composited';

  const ExportRoutingMode._();
}

class ExportRoutingReason {
  static const String singleCleanVideoClip = 'single_clean_video_clip';
  static const String multipleVisualClips = 'multiple_visual_clips';
  static const String visualTransformOrColor = 'visual_transform_or_color';
  static const String timelineAudioMixdown = 'timeline_audio_mixdown';
  static const String textOrOverlay = 'text_or_overlay';
  static const String unsupportedPassThrough = 'unsupported_pass_through';

  const ExportRoutingReason._();
}

class ExportRoutingDecision {
  final String mode;
  final List<String> reasons;
  final bool requiresAudioMixdown;
  final bool preferProxy;

  const ExportRoutingDecision({
    required this.mode,
    required this.reasons,
    required this.requiresAudioMixdown,
    required this.preferProxy,
  });

  bool get passThrough => mode == ExportRoutingMode.passThrough;
  bool get composited => mode == ExportRoutingMode.composited;

  Map<String, Object?> toJson() => {
        'mode': mode,
        'reasons': reasons,
        'requiresAudioMixdown': requiresAudioMixdown,
        'preferProxy': preferProxy,
      };
}

class ExportRoutingPolicy {
  const ExportRoutingPolicy();

  ExportRoutingDecision decide({
    required int visualClipCount,
    required bool hasText,
    required bool hasOverlays,
    required bool hasVisualTransforms,
    required bool hasColorPipeline,
    required bool requiresAudioMixdown,
    required bool preferProxy,
  }) {
    final reasons = <String>[];

    if (visualClipCount != 1) reasons.add(ExportRoutingReason.multipleVisualClips);
    if (hasText || hasOverlays) reasons.add(ExportRoutingReason.textOrOverlay);
    if (hasVisualTransforms || hasColorPipeline) {
      reasons.add(ExportRoutingReason.visualTransformOrColor);
    }
    if (requiresAudioMixdown) reasons.add(ExportRoutingReason.timelineAudioMixdown);

    if (reasons.isEmpty) {
      reasons.add(ExportRoutingReason.singleCleanVideoClip);
      return ExportRoutingDecision(
        mode: ExportRoutingMode.passThrough,
        reasons: reasons,
        requiresAudioMixdown: false,
        preferProxy: preferProxy,
      );
    }

    return ExportRoutingDecision(
      mode: ExportRoutingMode.composited,
      reasons: reasons,
      requiresAudioMixdown: requiresAudioMixdown,
      preferProxy: preferProxy,
    );
  }
}
