class CreativePackType {
  CreativePackType._();

  static const String effects = 'effects';
  static const String transitions = 'transitions';
  static const String text = 'text';
  static const String color = 'color';
  static const String export = 'export';
  static const String template = 'template';
  static const String thumbnail = 'thumbnail';
}

class CreativePackItemType {
  CreativePackItemType._();

  static const String effectPreset = 'effect_preset';
  static const String transitionPreset = 'transition_preset';
  static const String textPreset = 'text_preset';
  static const String colorPreset = 'color_preset';
  static const String exportPreset = 'export_preset';
  static const String socialTemplate = 'social_template';
  static const String thumbnailPreset = 'thumbnail_preset';
}

class CreativePackItem {
  final String id;
  final String packId;
  final String type;
  final String title;
  final String description;
  final bool proOnly;
  final String? requiredFeatureId;
  final Map<String, dynamic> payload;
  final List<String> tags;
  final String? previewAsset;

  const CreativePackItem({
    required this.id,
    required this.packId,
    required this.type,
    required this.title,
    required this.description,
    required this.proOnly,
    required this.payload,
    this.requiredFeatureId,
    this.tags = const [],
    this.previewAsset,
  });

  bool isLocked(bool Function(String featureId) hasFeature) {
    if (!proOnly) return false;

    final featureId = requiredFeatureId;
    if (featureId == null) return true;

    return !hasFeature(featureId);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packId': packId,
      'type': type,
      'title': title,
      'description': description,
      'proOnly': proOnly,
      'requiredFeatureId': requiredFeatureId,
      'payload': payload,
      'tags': tags,
      'previewAsset': previewAsset,
    };
  }

  factory CreativePackItem.fromJson(Map<String, dynamic> json) {
    return CreativePackItem(
      id: json['id']?.toString() ?? '',
      packId: json['packId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      proOnly: json['proOnly'] == true,
      requiredFeatureId: json['requiredFeatureId']?.toString(),
      payload: _asMap(json['payload']),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      previewAsset: json['previewAsset']?.toString(),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }

    return {};
  }
}

class CreativePack {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String description;
  final String version;
  final String author;
  final bool proOnly;
  final String? requiredFeatureId;
  final List<CreativePackItem> items;
  final List<String> tags;
  final String? coverAsset;

  const CreativePack({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.version,
    required this.author,
    required this.proOnly,
    required this.items,
    this.requiredFeatureId,
    this.tags = const [],
    this.coverAsset,
  });

  bool isLocked(bool Function(String featureId) hasFeature) {
    if (!proOnly) return false;

    final featureId = requiredFeatureId;
    if (featureId == null) return true;

    return !hasFeature(featureId);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'version': version,
      'author': author,
      'proOnly': proOnly,
      'requiredFeatureId': requiredFeatureId,
      'items': items.map((e) => e.toJson()).toList(),
      'tags': tags,
      'coverAsset': coverAsset,
    };
  }

  factory CreativePack.fromJson(Map<String, dynamic> json) {
    return CreativePack(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      version: json['version']?.toString() ?? '1.0.0',
      author: json['author']?.toString() ?? 'Kata',
      proOnly: json['proOnly'] == true,
      requiredFeatureId: json['requiredFeatureId']?.toString(),
      items: (json['items'] as List?)
              ?.map((e) => CreativePackItem.fromJson(CreativePackItem._asMap(e)))
              .toList() ??
          const [],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      coverAsset: json['coverAsset']?.toString(),
    );
  }
}
