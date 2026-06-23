import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:nle_editor/domain/device/device_capability_profile.dart';

class DeviceProfileStoreService {
  Future<String> _profilePath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'device_capability_profile.json');
  }

  Future<void> saveProfile(DeviceCapabilityProfile profile) async {
    final path = await _profilePath();
    final file = File(path);

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(profile.toJson()),
    );
  }

  Future<Map<String, dynamic>?> readRawProfile() async {
    final path = await _profilePath();
    final file = File(path);

    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();

    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearProfile() async {
    final path = await _profilePath();
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
