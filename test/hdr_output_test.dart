// test/hdr_output_test.dart
//
// 30J-PRO: Unit tests verifying HDR settings, fallback resolutions,
// and data pipeline serialization.

import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/domain/color_output/hdr_output_models.dart';
import 'package:nle_editor/domain/rendering/render_graph_hdr_output_dto.dart';

void main() {
  group('HDR Output Models & DTOs', () {
    test('NleHdrOutputSettings default settings matchBT.2020 foundation', () {
      final settings = NleHdrOutputSettings.defaultSettings();
      expect(settings.colorMode, equals(NleOutputColorMode.rec709Sdr));
      expect(settings.transferFunction, equals(NleHdrTransferFunction.sdr));
      expect(settings.bitDepth, equals(NleOutputBitDepth.eightBit));
      expect(settings.targetPeakNits, equals(1000.0));
      expect(settings.masteringMetadata.maxDisplayMasteringLuminance, equals(1000.0));
      expect(settings.masteringMetadata.primaryRedX, equals(0.708));
    });

    test('NleHdrOutputSettings toJson / fromJson roundtrip matchesBT.2020 foundation', () {
      final settings = NleHdrOutputSettings(
        colorMode: NleOutputColorMode.rec2020PqHdr,
        transferFunction: NleHdrTransferFunction.pq,
        toneMapOperator: NleToneMapOperator.acesApprox,
        metadataMode: NleHdrMetadataMode.hdr10Static,
        colorRange: NleColorRangeMode.full,
        bitDepth: NleOutputBitDepth.tenBit,
        previewMode: NleWideColorPreviewMode.hdrPreview,
        targetPeakNits: 2000.0,
        masteringMetadata: const NleHdrMasteringDisplayMetadata(
          maxDisplayMasteringLuminance: 2000.0,
          minDisplayMasteringLuminance: 0.001,
          maxContentLightLevel: 2000.0,
          maxFrameAverageLightLevel: 800.0,
        ),
      );

      final json = settings.toJson();
      final decoded = NleHdrOutputSettings.fromJson(json);

      expect(decoded.colorMode, equals(NleOutputColorMode.rec2020PqHdr));
      expect(decoded.transferFunction, equals(NleHdrTransferFunction.pq));
      expect(decoded.toneMapOperator, equals(NleToneMapOperator.acesApprox));
      expect(decoded.metadataMode, equals(NleHdrMetadataMode.hdr10Static));
      expect(decoded.colorRange, equals(NleColorRangeMode.full));
      expect(decoded.bitDepth, equals(NleOutputBitDepth.tenBit));
      expect(decoded.previewMode, equals(NleWideColorPreviewMode.hdrPreview));
      expect(decoded.targetPeakNits, equals(2000.0));
      expect(decoded.masteringMetadata.maxDisplayMasteringLuminance, equals(2000.0));
      expect(decoded.masteringMetadata.minDisplayMasteringLuminance, equals(0.001));
      expect(decoded.masteringMetadata.maxContentLightLevel, equals(2000.0));
      expect(decoded.masteringMetadata.maxFrameAverageLightLevel, equals(800.0));
    });

    test('RenderGraphHdrOutputDto matches settings serialization structure', () {
      final settings = NleHdrOutputSettings.defaultSettings();
      final dto = RenderGraphHdrOutputDto(settings: settings);
      final json = dto.toJson();

      expect(json['colorMode'], equals('rec709Sdr'));
      expect(json['transferFunction'], equals('sdr'));
      expect(json['toneMapOperator'], equals('none'));
      expect(json['targetPeakNits'], equals(1000.0));
      expect(json['masteringMetadata'], isA<Map>());
    });
  });

  group('HDR Fallback Resolution Rules', () {
    test('resolveFallbackMode with complete hardware support returns target mode', () {
      final settings = const NleHdrOutputSettings(
        colorMode: NleOutputColorMode.rec2020PqHdr,
        transferFunction: NleHdrTransferFunction.pq,
        toneMapOperator: NleToneMapOperator.none,
        metadataMode: NleHdrMetadataMode.none,
        colorRange: NleColorRangeMode.auto,
        bitDepth: NleOutputBitDepth.tenBit,
        previewMode: NleWideColorPreviewMode.auto,
        targetPeakNits: 1000.0,
        masteringMetadata: NleHdrMasteringDisplayMetadata(),
      );

      const capability = NleHdrDeviceCapability(
        displaySupportsHdr: true,
        displaySupportsWideColor: true,
        displayMaxNits: 1000.0,
        encoderSupportsHdrHlg: true,
        encoderSupportsHdrPq: true,
        encoderSupportsWideColorP3: true,
        encoderSupportsTenBit: true,
      );

      final resolved = settings.resolveFallbackMode(capability);
      expect(resolved, equals(NleOutputColorMode.rec2020PqHdr));
    });

    test('resolveFallbackMode with no PQ encoder support falls back to Display P3 if supported', () {
      final settings = const NleHdrOutputSettings(
        colorMode: NleOutputColorMode.rec2020PqHdr,
        transferFunction: NleHdrTransferFunction.pq,
        toneMapOperator: NleToneMapOperator.none,
        metadataMode: NleHdrMetadataMode.none,
        colorRange: NleColorRangeMode.auto,
        bitDepth: NleOutputBitDepth.tenBit,
        previewMode: NleWideColorPreviewMode.auto,
        targetPeakNits: 1000.0,
        masteringMetadata: NleHdrMasteringDisplayMetadata(),
      );

      const capability = NleHdrDeviceCapability(
        displaySupportsHdr: true,
        displaySupportsWideColor: true,
        displayMaxNits: 1000.0,
        encoderSupportsHdrHlg: false,
        encoderSupportsHdrPq: false,
        encoderSupportsWideColorP3: true,
        encoderSupportsTenBit: true,
      );

      final resolved = settings.resolveFallbackMode(capability);
      expect(resolved, equals(NleOutputColorMode.displayP3Sdr));
    });

    test('resolveFallbackMode with no PQ/HLG and no P3 support falls back to Rec 709 SDR', () {
      final settings = const NleHdrOutputSettings(
        colorMode: NleOutputColorMode.rec2020PqHdr,
        transferFunction: NleHdrTransferFunction.pq,
        toneMapOperator: NleToneMapOperator.none,
        metadataMode: NleHdrMetadataMode.none,
        colorRange: NleColorRangeMode.auto,
        bitDepth: NleOutputBitDepth.tenBit,
        previewMode: NleWideColorPreviewMode.auto,
        targetPeakNits: 1000.0,
        masteringMetadata: NleHdrMasteringDisplayMetadata(),
      );

      const capability = NleHdrDeviceCapability(
        displaySupportsHdr: false,
        displaySupportsWideColor: false,
        displayMaxNits: 300.0,
        encoderSupportsHdrHlg: false,
        encoderSupportsHdrPq: false,
        encoderSupportsWideColorP3: false,
        encoderSupportsTenBit: false,
      );

      final resolved = settings.resolveFallbackMode(capability);
      expect(resolved, equals(NleOutputColorMode.rec709Sdr));
    });
  });
}
