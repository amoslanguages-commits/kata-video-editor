// lib/domain/color/asset_color_metadata.dart
//
// 30A-PRO: Per-asset detected color metadata.
//
// Populated from the asset's codec/container metadata after import.
// Used by the RenderGraph to apply per-clip Input Color Transforms.

import 'package:nle_editor/domain/color/color_management_models.dart';

T _enumByName<T extends Enum>(
  List<T> values,
  Object? name,
  T fallback,
) {
  final string = name?.toString();
  if (string == null) return fallback;
  for (final value in values) {
    if (value.name == string) return value;
  }
  return fallback;
}

class AssetColorMetadata {
  final String assetId;
  final NleColorSpace inputColorSpace;
  final NleTransferCurve inputTransferCurve;
  final bool fullRange;
  final bool hdr;
  final bool wideGamut;
  final String? cameraLogProfile;
  final String? detectedCodec;
  final int? bitDepth;

  const AssetColorMetadata({
    required this.assetId,
    required this.inputColorSpace,
    required this.inputTransferCurve,
    required this.fullRange,
    required this.hdr,
    required this.wideGamut,
    this.cameraLogProfile,
    this.detectedCodec,
    this.bitDepth,
  });

  const AssetColorMetadata.unknown({required String assetId})
      : assetId = assetId,
        inputColorSpace = NleColorSpace.auto,
        inputTransferCurve = NleTransferCurve.auto,
        fullRange = true,
        hdr = false,
        wideGamut = false,
        cameraLogProfile = null,
        detectedCodec = null,
        bitDepth = null;

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'inputColorSpace': inputColorSpace.name,
      'inputTransferCurve': inputTransferCurve.name,
      'fullRange': fullRange,
      'hdr': hdr,
      'wideGamut': wideGamut,
      'cameraLogProfile': cameraLogProfile,
      'detectedCodec': detectedCodec,
      'bitDepth': bitDepth,
    };
  }

  factory AssetColorMetadata.fromJson(Map<String, dynamic> json) {
    return AssetColorMetadata(
      assetId: json['assetId']?.toString() ?? '',
      inputColorSpace: _enumByName(
        NleColorSpace.values,
        json['inputColorSpace'],
        NleColorSpace.auto,
      ),
      inputTransferCurve: _enumByName(
        NleTransferCurve.values,
        json['inputTransferCurve'],
        NleTransferCurve.auto,
      ),
      fullRange: json['fullRange'] != false,
      hdr: json['hdr'] == true,
      wideGamut: json['wideGamut'] == true,
      cameraLogProfile: json['cameraLogProfile']?.toString(),
      detectedCodec: json['detectedCodec']?.toString(),
      bitDepth: (json['bitDepth'] as num?)?.toInt(),
    );
  }
}
