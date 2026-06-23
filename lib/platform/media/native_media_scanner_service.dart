import 'package:flutter/services.dart';

import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';

class NativeMediaScannerService {
  static const MethodChannel _channel = MethodChannel('nle/media_scanner');

  const NativeMediaScannerService();

  Future<NleNativeMediaScanResult> scan(String path) async {
    try {
      final result = await _channel.invokeMethod<Map>(
        'media_scan',
        {
          'path': path,
        },
      );

      if (result == null) {
        return NleNativeMediaScanResult.empty(path);
      }

      return NleNativeMediaScanResult.fromJson(
        Map<String, dynamic>.from(result),
      );
    } catch (e) {
      return NleNativeMediaScanResult.empty(path);
    }
  }

  Future<String?> generateThumbnail({
    required String path,
    required String outputPath,
    required int width,
    required int height,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'media_generate_thumbnail',
        {
          'path': path,
          'outputPath': outputPath,
          'width': width,
          'height': height,
        },
      );

      if (result == null || result.isEmpty) return null;
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<bool> fileExists(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'media_file_exists',
        {
          'path': path,
        },
      );

      return result == true;
    } catch (e) {
      return false;
    }
  }
}

class NleNativeMediaScanResult {
  final String path;
  final NleMediaAssetType type;
  final int durationMicros;
  final int width;
  final int height;
  final double fps;
  final int sampleRate;
  final int channelCount;
  final int bitrate;
  final String videoCodec;
  final String audioCodec;
  final String colorSpace;
  final bool hasHdr;

  const NleNativeMediaScanResult({
    required this.path,
    required this.type,
    required this.durationMicros,
    required this.width,
    required this.height,
    required this.fps,
    required this.sampleRate,
    required this.channelCount,
    required this.bitrate,
    required this.videoCodec,
    required this.audioCodec,
    required this.colorSpace,
    required this.hasHdr,
  });

  const NleNativeMediaScanResult.empty(String path)
      : path = path,
        type = NleMediaAssetType.unknown,
        durationMicros = 0,
        width = 0,
        height = 0,
        fps = 0.0,
        sampleRate = 0,
        channelCount = 0,
        bitrate = 0,
        videoCodec = '',
        audioCodec = '',
        colorSpace = '',
        hasHdr = false;

  factory NleNativeMediaScanResult.fromJson(Map<String, dynamic> json) {
    return NleNativeMediaScanResult(
      path: json['path']?.toString() ?? '',
      type: _enumByName(
        NleMediaAssetType.values,
        json['type'],
        NleMediaAssetType.unknown,
      ),
      durationMicros: (json['durationMicros'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      fps: (json['fps'] as num?)?.toDouble() ?? 0.0,
      sampleRate: (json['sampleRate'] as num?)?.toInt() ?? 0,
      channelCount: (json['channelCount'] as num?)?.toInt() ?? 0,
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
      videoCodec: json['videoCodec']?.toString() ?? '',
      audioCodec: json['audioCodec']?.toString() ?? '',
      colorSpace: json['colorSpace']?.toString() ?? '',
      hasHdr: json['hasHdr'] == true,
    );
  }
}

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
