import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';

void main() {
  group('Color Scopes Domain Models & Serialization', () {
    test('Default NleScopeSettings', () {
      const settings = NleScopeSettings.defaultMobile();
      expect(settings.enabled, isTrue);
      expect(settings.activeType, equals(NleScopeType.waveform));
      expect(settings.source, equals(NleScopeSource.programPreview));
      expect(settings.colorSpace, equals(NleScopeColorSpace.displayReferred));
      expect(settings.showSkinToneLine, isTrue);
      expect(settings.showClippingWarnings, isTrue);
      expect(settings.showGrid, isTrue);
      expect(settings.showOverlay, isFalse);
      expect(settings.refreshFps, equals(12.0));
      expect(settings.sampleWidth, equals(256));
      expect(settings.sampleHeight, equals(144));
    });

    test('NleScopeSettings JSON serialization roundtrip', () {
      const settings = NleScopeSettings(
        enabled: true,
        activeType: NleScopeType.rgbParade,
        source: NleScopeSource.sourcePreview,
        colorSpace: NleScopeColorSpace.sceneLinear,
        showSkinToneLine: false,
        showClippingWarnings: false,
        showGrid: false,
        showOverlay: true,
        refreshFps: 24.0,
        sampleWidth: 128,
        sampleHeight: 72,
      );

      final json = settings.toJson();
      final decoded = NleScopeSettings.fromJson(json);

      expect(decoded.enabled, isTrue);
      expect(decoded.activeType, equals(NleScopeType.rgbParade));
      expect(decoded.source, equals(NleScopeSource.sourcePreview));
      expect(decoded.colorSpace, equals(NleScopeColorSpace.sceneLinear));
      expect(decoded.showSkinToneLine, isFalse);
      expect(decoded.showClippingWarnings, isFalse);
      expect(decoded.showGrid, isFalse);
      expect(decoded.showOverlay, isTrue);
      expect(decoded.refreshFps, equals(24.0));
      expect(decoded.sampleWidth, equals(128));
      expect(decoded.sampleHeight, equals(72));
    });

    test('NleScopeFrameData JSON serialization roundtrip', () {
      final json = {
        'frameTimestampMicros': 500000,
        'sampleWidth': 128,
        'sampleHeight': 72,
        'waveform': [
          {'x': 0.1, 'y': 0.2, 'intensity': 0.5},
          {'x': 0.5, 'y': 0.6, 'intensity': 0.8},
        ],
        'rgbParade': [
          {'x': 0.1, 'y': 0.2, 'red': 0.5, 'green': 0.4, 'blue': 0.3},
        ],
        'vectorscope': [
          {'x': -0.1, 'y': 0.2, 'intensity': 0.4},
        ],
        'histogram': {
          'luma': [0.1, 0.2, 0.3],
          'red': [0.4, 0.5, 0.6],
          'green': [0.7, 0.8, 0.9],
          'blue': [0.2, 0.4, 0.6],
        },
        'warnings': {
          'blackClipping': true,
          'whiteClipping': false,
          'redChannelClipping': true,
          'greenChannelClipping': false,
          'blueChannelClipping': false,
          'overSaturated': true,
          'blackClipPercent': 1.2,
          'whiteClipPercent': 0.0,
          'redClipPercent': 0.8,
          'greenClipPercent': 0.0,
          'blueClipPercent': 0.0,
          'saturationWarningPercent': 2.5,
        },
      };

      final frameData = NleScopeFrameData.fromJson(json);

      expect(frameData.frameTimestampMicros, equals(500000));
      expect(frameData.sampleWidth, equals(128));
      expect(frameData.sampleHeight, equals(72));

      expect(frameData.waveform.length, equals(2));
      expect(frameData.waveform[0].x, equals(0.1));
      expect(frameData.waveform[0].y, equals(0.2));
      expect(frameData.waveform[0].intensity, equals(0.5));

      expect(frameData.rgbParade.length, equals(1));
      expect(frameData.rgbParade[0].red, equals(0.5));

      expect(frameData.vectorscope.length, equals(1));
      expect(frameData.vectorscope[0].x, equals(-0.1));

      expect(frameData.histogram.luma, equals([0.1, 0.2, 0.3]));
      expect(frameData.histogram.green, equals([0.7, 0.8, 0.9]));

      expect(frameData.warnings.blackClipping, isTrue);
      expect(frameData.warnings.whiteClipping, isFalse);
      expect(frameData.warnings.redChannelClipping, isTrue);
      expect(frameData.warnings.overSaturated, isTrue);
      expect(frameData.warnings.blackClipPercent, equals(1.2));
      expect(frameData.warnings.saturationWarningPercent, equals(2.5));
      expect(frameData.warnings.hasAnyWarning, isTrue);
    });

    test('NleClippingWarnings.none initialization', () {
      final warnings = NleClippingWarnings.none();
      expect(warnings.hasAnyWarning, isFalse);
      expect(warnings.blackClipping, isFalse);
      expect(warnings.whiteClipping, isFalse);
      expect(warnings.redChannelClipping, isFalse);
      expect(warnings.greenChannelClipping, isFalse);
      expect(warnings.blueChannelClipping, isFalse);
      expect(warnings.overSaturated, isFalse);
      expect(warnings.blackClipPercent, equals(0.0));
      expect(warnings.whiteClipPercent, equals(0.0));
    });
  });
}
