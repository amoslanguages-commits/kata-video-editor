import 'package:permission_handler/permission_handler.dart';

class MicrophonePermissionService {
  const MicrophonePermissionService();

  Future<bool> hasPermission() async {
    return Permission.microphone.isGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> ensurePermission() async {
    if (await hasPermission()) return true;
    return requestPermission();
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
