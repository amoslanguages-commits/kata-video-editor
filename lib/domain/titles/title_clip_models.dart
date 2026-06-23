import 'package:nle_editor/domain/titles/title_motion_models.dart';
import 'package:nle_editor/domain/titles/title_style_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

class NleTitleLayout {
  final NleRectNorm box;
  final NleTextAnchor anchor;
  final NleTextHorizontalAlign horizontalAlign;
  final NleTextVerticalAlign verticalAlign;
  final bool respectSafeArea;
  final double safeAreaPadding;

  const NleTitleLayout({
    required this.box,
    required this.anchor,
    required this.horizontalAlign,
    required this.verticalAlign,
    required this.respectSafeArea,
    required this.safeAreaPadding,
  });

  const NleTitleLayout.center()
      : box = const NleRectNorm.centerTitle(),
        anchor = NleTextAnchor.center,
        horizontalAlign = NleTextHorizontalAlign.center,
        verticalAlign = NleTextVerticalAlign.center,
        respectSafeArea = true,
        safeAreaPadding = 0.06;

  const NleTitleLayout.lowerThird()
      : box = const NleRectNorm.lowerThird(),
        anchor = NleTextAnchor.centerLeft,
        horizontalAlign = NleTextHorizontalAlign.left,
        verticalAlign = NleTextVerticalAlign.center,
        respectSafeArea = true,
        safeAreaPadding = 0.06;

  Map<String, dynamic> toJson() {
    return {
      'box': box.toJson(),
      'anchor': anchor.name,
      'horizontalAlign': horizontalAlign.name,
      'verticalAlign': verticalAlign.name,
      'respectSafeArea': respectSafeArea,
      'safeAreaPadding': safeAreaPadding,
    };
  }

  factory NleTitleLayout.fromJson(Map<String, dynamic> json) {
    return NleTitleLayout(
      box: NleRectNorm.fromJson(
        Map<String, dynamic>.from(json['box'] as Map? ?? const {}),
      ),
      anchor: _enumByName(
        NleTextAnchor.values,
        json['anchor'],
        NleTextAnchor.center,
      ),
      horizontalAlign: _enumByName(
        NleTextHorizontalAlign.values,
        json['horizontalAlign'],
        NleTextHorizontalAlign.center,
      ),
      verticalAlign: _enumByName(
        NleTextVerticalAlign.values,
        json['verticalAlign'],
        NleTextVerticalAlign.center,
      ),
      respectSafeArea: json['respectSafeArea'] != false,
      safeAreaPadding: (json['safeAreaPadding'] as num?)?.toDouble() ?? 0.06,
    );
  }

  NleTitleLayout copyWith({
    NleRectNorm? box,
    NleTextAnchor? anchor,
    NleTextHorizontalAlign? horizontalAlign,
    NleTextVerticalAlign? verticalAlign,
    bool? respectSafeArea,
    double? safeAreaPadding,
  }) {
    return NleTitleLayout(
      box: box ?? this.box,
      anchor: anchor ?? this.anchor,
      horizontalAlign: horizontalAlign ?? this.horizontalAlign,
      verticalAlign: verticalAlign ?? this.verticalAlign,
      respectSafeArea: respectSafeArea ?? this.respectSafeArea,
      safeAreaPadding: safeAreaPadding ?? this.safeAreaPadding,
    );
  }
}

class NleTitleClipData {
  final String id;
  final NleTextClipKind kind;
  final String text;
  final String? secondaryText;

  final NleTextStyleModel style;
  final NleTextStyleModel? secondaryStyle;
  final NleTitleLayout layout;
  final NleTitleMotion motion;

  final NleTitleTemplateId? templateId;
  final bool editable;
  final int version;

  const NleTitleClipData({
    required this.id,
    required this.kind,
    required this.text,
    this.secondaryText,
    required this.style,
    this.secondaryStyle,
    required this.layout,
    required this.motion,
    this.templateId,
    required this.editable,
    required this.version,
  });

  factory NleTitleClipData.defaultTitle({
    required String id,
    String text = 'Your Title',
  }) {
    return NleTitleClipData(
      id: id,
      kind: NleTextClipKind.title,
      text: text,
      style: const NleTextStyleModel.defaultTitle(),
      layout: const NleTitleLayout.center(),
      motion: const NleTitleMotion.identity(),
      templateId: NleTitleTemplateId.basicTitle,
      editable: true,
      version: 1,
    );
  }

  factory NleTitleClipData.defaultLowerThird({
    required String id,
    String name = 'Your Name',
    String role = 'Subtitle',
  }) {
    return NleTitleClipData(
      id: id,
      kind: NleTextClipKind.lowerThird,
      text: name,
      secondaryText: role,
      style: const NleTextStyleModel.defaultTitle().copyWith(
        fontSize: 48.0,
        shadow: const NleTextShadowStyle.soft(),
      ),
      secondaryStyle: const NleTextStyleModel.defaultTitle().copyWith(
        fontSize: 26.0,
        opacity: 0.82,
        shadow: const NleTextShadowStyle.soft(),
      ),
      layout: const NleTitleLayout.lowerThird(),
      motion: const NleTitleMotion.identity().copyWith(
        animationPreset: NleTitleAnimationPreset.lowerThirdSlide,
      ),
      templateId: NleTitleTemplateId.lowerThirdClean,
      editable: true,
      version: 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'text': text,
      'secondaryText': secondaryText,
      'style': style.toJson(),
      'secondaryStyle': secondaryStyle?.toJson(),
      'layout': layout.toJson(),
      'motion': motion.toJson(),
      'templateId': templateId?.name,
      'editable': editable,
      'version': version,
    };
  }

  factory NleTitleClipData.fromJson(Map<String, dynamic> json) {
    return NleTitleClipData(
      id: json['id']?.toString() ?? '',
      kind: _enumByName(
        NleTextClipKind.values,
        json['kind'],
        NleTextClipKind.title,
      ),
      text: json['text']?.toString() ?? '',
      secondaryText: json['secondaryText']?.toString(),
      style: NleTextStyleModel.fromJson(
        Map<String, dynamic>.from(json['style'] as Map? ?? const {}),
      ),
      secondaryStyle: json['secondaryStyle'] is Map
          ? NleTextStyleModel.fromJson(
              Map<String, dynamic>.from(json['secondaryStyle'] as Map),
            )
          : null,
      layout: NleTitleLayout.fromJson(
        Map<String, dynamic>.from(json['layout'] as Map? ?? const {}),
      ),
      motion: NleTitleMotion.fromJson(
        Map<String, dynamic>.from(json['motion'] as Map? ?? const {}),
      ),
      templateId: _optionalEnumByName(
        NleTitleTemplateId.values,
        json['templateId'],
      ),
      editable: json['editable'] != false,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleTitleClipData copyWith({
    NleTextClipKind? kind,
    String? text,
    String? secondaryText,
    NleTextStyleModel? style,
    NleTextStyleModel? secondaryStyle,
    NleTitleLayout? layout,
    NleTitleMotion? motion,
    NleTitleTemplateId? templateId,
    bool? editable,
    int? version,
  }) {
    return NleTitleClipData(
      id: id,
      kind: kind ?? this.kind,
      text: text ?? this.text,
      secondaryText: secondaryText ?? this.secondaryText,
      style: style ?? this.style,
      secondaryStyle: secondaryStyle ?? this.secondaryStyle,
      layout: layout ?? this.layout,
      motion: motion ?? this.motion,
      templateId: templateId ?? this.templateId,
      editable: editable ?? this.editable,
      version: version ?? this.version,
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

T? _optionalEnumByName<T extends Enum>(
  List<T> values,
  Object? name,
) {
  final string = name?.toString();
  if (string == null) return null;

  for (final value in values) {
    if (value.name == string) return value;
  }

  return null;
}
