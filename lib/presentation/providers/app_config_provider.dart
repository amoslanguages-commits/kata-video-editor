import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/config/app_config.dart';
import 'package:nle_editor/core/config/app_environment.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.forEnvironment(AppEnvironment.dev);
});
