class NleExportPresetSpec {
  final String id;
  final String name;
  final String description;
  final String platform;
  final int width;
  final int height;
  final int frameRate;
  final int bitrateMbps;
  final String format;
  final bool removeWatermark;
  final bool isBuiltIn;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NleExportPresetSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.platform,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitrateMbps,
    required this.format,
    required this.removeWatermark,
    required this.isBuiltIn,
    required this.createdAt,
    required this.updatedAt,
  });

  String get resolutionLabel => '${width}x$height';
  String get frameRateLabel => '${frameRate}fps';
  String get bitrateLabel => '${bitrateMbps}M';

  Map<String, dynamic> get exportSettings {
    return {
      'preset': id,
      'resolution': height,
      'width': width,
      'frameRate': frameRate,
      'bitrate': bitrateLabel,
      'format': format,
      'removeWatermark': removeWatermark,
      'platform': platform,
    };
  }

  NleExportPresetSpec copyWith({
    String? id,
    String? name,
    String? description,
    String? platform,
    int? width,
    int? height,
    int? frameRate,
    int? bitrateMbps,
    String? format,
    bool? removeWatermark,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NleExportPresetSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      platform: platform ?? this.platform,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      bitrateMbps: bitrateMbps ?? this.bitrateMbps,
      format: format ?? this.format,
      removeWatermark: removeWatermark ?? this.removeWatermark,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'platform': platform,
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'bitrateMbps': bitrateMbps,
      'format': format,
      'removeWatermark': removeWatermark,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NleExportPresetSpec.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return NleExportPresetSpec(
      id: json['id']?.toString() ?? 'custom_${now.microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Custom Preset',
      description: json['description']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'Custom',
      width: _asInt(json['width'], 1920),
      height: _asInt(json['height'], 1080),
      frameRate: _asInt(json['frameRate'], 30),
      bitrateMbps: _asInt(json['bitrateMbps'], 8),
      format: json['format']?.toString() ?? 'mp4',
      removeWatermark: json['removeWatermark'] == true,
      isBuiltIn: json['isBuiltIn'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class NleExportPresetCatalog {
  const NleExportPresetCatalog._();

  static List<NleExportPresetSpec> builtInPresets() {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return [
      NleExportPresetSpec(
        id: 'tiktok_1080x1920_30',
        name: 'TikTok / Reels / Shorts',
        description: 'Vertical 1080p social export for short-form video.',
        platform: 'Short-form',
        width: 1080,
        height: 1920,
        frameRate: 30,
        bitrateMbps: 12,
        format: 'mp4',
        removeWatermark: false,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      NleExportPresetSpec(
        id: 'youtube_1920x1080_30',
        name: 'YouTube 1080p',
        description: 'Standard widescreen 1080p export.',
        platform: 'YouTube',
        width: 1920,
        height: 1080,
        frameRate: 30,
        bitrateMbps: 16,
        format: 'mp4',
        removeWatermark: false,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      NleExportPresetSpec(
        id: 'youtube_3840x2160_30',
        name: 'YouTube 4K',
        description: 'Premium 4K widescreen export.',
        platform: 'YouTube',
        width: 3840,
        height: 2160,
        frameRate: 30,
        bitrateMbps: 40,
        format: 'mp4',
        removeWatermark: false,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      NleExportPresetSpec(
        id: 'instagram_feed_1080x1350_30',
        name: 'Instagram Feed 4:5',
        description: 'Portrait feed export with strong mobile framing.',
        platform: 'Instagram',
        width: 1080,
        height: 1350,
        frameRate: 30,
        bitrateMbps: 12,
        format: 'mp4',
        removeWatermark: false,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      NleExportPresetSpec(
        id: 'cinema_3840x1646_24',
        name: 'Cinematic 21:9',
        description: 'Wide cinematic export for film-style projects.',
        platform: 'Cinema',
        width: 3840,
        height: 1646,
        frameRate: 24,
        bitrateMbps: 45,
        format: 'mp4',
        removeWatermark: false,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
