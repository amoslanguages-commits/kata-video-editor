enum MediaSourcePolicy {
  original,
  proxy,
  automatic,
}

class CanonicalMediaPathSelection {
  final String assetId;
  final String? originalPath;
  final String? projectPath;
  final String? proxyPath;
  final String? resolvedPath;
  final MediaSourcePolicy sourcePolicy;
  final bool usedProxy;

  const CanonicalMediaPathSelection({
    required this.assetId,
    required this.originalPath,
    required this.projectPath,
    required this.proxyPath,
    required this.resolvedPath,
    required this.sourcePolicy,
    required this.usedProxy,
  });

  bool get hasResolvedPath => resolvedPath != null && resolvedPath!.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'assetId': assetId,
        'originalPath': originalPath,
        'projectPath': projectPath,
        'proxyPath': proxyPath,
        'resolvedPath': resolvedPath,
        'sourcePolicy': sourcePolicy.name,
        'usedProxy': usedProxy,
      };
}

class CanonicalMediaPathResolver {
  const CanonicalMediaPathResolver();

  CanonicalMediaPathSelection resolve({
    required String assetId,
    required String? originalPath,
    required String? projectPath,
    required String? proxyPath,
    required MediaSourcePolicy policy,
  }) {
    final cleanOriginal = _clean(projectPath) ?? _clean(originalPath);
    final cleanProxy = _clean(proxyPath);
    switch (policy) {
      case MediaSourcePolicy.original:
        return CanonicalMediaPathSelection(
          assetId: assetId,
          originalPath: _clean(originalPath),
          projectPath: _clean(projectPath),
          proxyPath: cleanProxy,
          resolvedPath: cleanOriginal,
          sourcePolicy: policy,
          usedProxy: false,
        );
      case MediaSourcePolicy.proxy:
        return CanonicalMediaPathSelection(
          assetId: assetId,
          originalPath: _clean(originalPath),
          projectPath: _clean(projectPath),
          proxyPath: cleanProxy,
          resolvedPath: cleanProxy ?? cleanOriginal,
          sourcePolicy: policy,
          usedProxy: cleanProxy != null,
        );
      case MediaSourcePolicy.automatic:
        return CanonicalMediaPathSelection(
          assetId: assetId,
          originalPath: _clean(originalPath),
          projectPath: _clean(projectPath),
          proxyPath: cleanProxy,
          resolvedPath: cleanProxy ?? cleanOriginal,
          sourcePolicy: policy,
          usedProxy: cleanProxy != null,
        );
    }
  }

  String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
