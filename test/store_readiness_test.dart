import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/core/store_readiness/store_metadata.dart';
import 'package:nle_editor/presentation/controllers/store_readiness_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoreListingText and StoreMetadataDrafts Tests', () {
    test('Converts drafts to markdown correctly', () {
      final listing = StoreMetadataDrafts.nleEditor;
      final markdown = listing.toMarkdown();

      expect(markdown, contains('# Kata'));
      expect(markdown, contains('## Short Description'));
      expect(markdown, contains('## Subtitle'));
      expect(markdown, contains('Offline creator video editor'));
      expect(markdown, contains('## Full Description'));
      expect(markdown, contains('Kata is a powerful offline-first mobile video editor'));
      expect(markdown, contains('## Keywords'));
      expect(markdown, contains('video editor, offline editor'));
      expect(markdown, contains('## Support'));
      expect(markdown, contains('support@example.com'));
      expect(markdown, contains('## Privacy Policy'));
      expect(markdown, contains('https://example.com/privacy'));
    });

    test('Serializes to JSON correctly', () {
      final listing = StoreMetadataDrafts.nleEditor;
      final json = listing.toJson();

      expect(json['appName'], equals('Kata'));
      expect(json['shortDescription'], contains('Premium offline video editor'));
      expect(json['subtitle'], equals('Offline creator video editor'));
      expect(json['supportEmail'], equals('support@example.com'));
      expect(json['privacyPolicyUrl'], equals('https://example.com/privacy'));
    });
  });

  group('StoreReadinessController Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes as empty, records toggles and persists', () async {
      final controller = StoreReadinessController();
      // Wait for constructor's load to complete
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.currentDoneIds, isEmpty);

      // Toggle item on
      await controller.toggle('play_app_name', true);
      expect(controller.currentDoneIds, contains('play_app_name'));

      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('store_readiness_done_ids_v1'), equals(['play_app_name']));

      // Toggle item off
      await controller.toggle('play_app_name', false);
      expect(controller.currentDoneIds, isEmpty);

      // Reset checklist
      await controller.toggle('ios_app_name', true);
      expect(controller.currentDoneIds, contains('ios_app_name'));
      await controller.reset();
      expect(controller.currentDoneIds, isEmpty);
    });
  });
}
