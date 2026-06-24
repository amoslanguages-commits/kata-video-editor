// lib/data/repositories/hdr_output_repository.dart
//
// 30J-PRO: Persistence layer for NleHdrOutputSettings.
//
// Reads/writes the hdrOutputSettingsJson column on the Projects table.

import 'dart:convert';
import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/color_output/hdr_output_models.dart';

class HdrOutputRepository {
  final db.AppDatabase database;

  const HdrOutputRepository({required this.database});

  Future<NleHdrOutputSettings> getSettings(String projectId) async {
    try {
      final project = await database.getProjectById(projectId);
      final jsonString = project.hdrOutputSettingsJson;
      if (jsonString == null || jsonString.trim().isEmpty) {
        return NleHdrOutputSettings.defaultSettings();
      }
      return NleHdrOutputSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(jsonString) as Map),
      );
    } catch (_) {
      return NleHdrOutputSettings.defaultSettings();
    }
  }

  Future<void> saveSettings(String projectId, NleHdrOutputSettings settings) async {
    final jsonStr = jsonEncode(settings.toJson());
    await database.updateProjectHdrOutputSettingsJson(
      projectId: projectId,
      hdrOutputSettingsJson: jsonStr,
    );
  }

  Future<NleHdrOutputSettings> setOutputMode(String projectId, NleOutputColorMode mode) async {
    final current = await getSettings(projectId);

    // Automatically match transfer function and bit depth based on output mode.
    NleHdrTransferFunction tf;
    NleOutputBitDepth bitDepth;

    switch (mode) {
      case NleOutputColorMode.rec2020HlgHdr:
        tf = NleHdrTransferFunction.hlg;
        bitDepth = NleOutputBitDepth.tenBit;
        break;
      case NleOutputColorMode.rec2020PqHdr:
        tf = NleHdrTransferFunction.pq;
        bitDepth = NleOutputBitDepth.tenBit;
        break;
      case NleOutputColorMode.rec709Sdr:
      case NleOutputColorMode.srgbSdr:
      case NleOutputColorMode.displayP3Sdr:
      case NleOutputColorMode.rec2020Sdr:
        tf = NleHdrTransferFunction.sdr;
        bitDepth = NleOutputBitDepth.eightBit;
        break;
    }

    final updated = current.copyWith(
      colorMode: mode,
      transferFunction: tf,
      bitDepth: bitDepth,
    );

    await saveSettings(projectId, updated);
    return updated;
  }
}
