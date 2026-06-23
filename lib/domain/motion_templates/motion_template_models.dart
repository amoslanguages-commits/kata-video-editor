import 'package:nle_editor/domain/motion_templates/motion_template_layer_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_value_models.dart';

class NleMotionTemplate {
  final String id;
  final String packId;
  final String name;
  final String description;
  final List<NleMotionTemplateCategory> categories;
  final List<String> tags;

  final int durationMicros;
  final NleMotionTemplateAspectMode aspectMode;

  final String? thumbnailAssetPath;
  final String? previewVideoAssetPath;

  final List<NleTemplateParameterDefinition> parameters;
  final List<NleMotionTemplateLayer> layers;

  final NleMotionTemplateAccess access;
  final bool marketplaceReady;
  final int version;

  const NleMotionTemplate({
    required this.id,
    required this.packId,
    required this.name,
    required this.description,
    required this.categories,
    required this.tags,
    required this.durationMicros,
    required this.aspectMode,
    this.thumbnailAssetPath,
    this.previewVideoAssetPath,
    required this.parameters,
    required this.layers,
    required this.access,
    required this.marketplaceReady,
    required this.version,
  });

  bool get isPremium {
    return access == NleMotionTemplateAccess.premium ||
        access == NleMotionTemplateAccess.pro ||
        access == NleMotionTemplateAccess.marketplace;
  }

  List<NleTemplateParameterValue> get defaultParameterValues {
    return parameters.map((parameter) => parameter.defaultValue).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packId': packId,
      'name': name,
      'description': description,
      'categories': categories.map((item) => item.name).toList(),
      'tags': tags,
      'durationMicros': durationMicros,
      'aspectMode': aspectMode.name,
      'thumbnailAssetPath': thumbnailAssetPath,
      'previewVideoAssetPath': previewVideoAssetPath,
      'parameters': parameters.map((item) => item.toJson()).toList(),
      'layers': layers.map((item) => item.toJson()).toList(),
      'access': access.name,
      'marketplaceReady': marketplaceReady,
      'version': version,
    };
  }

  factory NleMotionTemplate.fromJson(Map<String, dynamic> json) {
    return NleMotionTemplate(
      id: json['id']?.toString() ?? '',
      packId: json['packId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categories: (json['categories'] as List? ?? const [])
          .map(
            (item) => _enumByName(
              NleMotionTemplateCategory.values,
              item,
              NleMotionTemplateCategory.titles,
            ),
          )
          .toList(),
      tags: (json['tags'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      durationMicros: (json['durationMicros'] as num?)?.toInt() ?? 4000000,
      aspectMode: _enumByName(
        NleMotionTemplateAspectMode.values,
        json['aspectMode'],
        NleMotionTemplateAspectMode.any,
      ),
      thumbnailAssetPath: json['thumbnailAssetPath']?.toString(),
      previewVideoAssetPath: json['previewVideoAssetPath']?.toString(),
      parameters: (json['parameters'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleTemplateParameterDefinition.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      layers: (json['layers'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleMotionTemplateLayer.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      access: _enumByName(
        NleMotionTemplateAccess.values,
        json['access'],
        NleMotionTemplateAccess.free,
      ),
      marketplaceReady: json['marketplaceReady'] == true,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class NleMotionTemplatePack {
  final String id;
  final String name;
  final String description;
  final NleTemplateCreatorMetadata creator;
  final NleTemplateInstallSource source;
  final List<NleMotionTemplateCategory> categories;
  final List<NleMotionTemplate> templates;
  final NleMotionTemplateAccess access;
  final String? coverAssetPath;
  final String? marketplaceProductId;
  final DateTime installedAt;
  final int version;

  const NleMotionTemplatePack({
    required this.id,
    required this.name,
    required this.description,
    required this.creator,
    required this.source,
    required this.categories,
    required this.templates,
    required this.access,
    this.coverAssetPath,
    this.marketplaceProductId,
    required this.installedAt,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creator': creator.toJson(),
      'source': source.name,
      'categories': categories.map((item) => item.name).toList(),
      'templates': templates.map((item) => item.toJson()).toList(),
      'access': access.name,
      'coverAssetPath': coverAssetPath,
      'marketplaceProductId': marketplaceProductId,
      'installedAt': installedAt.toIso8601String(),
      'version': version,
    };
  }

  factory NleMotionTemplatePack.fromJson(Map<String, dynamic> json) {
    return NleMotionTemplatePack(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      creator: NleTemplateCreatorMetadata.fromJson(
        Map<String, dynamic>.from(json['creator'] as Map? ?? const {}),
      ),
      source: _enumByName(
        NleTemplateInstallSource.values,
        json['source'],
        NleTemplateInstallSource.builtIn,
      ),
      categories: (json['categories'] as List? ?? const [])
          .map(
            (item) => _enumByName(
              NleMotionTemplateCategory.values,
              item,
              NleMotionTemplateCategory.titles,
            ),
          )
          .toList(),
      templates: (json['templates'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleMotionTemplate.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      access: _enumByName(
        NleMotionTemplateAccess.values,
        json['access'],
        NleMotionTemplateAccess.free,
      ),
      coverAssetPath: json['coverAssetPath']?.toString(),
      marketplaceProductId: json['marketplaceProductId']?.toString(),
      installedAt: DateTime.tryParse(json['installedAt']?.toString() ?? '') ??
          DateTime.now(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class NleTemplateApplyRequest {
  final String projectId;
  final String trackId;
  final int timelineStartMicros;
  final String templateId;
  final List<NleTemplateParameterValue> values;

  const NleTemplateApplyRequest({
    required this.projectId,
    required this.trackId,
    required this.timelineStartMicros,
    required this.templateId,
    required this.values,
  });
}

class NleTemplateApplyResult {
  final String templateId;
  final String groupId;
  final List<String> createdClipIds;

  const NleTemplateApplyResult({
    required this.templateId,
    required this.groupId,
    required this.createdClipIds,
  });
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
