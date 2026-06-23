import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_event.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class NativeProxyEventController {
  final NativeBridgeContract nativeBridge;
  final Ref ref;

  StreamSubscription<NativeEvent>? _subscription;

  NativeProxyEventController({
    required this.nativeBridge,
    required this.ref,
  });

  void start() {
    _subscription ??= nativeBridge.events.listen(_handleEvent);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _handleEvent(NativeEvent event) async {
    switch (event.type) {
      case NativeEventTypes.proxyStarted:
        await _handleStarted(event);
        break;

      case NativeEventTypes.proxyProgress:
        await _handleProgress(event);
        break;

      case NativeEventTypes.proxyCompleted:
        await _handleCompleted(event);
        break;

      case NativeEventTypes.proxyFailed:
        await _handleFailed(event);
        break;

      case NativeEventTypes.proxyCancelled:
        await _handleCancelled(event);
        break;
    }
  }

  Future<void> _handleStarted(NativeEvent event) async {
    final assetId = event.payload['assetId']?.toString();
    if (assetId == null) return;

    await ref.read(assetRepositoryProvider).updateAssetFields(
          assetId,
          const AssetsCompanion(
            proxyStatus: Value('processing'),
            errorMessage: Value(null),
          ),
        );
  }

  Future<void> _handleProgress(NativeEvent event) async {
    final assetId = event.payload['assetId']?.toString();
    if (assetId == null) return;

    await ref.read(assetRepositoryProvider).updateAssetFields(
          assetId,
          const AssetsCompanion(
            proxyStatus: Value('processing'),
          ),
        );
  }

  Future<void> _handleCompleted(NativeEvent event) async {
    final payload = event.payload;
    final assetId = payload['assetId']?.toString();
    if (assetId == null) return;

    final result = _asMap(payload['result']);
    final source = result.isEmpty ? payload : result;
    final outputPath = source['outputPath']?.toString() ?? source['proxyPath']?.toString();
    final width = (source['width'] as num?)?.toInt() ?? (source['proxyWidth'] as num?)?.toInt();
    final height = (source['height'] as num?)?.toInt() ?? (source['proxyHeight'] as num?)?.toInt();
    final codec = source['codec']?.toString() ?? source['proxyCodec']?.toString();
    final fileSize = (source['fileSize'] as num?)?.toInt();

    await ref.read(assetRepositoryProvider).updateAssetFields(
          assetId,
          AssetsCompanion(
            proxyStatus: const Value('ready'),
            proxyPath: Value(outputPath),
            proxyWidth: Value(width),
            proxyHeight: Value(height),
            proxyCodec: Value(codec),
            proxyFileSize: Value(fileSize),
            errorMessage: const Value(null),
          ),
        );
  }

  Future<void> _handleFailed(NativeEvent event) async {
    final assetId = event.payload['assetId']?.toString();
    if (assetId == null) return;

    final error = event.payload['errorMessage']?.toString() ?? 'Proxy generation failed';

    await ref.read(assetRepositoryProvider).updateAssetFields(
          assetId,
          AssetsCompanion(
            proxyStatus: const Value('failed'),
            errorMessage: Value(error),
          ),
        );
  }

  Future<void> _handleCancelled(NativeEvent event) async {
    final assetId = event.payload['assetId']?.toString();
    if (assetId == null) return;

    await ref.read(assetRepositoryProvider).updateAssetFields(
          assetId,
          const AssetsCompanion(
            proxyStatus: Value('cancelled'),
            errorMessage: Value('Cancelled by user'),
          ),
        );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }
}
