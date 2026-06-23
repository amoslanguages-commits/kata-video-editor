import 'package:nle_editor/domain/captions/caption_segment_models.dart';
import 'package:nle_editor/domain/captions/caption_value_models.dart';

class NleSubtitleTrack {
  final String id;
  final String projectId;
  final String name;
  final String langCode;
  final NleCaptionTrackType type;

  final bool enabled;
  final bool burnedIn;
  final bool exportSidecar;

  final NleSubtitleExportFormat exportFormat;
  final NleCaptionSpeakerMode speakerMode;

  final NleCaptionStylePreset stylePreset;
  final List<NleCaptionSegment> segments;

  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const NleSubtitleTrack({
    required this.id,
    required this.projectId,
    required this.name,
    required this.langCode,
    required this.type,
    required this.enabled,
    required this.burnedIn,
    required this.exportSidecar,
    required this.exportFormat,
    required this.speakerMode,
    required this.stylePreset,
    required this.segments,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  List<NleCaptionSegment> get orderedSegments {
    final copy = [...segments];
    copy.sort((a, b) => a.startMicros.compareTo(b.startMicros));
    return copy;
  }

  List<NleCaptionSegment> activeSegmentsAt(int timelineMicros) {
    if (!enabled || !burnedIn) return const [];

    return orderedSegments
        .where((segment) => segment.activeAt(timelineMicros))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'langCode': langCode,
      'type': type.name,
      'enabled': enabled,
      'burnedIn': burnedIn,
      'exportSidecar': exportSidecar,
      'exportFormat': exportFormat.name,
      'speakerMode': speakerMode.name,
      'stylePreset': stylePreset.toJson(),
      'segments': orderedSegments.map((segment) => segment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
    };
  }

  factory NleSubtitleTrack.fromJson(Map<String, dynamic> json) {
    return NleSubtitleTrack(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Subtitles',
      langCode: json['langCode']?.toString() ?? 'en',
      type: _enumByName(
        NleCaptionTrackType.values,
        json['type'],
        NleCaptionTrackType.subtitles,
      ),
      enabled: json['enabled'] != false,
      burnedIn: json['burnedIn'] == true,
      exportSidecar: json['exportSidecar'] != false,
      exportFormat: _enumByName(
        NleSubtitleExportFormat.values,
        json['exportFormat'],
        NleSubtitleExportFormat.srt,
      ),
      speakerMode: _enumByName(
        NleCaptionSpeakerMode.values,
        json['speakerMode'],
        NleCaptionSpeakerMode.hidden,
      ),
      stylePreset: NleCaptionStylePreset.fromJson(
        Map<String, dynamic>.from(json['stylePreset'] as Map? ?? const {}),
      ),
      segments: (json['segments'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleCaptionSegment.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleSubtitleTrack copyWith({
    String? name,
    String? langCode,
    NleCaptionTrackType? type,
    bool? enabled,
    bool? burnedIn,
    bool? exportSidecar,
    NleSubtitleExportFormat? exportFormat,
    NleCaptionSpeakerMode? speakerMode,
    NleCaptionStylePreset? stylePreset,
    List<NleCaptionSegment>? segments,
    DateTime? updatedAt,
    int? version,
  }) {
    return NleSubtitleTrack(
      id: id,
      projectId: projectId,
      name: name ?? this.name,
      langCode: langCode ?? this.langCode,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      burnedIn: burnedIn ?? this.burnedIn,
      exportSidecar: exportSidecar ?? this.exportSidecar,
      exportFormat: exportFormat ?? this.exportFormat,
      speakerMode: speakerMode ?? this.speakerMode,
      stylePreset: stylePreset ?? this.stylePreset,
      segments: segments ?? this.segments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      version: version ?? this.version,
    );
  }

  NleSubtitleTrack upsertSegment(NleCaptionSegment segment) {
    final next = <NleCaptionSegment>[];
    var replaced = false;

    for (final current in segments) {
      if (current.id == segment.id) {
        next.add(segment);
        replaced = true;
      } else {
        next.add(current);
      }
    }

    if (!replaced) {
      next.add(segment);
    }

    return copyWith(segments: next);
  }

  NleSubtitleTrack removeSegment(String segmentId) {
    return copyWith(
      segments: segments.where((segment) => segment.id != segmentId).toList(),
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
