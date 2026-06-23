import 'package:nle_editor/domain/titles/title_value_models.dart';

enum NleMotionTemplateCategory {
  titles,
  lowerThirds,
  captions,
  callouts,
  social,
  business,
  cinematic,
  stickers,
  arrows,
  highlights,
  news,
  minimal,
}

enum NleMotionTemplateLayerKind {
  title,
  overlay,
  caption,
  sticker,
}

enum NleMotionTemplateAspectMode {
  any,
  landscape16x9,
  portrait9x16,
  square1x1,
}

enum NleMotionTemplateAccess {
  free,
  premium,
  pro,
  marketplace,
}

enum NleTemplateParameterType {
  text,
  number,
  color,
  boolean,
  enumValue,
  asset,
  fontFamily,
}

enum NleTemplateInstallSource {
  builtIn,
  localImport,
  marketplace,
  userCreated,
}

class NleTemplateParameterOption {
  final String value;
  final String label;

  const NleTemplateParameterOption({
    required this.value,
    required this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }

  factory NleTemplateParameterOption.fromJson(Map<String, dynamic> json) {
    return NleTemplateParameterOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class NleTemplateParameterValue {
  final String parameterId;
  final NleTemplateParameterType type;
  final Object? value;

  const NleTemplateParameterValue({
    required this.parameterId,
    required this.type,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    Object? encoded = value;

    if (value is NleRgbaColor) {
      encoded = (value as NleRgbaColor).toJson();
    }

    return {
      'parameterId': parameterId,
      'type': type.name,
      'value': encoded,
    };
  }

  factory NleTemplateParameterValue.fromJson(Map<String, dynamic> json) {
    final type = _enumByName(
      NleTemplateParameterType.values,
      json['type'],
      NleTemplateParameterType.text,
    );

    Object? value = json['value'];

    if (type == NleTemplateParameterType.color && value is Map) {
      value = NleRgbaColor.fromJson(
        Map<String, dynamic>.from(value),
      );
    }

    return NleTemplateParameterValue(
      parameterId: json['parameterId']?.toString() ?? '',
      type: type,
      value: value,
    );
  }
}

class NleTemplateParameterDefinition {
  final String id;
  final String label;
  final String description;
  final NleTemplateParameterType type;
  final NleTemplateParameterValue defaultValue;
  final List<NleTemplateParameterOption> options;
  final double? min;
  final double? max;
  final bool required;

  const NleTemplateParameterDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.type,
    required this.defaultValue,
    required this.options,
    this.min,
    this.max,
    required this.required,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'description': description,
      'type': type.name,
      'defaultValue': defaultValue.toJson(),
      'options': options.map((item) => item.toJson()).toList(),
      'min': min,
      'max': max,
      'required': required,
    };
  }

  factory NleTemplateParameterDefinition.fromJson(Map<String, dynamic> json) {
    return NleTemplateParameterDefinition(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: _enumByName(
        NleTemplateParameterType.values,
        json['type'],
        NleTemplateParameterType.text,
      ),
      defaultValue: NleTemplateParameterValue.fromJson(
        Map<String, dynamic>.from(json['defaultValue'] as Map? ?? const {}),
      ),
      options: (json['options'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleTemplateParameterOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      required: json['required'] != false,
    );
  }
}

class NleTemplateParameterBinding {
  final String parameterId;
  final String layerId;
  final String propertyPath;

  const NleTemplateParameterBinding({
    required this.parameterId,
    required this.layerId,
    required this.propertyPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'parameterId': parameterId,
      'layerId': layerId,
      'propertyPath': propertyPath,
    };
  }

  factory NleTemplateParameterBinding.fromJson(Map<String, dynamic> json) {
    return NleTemplateParameterBinding(
      parameterId: json['parameterId']?.toString() ?? '',
      layerId: json['layerId']?.toString() ?? '',
      propertyPath: json['propertyPath']?.toString() ?? '',
    );
  }
}

class NleTemplateCreatorMetadata {
  final String creatorName;
  final String creatorUrl;
  final String license;
  final String copyright;
  final bool commercialUseAllowed;

  const NleTemplateCreatorMetadata({
    required this.creatorName,
    required this.creatorUrl,
    required this.license,
    required this.copyright,
    required this.commercialUseAllowed,
  });

  const NleTemplateCreatorMetadata.builtIn()
      : creatorName = 'NLE Editor',
        creatorUrl = '',
        license = 'Built-in app template',
        copyright = 'NLE Editor',
        commercialUseAllowed = true;

  Map<String, dynamic> toJson() {
    return {
      'creatorName': creatorName,
      'creatorUrl': creatorUrl,
      'license': license,
      'copyright': copyright,
      'commercialUseAllowed': commercialUseAllowed,
    };
  }

  factory NleTemplateCreatorMetadata.fromJson(Map<String, dynamic> json) {
    return NleTemplateCreatorMetadata(
      creatorName: json['creatorName']?.toString() ?? 'Unknown',
      creatorUrl: json['creatorUrl']?.toString() ?? '',
      license: json['license']?.toString() ?? '',
      copyright: json['copyright']?.toString() ?? '',
      commercialUseAllowed: json['commercialUseAllowed'] != false,
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
