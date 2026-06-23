import 'package:nle_editor/domain/titles/title_style_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

enum NleSubtitleExportFormat {
  none,
  srt,
  webvtt,
  burnedInOnly,
  burnedInAndSrt,
  burnedInAndWebvtt,
}

enum NleCaptionTrackType {
  subtitles,
  captions,
  forcedNarrative,
  translation,
  karaoke,
}

enum NleCaptionPlacement {
  bottomSafe,
  topSafe,
  center,
  custom,
}

enum NleCaptionSpeakerMode {
  hidden,
  inline,
  prefix,
  separateLine,
}

enum NleCaptionSnapMode {
  off,
  toTimelinePlayhead,
  toNearestClipCut,
  toPreviousCaptionEnd,
  toNextCaptionStart,
}

enum NleAutoCaptionStatus {
  idle,
  queued,
  transcribing,
  completed,
  failed,
  cancelled,
}

class NleCaptionWordTiming {
  final String id;
  final String word;
  final int startMicros;
  final int endMicros;
  final double confidence;

  const NleCaptionWordTiming({
    required this.id,
    required this.word,
    required this.startMicros,
    required this.endMicros,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'startMicros': startMicros,
      'endMicros': endMicros,
      'confidence': confidence,
    };
  }

  factory NleCaptionWordTiming.fromJson(Map<String, dynamic> json) {
    return NleCaptionWordTiming(
      id: json['id']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
      startMicros: (json['startMicros'] as num?)?.toInt() ?? 0,
      endMicros: (json['endMicros'] as num?)?.toInt() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  NleCaptionWordTiming shifted(int deltaMicros) {
    return NleCaptionWordTiming(
      id: id,
      word: word,
      startMicros: startMicros + deltaMicros,
      endMicros: endMicros + deltaMicros,
      confidence: confidence,
    );
  }
}

class NleCaptionStylePreset {
  final String id;
  final String name;
  final NleTextStyleModel style;
  final NleCaptionPlacement placement;
  final NleRectNorm customBox;
  final bool showSafeArea;
  final int maxLines;

  const NleCaptionStylePreset({
    required this.id,
    required this.name,
    required this.style,
    required this.placement,
    required this.customBox,
    required this.showSafeArea,
    required this.maxLines,
  });

  factory NleCaptionStylePreset.defaultReadable() {
    return NleCaptionStylePreset(
      id: 'default_readable',
      name: 'Readable',
      placement: NleCaptionPlacement.bottomSafe,
      customBox: const NleRectNorm(
        x: 0.08,
        y: 0.76,
        width: 0.84,
        height: 0.18,
      ),
      showSafeArea: true,
      maxLines: 2,
      style: const NleTextStyleModel.defaultTitle().copyWith(
        fontSize: 34.0,
        lineHeight: 1.15,
        shadow: const NleTextShadowStyle.soft(),
        stroke: const NleTextStrokeStyle(
          enabled: true,
          width: 4.0,
          color: NleRgbaColor.black(),
        ),
      ),
    );
  }

  factory NleCaptionStylePreset.socialBox() {
    return NleCaptionStylePreset(
      id: 'social_box',
      name: 'Social Box',
      placement: NleCaptionPlacement.bottomSafe,
      customBox: const NleRectNorm(
        x: 0.07,
        y: 0.74,
        width: 0.86,
        height: 0.18,
      ),
      showSafeArea: true,
      maxLines: 2,
      style: const NleTextStyleModel.defaultTitle().copyWith(
        fontSize: 36.0,
        lineHeight: 1.10,
        background: const NleTextBackgroundStyle.darkPill(),
      ),
    );
  }

  factory NleCaptionStylePreset.minimal() {
    return NleCaptionStylePreset(
      id: 'minimal',
      name: 'Minimal',
      placement: NleCaptionPlacement.bottomSafe,
      customBox: const NleRectNorm(
        x: 0.10,
        y: 0.78,
        width: 0.80,
        height: 0.14,
      ),
      showSafeArea: true,
      maxLines: 2,
      style: const NleTextStyleModel.defaultTitle().copyWith(
        fontSize: 30.0,
        lineHeight: 1.12,
        shadow: const NleTextShadowStyle.soft(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'style': style.toJson(),
      'placement': placement.name,
      'customBox': customBox.toJson(),
      'showSafeArea': showSafeArea,
      'maxLines': maxLines,
    };
  }

  factory NleCaptionStylePreset.fromJson(Map<String, dynamic> json) {
    return NleCaptionStylePreset(
      id: json['id']?.toString() ?? 'default_readable',
      name: json['name']?.toString() ?? 'Readable',
      style: NleTextStyleModel.fromJson(
        Map<String, dynamic>.from(json['style'] as Map? ?? const {}),
      ),
      placement: _enumByName(
        NleCaptionPlacement.values,
        json['placement'],
        NleCaptionPlacement.bottomSafe,
      ),
      customBox: NleRectNorm.fromJson(
        Map<String, dynamic>.from(json['customBox'] as Map? ?? const {}),
      ),
      showSafeArea: json['showSafeArea'] != false,
      maxLines: (json['maxLines'] as num?)?.toInt() ?? 2,
    );
  }

  NleCaptionStylePreset copyWith({
    String? id,
    String? name,
    NleTextStyleModel? style,
    NleCaptionPlacement? placement,
    NleRectNorm? customBox,
    bool? showSafeArea,
    int? maxLines,
  }) {
    return NleCaptionStylePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      style: style ?? this.style,
      placement: placement ?? this.placement,
      customBox: customBox ?? this.customBox,
      showSafeArea: showSafeArea ?? this.showSafeArea,
      maxLines: maxLines ?? this.maxLines,
    );
  }
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? name,
  T fallback,
) {
  final string = name?.toString();
  if (string == null) return fallback;

  for (final value in values) {
    if (value.name == string) return value;
  }

  return fallback;
}
