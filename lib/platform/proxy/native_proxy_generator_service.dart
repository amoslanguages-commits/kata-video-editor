import 'package:flutter/services.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

class NleNativeProxyResult {
  final String proxyPath;
  final int width;
  final int height;
  final double fps;
  final int bitrate;
  final int fileSizeBytes;
  final int durationMicros;
  final String codec;

  const NleNativeProxyResult({
    required this.proxyPath,
    required this.width,
    required this.height,
    required this.fps,
    required this.bitrate,
    required this.fileSizeBytes,
    required this.durationMicros,
    required this.codec,
  });

  NleProxyMetadata toMetadata() {
    return NleProxyMetadata(
      proxyPath: proxyPath,
      width: width,
      height: height,
      fps: fps,
      bitrate: bitrate,
      fileSizeBytes: fileSizeBytes,
      durationMicros: durationMicros,
      codec: codec,
      createdAt: DateTime.now(),
    );
  }
}

class NativeProxyGeneratorService {
  static const MethodChannel _channel = MethodChannel('nle/proxy_generator');

  const NativeProxyGeneratorService();

  Future<NleNativeProxyResult> generate({
    required String jobId,
    required String sourcePath,
    required String outputPath,
    required NleProxyVideoSpec spec,
  }) async {
    final result = await _channel.invokeMethod('proxy_generate', {
      'jobId': jobId,
      'sourcePath': sourcePath,
      'outputPath': outputPath,
      'maxWidth': spec.maxWidth,
      'maxHeight': spec.maxHeight,
      'bitrate': spec.bitrate,
      'fpsLimit': spec.fpsLimit,
      'codec': spec.codec == NleProxyCodec.hevc ? 'video/hevc' : 'video/avc',
      'container': spec.container.name,
    });

    if (result == null) {
      throw PlatformException(code: 'ERROR', message: 'Failed to generate proxy, result was null');
    }

    final map = Map<String, dynamic>.from(result as Map);

    return NleNativeProxyResult(
      proxyPath: map['proxyPath']?.toString() ?? outputPath,
      width: (map['width'] as num?)?.toInt() ?? spec.maxWidth,
      height: (map['height'] as num?)?.toInt() ?? spec.maxHeight,
      fps: (map['fps'] as num?)?.toDouble() ?? spec.fpsLimit,
      bitrate: (map['bitrate'] as num?)?.toInt() ?? spec.bitrate,
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      durationMicros: (map['durationMicros'] as num?)?.toInt() ?? 0,
      codec: map['codec']?.toString() ?? spec.codec.name,
    );
  }

  Future<void> cancel(String jobId) async {
    await _channel.invokeMethod('proxy_cancel', {
      'jobId': jobId,
    });
  }
}
