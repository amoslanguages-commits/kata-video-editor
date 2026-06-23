// lib/presentation/providers/hdr_output_providers.dart
//
// 30J-PRO: Providers for HDR & Wide Color Gamut Output services.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/data/repositories/hdr_output_repository.dart';
import 'package:nle_editor/domain/native/native_hdr_output_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final hdrOutputRepositoryProvider = Provider<HdrOutputRepository>((ref) {
  return HdrOutputRepository(database: ref.watch(databaseProvider));
});

final nativeHdrOutputServiceProvider = Provider<NativeHdrOutputService>((ref) {
  return NativeHdrOutputService(bridge: ref.watch(nativeBridgeProvider));
});
