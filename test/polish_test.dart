import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/core/copy/app_copy.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/onboarding/onboarding_state_service.dart';
import 'package:nle_editor/domain/polish/editor_hint.dart';
import 'package:nle_editor/domain/polish/editor_hint_service.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // OnboardingStateService
  // ---------------------------------------------------------------------------

  group('OnboardingStateService Tests', () {
    late OnboardingStateService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = OnboardingStateService();
    });

    test('hasSeenOnboarding returns false by default', () async {
      expect(await service.hasSeenOnboarding(), isFalse);
    });

    test('markOnboardingSeen persists to prefs', () async {
      await service.markOnboardingSeen();
      expect(await service.hasSeenOnboarding(), isTrue);
    });

    test('hasSeenFirstProjectGuide returns false by default', () async {
      expect(await service.hasSeenFirstProjectGuide(), isFalse);
    });

    test('markFirstProjectGuideSeen persists to prefs', () async {
      await service.markFirstProjectGuideSeen();
      expect(await service.hasSeenFirstProjectGuide(), isTrue);
    });

    test('resetForTesting clears both flags', () async {
      await service.markOnboardingSeen();
      await service.markFirstProjectGuideSeen();

      await service.resetForTesting();

      expect(await service.hasSeenOnboarding(), isFalse);
      expect(await service.hasSeenFirstProjectGuide(), isFalse);
    });

    test('second markOnboardingSeen call is idempotent', () async {
      await service.markOnboardingSeen();
      await service.markOnboardingSeen();
      expect(await service.hasSeenOnboarding(), isTrue);
    });

    test('both flags can be set independently', () async {
      await service.markOnboardingSeen();
      // guide not yet marked
      expect(await service.hasSeenOnboarding(), isTrue);
      expect(await service.hasSeenFirstProjectGuide(), isFalse);

      await service.markFirstProjectGuideSeen();
      expect(await service.hasSeenFirstProjectGuide(), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // EditorHintService
  // ---------------------------------------------------------------------------

  group('EditorHintService Tests', () {
    late EditorHintService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = EditorHintService();
    });

    test('isDismissed returns false for a new hint', () async {
      expect(await service.isDismissed(EditorHintId.importMedia), isFalse);
    });

    test('dismiss marks hint as dismissed', () async {
      await service.dismiss(EditorHintId.importMedia);
      expect(await service.isDismissed(EditorHintId.importMedia), isTrue);
    });

    test('dismissing one hint does not affect others', () async {
      await service.dismiss(EditorHintId.importMedia);

      expect(await service.isDismissed(EditorHintId.importMedia), isTrue);
      expect(await service.isDismissed(EditorHintId.dragToTimeline), isFalse);
      expect(await service.isDismissed(EditorHintId.exportVideo), isFalse);
    });

    test('reset clears all dismissed hints', () async {
      await service.dismiss(EditorHintId.importMedia);
      await service.dismiss(EditorHintId.addText);
      await service.dismiss(EditorHintId.exportVideo);

      await service.reset();

      expect(await service.isDismissed(EditorHintId.importMedia), isFalse);
      expect(await service.isDismissed(EditorHintId.addText), isFalse);
      expect(await service.isDismissed(EditorHintId.exportVideo), isFalse);
    });

    test('isDismissed is false by default for all catalog hints', () async {
      for (final hint in EditorHintCatalog.hints) {
        expect(
          await service.isDismissed(hint.id),
          isFalse,
          reason: 'Expected hint "${hint.id}" to be undismissed by default',
        );
      }
    });

    test('multiple dismiss calls are idempotent', () async {
      await service.dismiss(EditorHintId.generateProxy);
      await service.dismiss(EditorHintId.generateProxy);
      expect(await service.isDismissed(EditorHintId.generateProxy), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // EditorHintCatalog
  // ---------------------------------------------------------------------------

  group('EditorHintCatalog Tests', () {
    test('catalog contains all defined hint ids', () {
      final ids = EditorHintCatalog.hints.map((h) => h.id).toSet();

      expect(ids, contains(EditorHintId.importMedia));
      expect(ids, contains(EditorHintId.dragToTimeline));
      expect(ids, contains(EditorHintId.addText));
      expect(ids, contains(EditorHintId.generateProxy));
      expect(ids, contains(EditorHintId.exportVideo));
      expect(ids, contains(EditorHintId.diagnostics));
    });

    test('all hints have non-empty title, message, and actionLabel', () {
      for (final hint in EditorHintCatalog.hints) {
        expect(hint.title, isNotEmpty, reason: 'hint ${hint.id} title is empty');
        expect(hint.message, isNotEmpty, reason: 'hint ${hint.id} message is empty');
        expect(hint.actionLabel, isNotEmpty, reason: 'hint ${hint.id} actionLabel is empty');
      }
    });

    test('byId returns correct hint', () {
      final hint = EditorHintCatalog.byId(EditorHintId.importMedia);
      expect(hint, isNotNull);
      expect(hint!.id, equals(EditorHintId.importMedia));
    });

    test('byId returns null for unknown id', () {
      expect(EditorHintCatalog.byId('nonexistent_hint_xyz'), isNull);
    });

    test('all catalog hint ids are unique', () {
      final ids = EditorHintCatalog.hints.map((h) => h.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, equals(uniqueIds.length));
    });

    test('byId returns the expected hint for each catalog entry', () {
      for (final hint in EditorHintCatalog.hints) {
        final found = EditorHintCatalog.byId(hint.id);
        expect(found, isNotNull);
        expect(found!.id, equals(hint.id));
        expect(found.title, equals(hint.title));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // UxReviewChecklistController
  // ---------------------------------------------------------------------------

  group('UxReviewChecklistController Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is empty set', () {
      final controller = UxReviewChecklistController();
      // State is initially empty (async load pending but not yet resolved).
      expect(controller.state, isEmpty);
    });

    test('toggle adds item to state', () async {
      final controller = UxReviewChecklistController();
      // Let the constructor's async load() complete before mutating.
      await Future<void>.delayed(Duration.zero);

      await controller.toggle('item_a', true);
      expect(controller.state, contains('item_a'));
    });

    test('toggle removes item from state', () async {
      final controller = UxReviewChecklistController();
      await Future<void>.delayed(Duration.zero);

      await controller.toggle('item_a', true);
      await controller.toggle('item_a', false);
      expect(controller.state, isNot(contains('item_a')));
    });

    test('toggle persists across reload', () async {
      final controller = UxReviewChecklistController();
      await Future<void>.delayed(Duration.zero);

      await controller.toggle('item_b', true);
      await controller.toggle('item_c', true);

      // Simulate app restart by creating a new controller (same shared prefs)
      final controller2 = UxReviewChecklistController();
      await Future<void>.delayed(Duration.zero);

      expect(controller2.state, containsAll(['item_b', 'item_c']));
    });

    test('reset clears all items', () async {
      final controller = UxReviewChecklistController();
      await Future<void>.delayed(Duration.zero);

      await controller.toggle('item_a', true);
      await controller.toggle('item_b', true);

      await controller.reset();

      expect(controller.state, isEmpty);
    });

    test('reset clears persisted state', () async {
      final controller = UxReviewChecklistController();
      await Future<void>.delayed(Duration.zero);

      await controller.toggle('item_x', true);
      await controller.reset();

      final controller2 = UxReviewChecklistController();
      await Future<void>.delayed(Duration.zero);

      expect(controller2.state, isEmpty);
    });

    test('multiple toggles on different items accumulate', () async {
      final controller = UxReviewChecklistController();
      await Future<void>.delayed(Duration.zero);

      await controller.toggle('alpha', true);
      await controller.toggle('beta', true);
      await controller.toggle('gamma', true);

      expect(controller.state.length, equals(3));
      expect(controller.state, containsAll(['alpha', 'beta', 'gamma']));
    });
  });

  // ---------------------------------------------------------------------------
  // PremiumSpacing / PremiumRadius / PremiumMotion Design Tokens
  // ---------------------------------------------------------------------------

  group('Design Token Tests', () {
    test('PremiumSpacing tokens are ordered ascending', () {
      expect(PremiumSpacing.xs, lessThan(PremiumSpacing.sm));
      expect(PremiumSpacing.sm, lessThan(PremiumSpacing.md));
      expect(PremiumSpacing.md, lessThan(PremiumSpacing.lg));
      expect(PremiumSpacing.lg, lessThan(PremiumSpacing.xl));
      expect(PremiumSpacing.xl, lessThan(PremiumSpacing.xxl));
    });

    test('PremiumSpacing tokens are all positive', () {
      expect(PremiumSpacing.xs, greaterThan(0));
      expect(PremiumSpacing.sm, greaterThan(0));
      expect(PremiumSpacing.md, greaterThan(0));
      expect(PremiumSpacing.lg, greaterThan(0));
      expect(PremiumSpacing.xl, greaterThan(0));
      expect(PremiumSpacing.xxl, greaterThan(0));
    });

    test('PremiumRadius tokens are all positive', () {
      expect(PremiumRadius.sm, greaterThan(0));
      expect(PremiumRadius.md, greaterThan(0));
      expect(PremiumRadius.lg, greaterThan(0));
      expect(PremiumRadius.xl, greaterThan(0));
      expect(PremiumRadius.pill, greaterThan(0));
    });

    test('PremiumRadius tokens are ordered ascending (sm < md < lg < xl)', () {
      expect(PremiumRadius.sm, lessThanOrEqualTo(PremiumRadius.md));
      expect(PremiumRadius.md, lessThanOrEqualTo(PremiumRadius.lg));
      expect(PremiumRadius.lg, lessThanOrEqualTo(PremiumRadius.xl));
    });

    test('PremiumMotion durations are non-zero', () {
      expect(PremiumMotion.fast.inMilliseconds, greaterThan(0));
      expect(PremiumMotion.normal.inMilliseconds, greaterThan(0));
      expect(PremiumMotion.slow.inMilliseconds, greaterThan(0));
    });

    test('PremiumMotion durations are ordered fast < normal < slow', () {
      expect(
        PremiumMotion.fast.inMilliseconds,
        lessThan(PremiumMotion.normal.inMilliseconds),
      );
      expect(
        PremiumMotion.normal.inMilliseconds,
        lessThan(PremiumMotion.slow.inMilliseconds),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // AppCopy Constants
  // ---------------------------------------------------------------------------

  group('AppCopy Constants Tests', () {
    test('onboarding copy strings are non-empty', () {
      expect(AppCopy.onboardingTitle1, isNotEmpty);
      expect(AppCopy.onboardingBody1, isNotEmpty);
      expect(AppCopy.onboardingTitle2, isNotEmpty);
      expect(AppCopy.onboardingBody2, isNotEmpty);
      expect(AppCopy.onboardingTitle3, isNotEmpty);
      expect(AppCopy.onboardingBody3, isNotEmpty);
    });

    test('export copy strings are non-empty', () {
      expect(AppCopy.exportSuccessTitle, isNotEmpty);
      expect(AppCopy.exportSuccessBody, isNotEmpty);
    });

    test('empty state copy strings are non-empty', () {
      expect(AppCopy.emptyProjectsTitle, isNotEmpty);
      expect(AppCopy.emptyProjectsBody, isNotEmpty);
      expect(AppCopy.emptyMediaTitle, isNotEmpty);
      expect(AppCopy.emptyMediaBody, isNotEmpty);
      expect(AppCopy.emptyTimelineTitle, isNotEmpty);
      expect(AppCopy.emptyTimelineBody, isNotEmpty);
    });

    test('create project copy strings are non-empty', () {
      expect(AppCopy.createFirstProject, isNotEmpty);
      expect(AppCopy.createProjectSubtitle, isNotEmpty);
      expect(AppCopy.createProject, isNotEmpty);
    });

    test('action copy strings are non-empty', () {
      expect(AppCopy.retry, isNotEmpty);
      expect(AppCopy.continueText, isNotEmpty);
      expect(AppCopy.getStarted, isNotEmpty);
      expect(AppCopy.importMedia, isNotEmpty);
      expect(AppCopy.openDiagnostics, isNotEmpty);
    });

    test('error copy strings are non-empty', () {
      expect(AppCopy.somethingWentWrong, isNotEmpty);
    });

    test('no AppCopy field is only whitespace', () {
      final copies = [
        AppCopy.onboardingTitle1,
        AppCopy.onboardingBody1,
        AppCopy.onboardingTitle2,
        AppCopy.onboardingBody2,
        AppCopy.onboardingTitle3,
        AppCopy.onboardingBody3,
        AppCopy.createFirstProject,
        AppCopy.createProjectSubtitle,
        AppCopy.emptyProjectsTitle,
        AppCopy.emptyProjectsBody,
        AppCopy.emptyMediaTitle,
        AppCopy.emptyMediaBody,
        AppCopy.emptyTimelineTitle,
        AppCopy.emptyTimelineBody,
        AppCopy.exportSuccessTitle,
        AppCopy.exportSuccessBody,
        AppCopy.somethingWentWrong,
        AppCopy.retry,
        AppCopy.continueText,
        AppCopy.getStarted,
        AppCopy.createProject,
        AppCopy.importMedia,
        AppCopy.openDiagnostics,
      ];

      for (final copy in copies) {
        expect(copy.trim(), isNotEmpty, reason: '"$copy" is only whitespace');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // EditorHintId Constants
  // ---------------------------------------------------------------------------

  group('EditorHintId Constant Tests', () {
    test('all hint ID strings are non-empty and snake_case', () {
      final ids = [
        EditorHintId.importMedia,
        EditorHintId.dragToTimeline,
        EditorHintId.addText,
        EditorHintId.generateProxy,
        EditorHintId.exportVideo,
        EditorHintId.diagnostics,
      ];

      for (final id in ids) {
        expect(id, isNotEmpty);
        expect(id, isNot(contains(' ')));
        // Should only contain lowercase letters, digits, and underscores.
        expect(RegExp(r'^[a-z0-9_]+$').hasMatch(id), isTrue,
            reason: 'EditorHintId "$id" contains unexpected characters');
      }
    });

    test('all hint IDs are unique', () {
      final ids = [
        EditorHintId.importMedia,
        EditorHintId.dragToTimeline,
        EditorHintId.addText,
        EditorHintId.generateProxy,
        EditorHintId.exportVideo,
        EditorHintId.diagnostics,
      ];
      expect(ids.toSet().length, equals(ids.length));
    });
  });
}
