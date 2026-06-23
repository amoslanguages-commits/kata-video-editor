import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/core/haptics/haptic_service.dart';
import 'package:nle_editor/domain/onboarding/onboarding_state_service.dart';
import 'package:nle_editor/domain/polish/editor_hint_service.dart';

final hapticServiceProvider = Provider<HapticService>((ref) {
  return const HapticService();
});

final onboardingStateServiceProvider = Provider<OnboardingStateService>((ref) {
  return OnboardingStateService();
});

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingStateServiceProvider).hasSeenOnboarding();
});

final hasSeenFirstProjectGuideProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingStateServiceProvider).hasSeenFirstProjectGuide();
});

final editorHintServiceProvider = Provider<EditorHintService>((ref) {
  return EditorHintService();
});

final editorHintDismissedProvider =
    FutureProvider.family<bool, String>((ref, hintId) {
  return ref.watch(editorHintServiceProvider).isDismissed(hintId);
});

// UX Checklist State Notifier & Provider
final uxReviewChecklistProvider =
    StateNotifierProvider<UxReviewChecklistController, Set<String>>((ref) {
  return UxReviewChecklistController();
});

class UxReviewChecklistController extends StateNotifier<Set<String>> {
  UxReviewChecklistController() : super(const {}) {
    load();
  }

  static const _key = 'ux_review_checklist_done_ids_v1';

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
