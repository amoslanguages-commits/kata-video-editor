enum NleLutDomain {
  sceneLinear,
  displayReferred,
  log,
}

enum NleLutInterpolation {
  nearest,
  trilinear,
}

enum NleLutTextureMode {
  texture3d,
  texture2dAtlas,
}

enum NleLutSourceType {
  cube,
  builtIn,
  generated,
}

class NleLutAsset {
  final String id;
  final String name;
  final String filePath;
  final NleLutSourceType sourceType;
  final int size;
  final bool isValid;
  final String? previewThumbnailPath;
  final DateTime importedAt;

  const NleLutAsset({
    required this.id,
    required this.name,
    required this.filePath,
    required this.sourceType,
    required this.size,
    required this.isValid,
    required this.importedAt,
    this.previewThumbnailPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'sourceType': sourceType.name,
      'size': size,
      'isValid': isValid,
      'previewThumbnailPath': previewThumbnailPath,
      'importedAt': importedAt.toIso8601String(),
    };
  }

  factory NleLutAsset.fromJson(Map<String, dynamic> json) {
    return NleLutAsset(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'LUT',
      filePath: json['filePath']?.toString() ?? '',
      sourceType: _enumByName(
        NleLutSourceType.values,
        json['sourceType'],
        NleLutSourceType.cube,
      ),
      size: (json['size'] as num?)?.toInt() ?? 0,
      isValid: json['isValid'] == true,
      previewThumbnailPath: json['previewThumbnailPath']?.toString(),
      importedAt: DateTime.tryParse(json['importedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class NleLutLayer {
  final String id;
  final String lutAssetId;
  final String lutPath;
  final String name;
  final int size;
  final double intensity;
  final bool enabled;
  final NleLutDomain domain;
  final NleLutInterpolation interpolation;

  const NleLutLayer({
    required this.id,
    required this.lutAssetId,
    required this.lutPath,
    required this.name,
    required this.size,
    this.intensity = 1.0,
    this.enabled = true,
    this.domain = NleLutDomain.sceneLinear,
    this.interpolation = NleLutInterpolation.trilinear,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lutAssetId': lutAssetId,
      'lutPath': lutPath,
      'name': name,
      'size': size,
      'intensity': intensity,
      'enabled': enabled,
      'domain': domain.name,
      'interpolation': interpolation.name,
    };
  }

  factory NleLutLayer.fromJson(Map<String, dynamic> json) {
    return NleLutLayer(
      id: json['id']?.toString() ?? '',
      lutAssetId: json['lutAssetId']?.toString() ?? '',
      lutPath: json['lutPath']?.toString() ?? '',
      name: json['name']?.toString() ?? 'LUT',
      size: (json['size'] as num?)?.toInt() ?? 0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
      enabled: json['enabled'] != false,
      domain: _enumByName(
        NleLutDomain.values,
        json['domain'],
        NleLutDomain.sceneLinear,
      ),
      interpolation: _enumByName(
        NleLutInterpolation.values,
        json['interpolation'],
        NleLutInterpolation.trilinear,
      ),
    );
  }
}

class NleClipLutStack {
  final String clipId;
  final List<NleLutLayer> layers;

  const NleClipLutStack({
    required this.clipId,
    required this.layers,
  });

  const NleClipLutStack.empty({
    required this.clipId,
  }) : layers = const [];

  bool get hasEnabledLuts {
    return layers.any((layer) => layer.enabled && layer.intensity > 0.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'clipId': clipId,
      'layers': layers.map((layer) => layer.toJson()).toList(),
    };
  }

  factory NleClipLutStack.fromJson(Map<String, dynamic> json) {
    return NleClipLutStack(
      clipId: json['clipId']?.toString() ?? '',
      layers: (json['layers'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => NleLutLayer.fromJson(Map<String, dynamic>.from(item)))
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
