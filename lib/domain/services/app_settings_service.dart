import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:nle_editor/domain/settings/app_settings.dart';

class AppSettingsService {
  Future<String> _settingsPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'app_settings.json');
  }

  Future<AppSettings> loadSettings() async {
    final path = await _settingsPath();
    final file = File(path);

    if (!await file.exists()) {
      final defaults = AppSettings.defaults();
      await saveSettings(defaults);
      return defaults;
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings.fromJson(decoded);
    } catch (_) {
      final defaults = AppSettings.defaults();
      await saveSettings(defaults);
      return defaults;
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final path = await _settingsPath();
    final file = File(path);

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
    );
  }

  Future<AppSettings> resetSettings() async {
    final defaults = AppSettings.defaults();
    await saveSettings(defaults);
    return defaults;
  }
}
