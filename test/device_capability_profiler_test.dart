import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/domain/services/device_capability_profiler_service.dart';
import 'package:nle_editor/native_bridge/fake_native_bridge.dart';

void main() {
  group('DeviceCapabilityProfilerService', () {
    test('uses native bridge capability events when available', () async {
      final bridge = FakeNativeBridge();
      await bridge.initialize();

      final profile = await DeviceCapabilityProfilerService().detectProfile(
        nativeBridge: bridge,
      );

      expect(profile.source, isNot('flutter_placeholder'));
      expect(profile.tier, 'flagship');
      expect(profile.codecSupport.h264Encode, isTrue);
      expect(profile.codecSupport.hevcEncode, isTrue);

      await bridge.dispose();
    });

    test('falls back to a conservative Flutter profile without native bridge',
        () async {
      final profile = await DeviceCapabilityProfilerService().detectProfile();

      expect(profile.source, 'flutter_placeholder');
      expect(profile.codecSupport.h264Decode, isTrue);
      expect(profile.limits.safePreviewHeight, greaterThanOrEqualTo(540));
    });
  });
}
