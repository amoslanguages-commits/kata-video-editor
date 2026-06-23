import 'package:nle_editor/domain/motion_templates/motion_template_value_models.dart';
import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/domain/titles/title_clip_models.dart';

class NleMotionTemplateLayer {
  final String id;
  final String name;
  final NleMotionTemplateLayerKind kind;
  final int relativeStartMicros;
  final int relativeEndMicros;
  final int zIndex;

  final NleTitleClipData? titleData;
  final NleOverlayClipData? overlayData;

  final List<NleTemplateParameterBinding> bindings;

  const NleMotionTemplateLayer({
    required this.id,
    required this.name,
    required this.kind,
    required this.relativeStartMicros,
    required this.relativeEndMicros,
    required this.zIndex,
    this.titleData,
    this.overlayData,
    required this.bindings,
  });

  int get durationMicros => relativeEndMicros - relativeStartMicros;

  bool get isValid {
    return id.isNotEmpty &&
        relativeStartMicros >= 0 &&
        relativeEndMicros > relativeStartMicros;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kind': kind.name,
      'relativeStartMicros': relativeStartMicros,
      'relativeEndMicros': relativeEndMicros,
      'zIndex': zIndex,
      'titleData': titleData?.toJson(),
      'overlayData': overlayData?.toJson(),
      'bindings': bindings.map((item) => item.toJson()).toList(),
    };
  }

  factory NleMotionTemplateLayer.fromJson(Map<String, dynamic> json) {
    return NleMotionTemplateLayer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Layer',
      kind: _enumByName(
        NleMotionTemplateLayerKind.values,
        json['kind'],
        NleMotionTemplateLayerKind.title,
      ),
      relativeStartMicros:
          (json['relativeStartMicros'] as num?)?.toInt() ?? 0,
      relativeEndMicros:
          (json['relativeEndMicros'] as num?)?.toInt() ?? 4000000,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      titleData: json['titleData'] is Map
          ? NleTitleClipData.fromJson(
              Map<String, dynamic>.from(json['titleData'] as Map),
            )
          : null,
      overlayData: json['overlayData'] is Map
          ? NleOverlayClipData.fromJson(
              Map<String, dynamic>.from(json['overlayData'] as Map),
            )
          : null,
      bindings: (json['bindings'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleTemplateParameterBinding.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
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
