import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Lut3D {
  final String title;
  final int size;
  final List<double> domainMin;
  final List<double> domainMax;
  final List<List<double>> table; // List of [R, G, B] values

  Lut3D({
    required this.title,
    required this.size,
    required this.domainMin,
    required this.domainMax,
    required this.table,
  });
}

class LutFilterService {
  const LutFilterService();

  Future<Lut3D> parseCubeFile(File file) async {
    final contents = await file.readAsString();
    return parseCubeString(contents);
  }

  Lut3D parseCubeString(String contents) {
    final lines = LineSplitter.split(contents);
    String title = 'Untitled';
    int size = 0;
    List<double> domainMin = [0.0, 0.0, 0.0];
    List<double> domainMax = [1.0, 1.0, 1.0];
    final table = <List<double>>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      if (line.startsWith('TITLE')) {
        title = line.substring(5).replaceAll('"', '').trim();
      } else if (line.startsWith('LUT_3D_SIZE')) {
        size = int.tryParse(line.substring(11).trim()) ?? 0;
      } else if (line.startsWith('DOMAIN_MIN')) {
        domainMin = line
            .substring(10)
            .trim()
            .split(RegExp(r'\s+'))
            .map((s) => double.tryParse(s) ?? 0.0)
            .toList();
      } else if (line.startsWith('DOMAIN_MAX')) {
        domainMax = line
            .substring(10)
            .trim()
            .split(RegExp(r'\s+'))
            .map((s) => double.tryParse(s) ?? 1.0)
            .toList();
      } else {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final r = double.tryParse(parts[0]);
          final g = double.tryParse(parts[1]);
          final b = double.tryParse(parts[2]);
          if (r != null && g != null && b != null) {
            table.add([r, g, b]);
          }
        }
      }
    }

    if (size == 0) {
      throw const FormatException('Invalid or missing LUT_3D_SIZE in CUBE file');
    }

    return Lut3D(
      title: title,
      size: size,
      domainMin: domainMin,
      domainMax: domainMax,
      table: table,
    );
  }

  /// Evaluates an input [r, g, b] (each 0.0 to 1.0) using 3D LUT mapping.
  List<double> evaluate(Lut3D lut, double r, double g, double b) {
    if (lut.table.isEmpty) return [r, g, b];

    final size = lut.size;
    final rScaled = (r.clamp(0.0, 1.0) * (size - 1));
    final gScaled = (g.clamp(0.0, 1.0) * (size - 1));
    final bScaled = (b.clamp(0.0, 1.0) * (size - 1));

    // Nearest neighbor lookup
    final rIdx = rScaled.round();
    final gIdx = gScaled.round();
    final bIdx = bScaled.round();

    final index = rIdx + gIdx * size + bIdx * size * size;
    if (index >= 0 && index < lut.table.length) {
      return lut.table[index];
    }

    return [r, g, b];
  }
}

final lutFilterServiceProvider = Provider<LutFilterService>((ref) {
  return const LutFilterService();
});
