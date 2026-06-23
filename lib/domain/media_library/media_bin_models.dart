class NleMediaBin {
  final String id;
  final String projectId;
  final String name;
  final String? parentBinId;
  final int sortIndex;
  final bool smartBin;
  final String? smartQuery;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const NleMediaBin({
    required this.id,
    required this.projectId,
    required this.name,
    this.parentBinId,
    required this.sortIndex,
    required this.smartBin,
    this.smartQuery,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory NleMediaBin.root({
    required String id,
    required String projectId,
  }) {
    final now = DateTime.now();

    return NleMediaBin(
      id: id,
      projectId: projectId,
      name: 'All Media',
      sortIndex: 0,
      smartBin: true,
      smartQuery: 'all',
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  factory NleMediaBin.defaultVideos({
    required String id,
    required String projectId,
  }) {
    final now = DateTime.now();

    return NleMediaBin(
      id: id,
      projectId: projectId,
      name: 'Videos',
      sortIndex: 1,
      smartBin: true,
      smartQuery: 'type:video',
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  factory NleMediaBin.defaultAudio({
    required String id,
    required String projectId,
  }) {
    final now = DateTime.now();

    return NleMediaBin(
      id: id,
      projectId: projectId,
      name: 'Audio',
      sortIndex: 2,
      smartBin: true,
      smartQuery: 'type:audio',
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  factory NleMediaBin.defaultImages({
    required String id,
    required String projectId,
  }) {
    final now = DateTime.now();

    return NleMediaBin(
      id: id,
      projectId: projectId,
      name: 'Images',
      sortIndex: 3,
      smartBin: true,
      smartQuery: 'type:image',
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  factory NleMediaBin.defaultUnused({
    required String id,
    required String projectId,
  }) {
    final now = DateTime.now();

    return NleMediaBin(
      id: id,
      projectId: projectId,
      name: 'Unused',
      sortIndex: 4,
      smartBin: true,
      smartQuery: 'usage:unused',
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'parentBinId': parentBinId,
      'sortIndex': sortIndex,
      'smartBin': smartBin,
      'smartQuery': smartQuery,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
    };
  }

  factory NleMediaBin.fromJson(Map<String, dynamic> json) {
    return NleMediaBin(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Bin',
      parentBinId: json['parentBinId']?.toString(),
      sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
      smartBin: json['smartBin'] == true,
      smartQuery: json['smartQuery']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class NleAssetBinLink {
  final String assetId;
  final String binId;
  final DateTime linkedAt;

  const NleAssetBinLink({
    required this.assetId,
    required this.binId,
    required this.linkedAt,
  });
}
