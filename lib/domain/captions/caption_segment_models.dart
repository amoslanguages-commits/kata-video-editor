import 'package:nle_editor/domain/captions/caption_value_models.dart';
import 'package:nle_editor/domain/titles/title_style_models.dart';

class NleCaptionSegment {
  final String id;
  final String trackId;
  final int startMicros;
  final int endMicros;
  final String text;

  final String? speaker;
  final double confidence;
  final bool locked;
  final bool hidden;

  final NleTextStyleModel? styleOverride;
  final List<NleCaptionWordTiming> words;

  final int version;

  const NleCaptionSegment({
    required this.id,
    required this.trackId,
    required this.startMicros,
    required this.endMicros,
    required this.text,
    this.speaker,
    required this.confidence,
    required this.locked,
    required this.hidden,
    this.styleOverride,
    required this.words,
    required this.version,
  });

  int get durationMicros => endMicros - startMicros;

  bool get isValid {
    return id.isNotEmpty &&
        trackId.isNotEmpty &&
        startMicros >= 0 &&
        endMicros > startMicros;
  }

  bool activeAt(int timelineMicros) {
    return !hidden &&
        timelineMicros >= startMicros &&
        timelineMicros < endMicros;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackId': trackId,
      'startMicros': startMicros,
      'endMicros': endMicros,
      'text': text,
      'speaker': speaker,
      'confidence': confidence,
      'locked': locked,
      'hidden': hidden,
      'styleOverride': styleOverride?.toJson(),
      'words': words.map((word) => word.toJson()).toList(),
      'version': version,
    };
  }

  factory NleCaptionSegment.fromJson(Map<String, dynamic> json) {
    return NleCaptionSegment(
      id: json['id']?.toString() ?? '',
      trackId: json['trackId']?.toString() ?? '',
      startMicros: (json['startMicros'] as num?)?.toInt() ?? 0,
      endMicros: (json['endMicros'] as num?)?.toInt() ?? 1,
      text: json['text']?.toString() ?? '',
      speaker: json['speaker']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      locked: json['locked'] == true,
      hidden: json['hidden'] == true,
      styleOverride: json['styleOverride'] is Map
          ? NleTextStyleModel.fromJson(
              Map<String, dynamic>.from(json['styleOverride'] as Map),
            )
          : null,
      words: (json['words'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleCaptionWordTiming.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleCaptionSegment copyWith({
    String? id,
    String? trackId,
    int? startMicros,
    int? endMicros,
    String? text,
    String? speaker,
    double? confidence,
    bool? locked,
    bool? hidden,
    NleTextStyleModel? styleOverride,
    List<NleCaptionWordTiming>? words,
    int? version,
  }) {
    return NleCaptionSegment(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      startMicros: startMicros ?? this.startMicros,
      endMicros: endMicros ?? this.endMicros,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      confidence: confidence ?? this.confidence,
      locked: locked ?? this.locked,
      hidden: hidden ?? this.hidden,
      styleOverride: styleOverride ?? this.styleOverride,
      words: words ?? this.words,
      version: version ?? this.version,
    );
  }

  NleCaptionSegment shifted(int deltaMicros) {
    return copyWith(
      startMicros: startMicros + deltaMicros,
      endMicros: endMicros + deltaMicros,
      words: words.map((word) => word.shifted(deltaMicros)).toList(),
    );
  }
}
