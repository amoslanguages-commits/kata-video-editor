import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/domain/film_look/film_look_models.dart';
import 'package:nle_editor/domain/film_look/film_stock_presets.dart';

void main() {
  group('Film Look Models', () {
    test('NleFilmGrainSettings toJson/fromJson roundtrip', () {
      const settings = NleFilmGrainSettings(
        enabled: true,
        amount: 0.8,
        softness: 0.2,
        size: NleFilmGrainSize.coarse,
        monochrome: true,
        responseToLuma: 0.4,
      );
      final json = settings.toJson();
      final decoded = NleFilmGrainSettings.fromJson(json);
      expect(decoded.enabled, isTrue);
      expect(decoded.amount, 0.8);
      expect(decoded.softness, 0.2);
      expect(decoded.size, NleFilmGrainSize.coarse);
      expect(decoded.monochrome, isTrue);
      expect(decoded.responseToLuma, 0.4);
    });

    test('NleHalationSettings toJson/fromJson roundtrip', () {
      const settings = NleHalationSettings(
        enabled: true,
        amount: 0.7,
        threshold: 0.5,
        radius: 0.6,
        redBias: 0.8,
        warmth: 0.9,
      );
      final json = settings.toJson();
      final decoded = NleHalationSettings.fromJson(json);
      expect(decoded.enabled, isTrue);
      expect(decoded.amount, 0.7);
      expect(decoded.threshold, 0.5);
      expect(decoded.radius, 0.6);
      expect(decoded.redBias, 0.8);
      expect(decoded.warmth, 0.9);
    });

    test('NleBloomSettings toJson/fromJson roundtrip', () {
      const settings = NleBloomSettings(
        enabled: true,
        amount: 0.6,
        threshold: 0.4,
        radius: 0.5,
        softness: 0.7,
      );
      final json = settings.toJson();
      final decoded = NleBloomSettings.fromJson(json);
      expect(decoded.enabled, isTrue);
      expect(decoded.amount, 0.6);
      expect(decoded.threshold, 0.4);
      expect(decoded.radius, 0.5);
      expect(decoded.softness, 0.7);
    });

    test('NlePrintSettings toJson/fromJson roundtrip', () {
      const settings = NlePrintSettings(
        enabled: true,
        contrast: 1.2,
        toe: 0.1,
        shoulder: 0.2,
        fade: 0.05,
        saturation: 1.1,
        highlightRolloff: 0.4,
        shadowTint: 0.02,
        highlightWarmth: -0.01,
      );
      final json = settings.toJson();
      final decoded = NlePrintSettings.fromJson(json);
      expect(decoded.enabled, isTrue);
      expect(decoded.contrast, 1.2);
      expect(decoded.toe, 0.1);
      expect(decoded.shoulder, 0.2);
      expect(decoded.fade, 0.05);
      expect(decoded.saturation, 1.1);
      expect(decoded.highlightRolloff, 0.4);
      expect(decoded.shadowTint, 0.02);
      expect(decoded.highlightWarmth, -0.01);
    });

    test('NleVignetteSettings toJson/fromJson roundtrip', () {
      const settings = NleVignetteSettings(
        enabled: true,
        amount: -0.5,
        radius: 0.8,
        feather: 0.6,
        roundness: 0.9,
      );
      final json = settings.toJson();
      final decoded = NleVignetteSettings.fromJson(json);
      expect(decoded.enabled, isTrue);
      expect(decoded.amount, -0.5);
      expect(decoded.radius, 0.8);
      expect(decoded.feather, 0.6);
      expect(decoded.roundness, 0.9);
    });

    test('NleGateWeaveSettings toJson/fromJson roundtrip', () {
      const settings = NleGateWeaveSettings(
        enabled: true,
        amount: 0.3,
        frequency: 1.2,
        rotation: 0.05,
      );
      final json = settings.toJson();
      final decoded = NleGateWeaveSettings.fromJson(json);
      expect(decoded.enabled, isTrue);
      expect(decoded.amount, 0.3);
      expect(decoded.frequency, 1.2);
      expect(decoded.rotation, 0.05);
    });

    test('NleFilmLookSettings identity works', () {
      const settings = NleFilmLookSettings.identity();
      expect(settings.enabled, isFalse);
      expect(settings.intensity, 1.0);
      expect(settings.preset, NleFilmStockPreset.neutral);
      expect(settings.isIdentity, isTrue);
    });

    test('NleFilmLookSettings non-identity works', () {
      const settings = NleFilmLookSettings(
        enabled: true,
        intensity: 0.5,
        preset: NleFilmStockPreset.kodak2383,
        placement: NleFilmLookPlacement.beforeLut,
        grain: NleFilmGrainSettings.identity(),
        halation: NleHalationSettings.identity(),
        bloom: NleBloomSettings.identity(),
        print: NlePrintSettings.identity(),
        vignette: NleVignetteSettings.identity(),
        gateWeave: NleGateWeaveSettings.identity(),
        chromaticSoftness: 0.1,
      );
      expect(settings.isIdentity, isFalse);
    });
  });

  group('Film Stock Presets', () {
    test('Preset lookup returns correct preset stock', () {
      const presets = FilmStockPresets();
      final kodak = presets.preset(NleFilmStockPreset.kodak2383);
      expect(kodak.preset, equals(NleFilmStockPreset.kodak2383));
      expect(kodak.enabled, isTrue);
    });
  });
}
