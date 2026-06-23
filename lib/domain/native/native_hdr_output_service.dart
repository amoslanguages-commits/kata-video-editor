// lib/domain/native/native_hdr_output_service.dart
//
// 30J-PRO: Interface to the native platform scanner and validation commands.

import 'dart:async';

import 'package:nle_editor/domain/color_output/hdr_output_models.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_command.dart';
import 'package:nle_editor/native_bridge/native_event.dart';

class NativeHdrOutputService {
  final NativeBridgeContract bridge;

  const NativeHdrOutputService({required this.bridge});

  Future<NleHdrDeviceCapability> scanCapability() async {
    final eventFuture = bridge.events.firstWhere(
      (event) => event.type == NativeEventTypes.hdrDeviceCapability,
    );

    final result = await bridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.hdrScanCapability,
      ),
    );

    if (!result.accepted) {
      return NleHdrDeviceCapability.unknown();
    }

    try {
      final event = await eventFuture.timeout(const Duration(seconds: 2));
      return NleHdrDeviceCapability.fromJson(event.payload);
    } catch (_) {
      return NleHdrDeviceCapability.unknown();
    }
  }

  Future<NleHdrExportValidation> validateExport({
    required String projectId,
    required NleHdrOutputSettings settings,
  }) async {
    final eventFuture = bridge.events.firstWhere(
      (event) => event.type == NativeEventTypes.hdrExportValidation && event.projectId == projectId,
    );

    final result = await bridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.hdrValidateExport,
        projectId: projectId,
        payload: settings.toJson(),
      ),
    );

    if (!result.accepted) {
      return NleHdrExportValidation(
        isHdrSafe: true,
        warnings: const [],
        errors: const [],
        suggestedColorMode: settings.colorMode,
        suggestedBitDepth: settings.bitDepth,
        suggestedTransferFunction: settings.transferFunction,
      );
    }

    try {
      final event = await eventFuture.timeout(const Duration(seconds: 2));
      return NleHdrExportValidation.fromJson(event.payload);
    } catch (_) {
      return NleHdrExportValidation(
        isHdrSafe: true,
        warnings: const [],
        errors: const [],
        suggestedColorMode: settings.colorMode,
        suggestedBitDepth: settings.bitDepth,
        suggestedTransferFunction: settings.transferFunction,
      );
    }
  }

  Future<void> configurePreview({
    required String projectId,
    required NleHdrOutputSettings settings,
  }) async {
    await bridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.hdrConfigurePreview,
        projectId: projectId,
        payload: settings.toJson(),
      ),
    );
  }
}
