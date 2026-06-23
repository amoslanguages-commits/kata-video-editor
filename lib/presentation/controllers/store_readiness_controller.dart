import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreReadinessController extends StateNotifier<Set<String>> {
  StoreReadinessController() : super(const {}) {
    load();
  }

  static const _key = 'store_readiness_done_ids_v1';

  Set<String> get currentDoneIds => state;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_key) ?? const []).toSet();
  }

  Future<void> toggle(String id, bool checked) async {
    final next = {...state};

    if (checked) {
      next.add(id);
    } else {
      next.remove(id);
    }

    state = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  Future<void> reset() async {
    state = const {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
