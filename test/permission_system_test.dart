import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';

void main() {
  group('AppPermissionState Tests', () {
    test('default unknown state has correct values', () {
      final state = AppPermissionState.unknown(AppPermissionType.microphone);

      expect(state.type, equals(AppPermissionType.microphone));
      expect(state.status, equals(AppPermissionStatusValue.unknown));
      expect(state.canRequestAgain, isTrue);
      expect(state.shouldOpenSettings, isFalse);
      expect(state.hasLimitedAccess, isFalse);
      expect(state.isGranted, isFalse);
      expect(state.isLimited, isFalse);
      expect(state.isDenied, isFalse);
      expect(state.isPermanentlyDenied, isFalse);
      expect(state.hasAccess, isFalse);
    });

    test('granted status evaluates correctly', () {
      final state = AppPermissionState(
        type: AppPermissionType.mediaLibrary,
        status: AppPermissionStatusValue.granted,
        canRequestAgain: false,
        shouldOpenSettings: false,
        hasLimitedAccess: false,
        checkedAt: DateTime.now(),
      );

      expect(state.isGranted, isTrue);
      expect(state.isLimited, isFalse);
      expect(state.isDenied, isFalse);
      expect(state.isPermanentlyDenied, isFalse);
      expect(state.hasAccess, isTrue);
    });

    test('limited status evaluates correctly', () {
      final state = AppPermissionState(
        type: AppPermissionType.mediaLibrary,
        status: AppPermissionStatusValue.limited,
        canRequestAgain: false,
        shouldOpenSettings: false,
        hasLimitedAccess: true,
        checkedAt: DateTime.now(),
      );

      expect(state.isGranted, isFalse);
      expect(state.isLimited, isTrue);
      expect(state.isDenied, isFalse);
      expect(state.isPermanentlyDenied, isFalse);
      expect(state.hasAccess, isTrue);
    });

    test('denied status evaluates correctly', () {
      final state = AppPermissionState(
        type: AppPermissionType.microphone,
        status: AppPermissionStatusValue.denied,
        canRequestAgain: true,
        shouldOpenSettings: false,
        hasLimitedAccess: false,
        checkedAt: DateTime.now(),
      );

      expect(state.isGranted, isFalse);
      expect(state.isLimited, isFalse);
      expect(state.isDenied, isTrue);
      expect(state.isPermanentlyDenied, isFalse);
      expect(state.hasAccess, isFalse);
    });

    test('permanentlyDenied status evaluates correctly', () {
      final state = AppPermissionState(
        type: AppPermissionType.notifications,
        status: AppPermissionStatusValue.permanentlyDenied,
        canRequestAgain: false,
        shouldOpenSettings: true,
        hasLimitedAccess: false,
        checkedAt: DateTime.now(),
      );

      expect(state.isGranted, isFalse);
      expect(state.isLimited, isFalse);
      expect(state.isDenied, isFalse);
      expect(state.isPermanentlyDenied, isTrue);
      expect(state.hasAccess, isFalse);
    });

    test('copyWith keeps or updates fields correctly', () {
      final initial = AppPermissionState.unknown(AppPermissionType.mediaLibrary);
      final updated = initial.copyWith(
        status: AppPermissionStatusValue.granted,
        canRequestAgain: false,
      );

      expect(updated.type, equals(AppPermissionType.mediaLibrary));
      expect(updated.status, equals(AppPermissionStatusValue.granted));
      expect(updated.canRequestAgain, isFalse);
      expect(updated.shouldOpenSettings, isFalse);
    });
  });

  group('AppPermissionPurposes Tests', () {
    test('returns correct purpose descriptions for mediaLibrary', () {
      final purpose = AppPermissionPurposes.forType(AppPermissionType.mediaLibrary);

      expect(purpose.title, contains('Import your media'));
      expect(purpose.primaryButton, equals('Allow Media Access'));
      expect(purpose.iconName, equals('video_library'));
    });

    test('returns correct purpose descriptions for microphone', () {
      final purpose = AppPermissionPurposes.forType(AppPermissionType.microphone);

      expect(purpose.title, contains('Record voiceover'));
      expect(purpose.primaryButton, equals('Allow Microphone'));
      expect(purpose.iconName, equals('mic'));
    });

    test('returns default purpose descriptions for unknown types', () {
      final purpose = AppPermissionPurposes.forType('non_existent_type');

      expect(purpose.title, equals('Permission needed'));
      expect(purpose.iconName, equals('lock'));
    });

    test('print PermissionRequestOption', () {
      print(PermissionRequestOption);
    });
  });
}
