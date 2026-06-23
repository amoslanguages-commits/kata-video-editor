import 'dart:convert';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path/path.dart' as p;

class WaveformService {
  Future<String?> generateWaveform({
    required String sourcePath,
    required String outputDirectory,
    required String assetId,
    int samples = 160,
  }) async {
    final controller = PlayerController();

    try {
      final values = await controller.extractWaveformData(
        path: sourcePath,
        noOfSamples: samples,
      );

      final outputPath = p.join(outputDirectory, '$assetId.waveform.json');

      final normalized = values.map((v) {
        final value = v.abs();
        if (value.isNaN || value.isInfinite) return 0.0;
        return value.clamp(0.0, 1.0);
      }).toList();

      await File(outputPath).writeAsString(jsonEncode(normalized));
      return outputPath;
    } catch (_) {
      return null;
    } finally {
      controller.dispose();
    }
  }

  Future<List<double>> readWaveform(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return [];

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return [];
    }
  }
}
