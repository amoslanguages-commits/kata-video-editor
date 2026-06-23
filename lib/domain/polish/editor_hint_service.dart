import 'package:shared_preferences/shared_preferences.dart';

class EditorHintService {
  static const _dismissedPrefix = 'editor_hint_dismissed_v1_';

  Future<bool> isDismissed(String hintId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_dismissedPrefix$hintId') ?? false;
  }

  Future<void> dismiss(String hintId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_dismissedPrefix$hintId', true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in prefs.getKeys()) {
      if (key.startsWith(_dismissedPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
