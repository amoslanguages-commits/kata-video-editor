import 'package:package_info_plus/package_info_plus.dart';

import 'package:nle_editor/core/config/app_config.dart';
import 'package:nle_editor/core/release/build_metadata.dart';

class BuildMetadataService {
  final AppConfig config;

  const BuildMetadataService({
    required this.config,
  });

  Future<BuildMetadata> load() async {
    final info = await PackageInfo.fromPlatform();

    return BuildMetadata(
      appName: info.appName,
      packageName: info.packageName,
      version: info.version,
      buildNumber: info.buildNumber,
      environment: config.environment.name,
      installerStore: info.installerStore ?? 'unknown',
      loadedAt: DateTime.now(),
    );
  }
}
