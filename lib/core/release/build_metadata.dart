class BuildMetadata {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String environment;
  final String installerStore;
  final DateTime loadedAt;

  const BuildMetadata({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.environment,
    required this.installerStore,
    required this.loadedAt,
  });

  String get fullVersion => '$version+$buildNumber';

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'packageName': packageName,
      'version': version,
      'buildNumber': buildNumber,
      'fullVersion': fullVersion,
      'environment': environment,
      'installerStore': installerStore,
      'loadedAt': loadedAt.toIso8601String(),
    };
  }
}
