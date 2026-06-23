import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:nle_editor/domain/device/device_capability_profile.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_event.dart';

class DeviceCapabilityProfilerService {
  Future<DeviceCapabilityProfile> detectProfile({
    NativeBridgeContract? nativeBridge,
  }) async {
    if (nativeBridge != null) {
      final nativeProfile = await _tryDetectNativeProfile(nativeBridge);
      if (nativeProfile != null) {
        return nativeProfile;
      }
    }

    return _detectFallbackProfile();
  }

  Future<DeviceCapabilityProfile> _detectFallbackProfile() async {
    final cpuCores = Platform.numberOfProcessors;
    final platform = _platformName();
    final osVersion = Platform.operatingSystemVersion;

    final tier = _estimateTier(
      cpuCores: cpuCores,
      ramMb: null,
      platform: platform,
    );

    final codecSupport = _safeCodecSupportForPlaceholder(
      platform: platform,
      tier: tier,
    );

    final limits = _limitsForTier(tier);
    final runtime = await detectRuntimeState();

    return DeviceCapabilityProfile(
      profileVersion: '1.0.0',
      source: 'flutter_placeholder',
      platform: platform,
      deviceModel: kIsWeb ? 'web' : 'unknown_device',
      osVersion: osVersion,
      cpuCores: cpuCores,
      ramMb: null,
      gpuName: 'unknown_gpu',
      tier: tier,
      recommendedPreviewQuality: _recommendedPreviewQuality(tier),
      recommendedProxyMode: ProxyMode.auto,
      recommendedExportPreference: ExportPreference.compatibility,
      codecSupport: codecSupport,
      limits: limits,
      runtime: runtime,
      detectedAt: DateTime.now(),
    );
  }

  Future<DeviceCapabilityProfile?> _tryDetectNativeProfile(
    NativeBridgeContract nativeBridge,
  ) async {
    try {
      final eventFuture = nativeBridge.events.firstWhere(
        (event) => event.type == NativeEventTypes.deviceCapabilities,
      );

      final result = await nativeBridge.probeDeviceCapabilities();
      if (!result.accepted) return null;

      final event = await eventFuture.timeout(const Duration(seconds: 2));
      return _profileFromNativePayload(event.payload);
    } catch (_) {
      return null;
    }
  }

  DeviceCapabilityProfile _profileFromNativePayload(
    Map<String, dynamic> payload,
  ) {
    final platform = (payload['platform'] as String?) ?? _platformName();
    final tier = (payload['tier'] as String?) ??
        _estimateTier(
          cpuCores: _intValue(payload['cpuCores']) ?? Platform.numberOfProcessors,
          ramMb: _intValue(payload['largeMemoryClassMb']) ??
              _intValue(payload['memoryClassMb']),
          platform: platform,
        );
    final codecPayload = _mapValue(payload['codecSupport']) ??
        _mapValue(payload['codec']) ??
        const <String, dynamic>{};
    final limitsPayload = _mapValue(payload['limits']) ?? const <String, dynamic>{};
    final fallbackLimits = _limitsForTier(tier);
    final cpuCores = _intValue(payload['cpuCores']) ?? Platform.numberOfProcessors;

    return DeviceCapabilityProfile(
      profileVersion: '1.0.0',
      source: (payload['source'] as String?) ?? '${platform}_native_bridge',
      platform: platform,
      deviceModel: _deviceModelFromNativePayload(payload),
      osVersion: _osVersionFromNativePayload(payload),
      cpuCores: cpuCores,
      ramMb: _intValue(payload['largeMemoryClassMb']) ??
          _intValue(payload['memoryClassMb']),
      gpuName: (payload['gpuName'] as String?) ?? 'unknown_gpu',
      tier: tier,
      recommendedPreviewQuality: _recommendedPreviewQuality(tier),
      recommendedProxyMode: ProxyMode.auto,
      recommendedExportPreference: ExportPreference.compatibility,
      codecSupport: _codecSupportFromNativePayload(codecPayload, payload),
      limits: _limitsFromNativePayload(limitsPayload, fallbackLimits),
      runtime: DeviceRuntimeState.safeDefault(),
      detectedAt: DateTime.now(),
    );
  }

  CodecSupport _codecSupportFromNativePayload(
    Map<String, dynamic> codecPayload,
    Map<String, dynamic> fullPayload,
  ) {
    final supportedCodecs = (fullPayload['supportedCodecs'] as List?)
            ?.map((value) => value.toString().toLowerCase())
            .toSet() ??
        const <String>{};

    return CodecSupport(
      h264Decode: _boolValue(codecPayload['h264Decode']) ??
          supportedCodecs.contains('h264') ||
          supportedCodecs.isEmpty,
      h264Encode: _boolValue(codecPayload['h264Encode']) ??
          supportedCodecs.contains('h264') ||
          supportedCodecs.isEmpty,
      hevcDecode: _boolValue(codecPayload['hevcDecode']) ??
          supportedCodecs.contains('hevc'),
      hevcEncode: _boolValue(codecPayload['hevcEncode']) ??
          supportedCodecs.contains('hevc'),
      tenBitDecode: _boolValue(codecPayload['tenBitDecode']) ?? false,
      tenBitEncode: _boolValue(codecPayload['tenBitEncode']) ?? false,
      hdrPreview: _boolValue(codecPayload['hdrPreview']) ?? false,
      hdrExport: _boolValue(codecPayload['hdrExport']) ?? false,
    );
  }

  DeviceLimits _limitsFromNativePayload(
    Map<String, dynamic> limitsPayload,
    DeviceLimits fallback,
  ) {
    final allow4kExport =
        _boolValue(limitsPayload['allow4kExport']) ?? fallback.allow4kExport;

    return DeviceLimits(
      safePreviewHeight:
          _intValue(limitsPayload['safePreviewHeight']) ?? fallback.safePreviewHeight,
      recommendedProxyHeight: _intValue(limitsPayload['recommendedProxyHeight']) ??
          fallback.recommendedProxyHeight,
      maxExportHeight: _intValue(limitsPayload['maxExportHeight']) ??
          (allow4kExport ? 2160 : fallback.maxExportHeight),
      maxExportFrameRate:
          _intValue(limitsPayload['maxExportFrameRate']) ?? fallback.maxExportFrameRate,
      maxRealtimeVideoTracks: _intValue(limitsPayload['maxRealtimeVideoTracks']) ??
          fallback.maxRealtimeVideoTracks,
      maxRealtimeAudioTracks: _intValue(limitsPayload['maxRealtimeAudioTracks']) ??
          fallback.maxRealtimeAudioTracks,
      proxyRequiredFor4k:
          _boolValue(limitsPayload['proxyRequiredFor4k']) ?? !allow4kExport,
      advancedEffectsEnabled:
          _boolValue(limitsPayload['advancedEffectsEnabled']) ??
              fallback.advancedEffectsEnabled,
      backgroundProxyEnabled:
          _boolValue(limitsPayload['backgroundProxyEnabled']) ??
              fallback.backgroundProxyEnabled,
      allow4kExport: allow4kExport,
    );
  }

  String _deviceModelFromNativePayload(Map<String, dynamic> payload) {
    final manufacturer = payload['manufacturer']?.toString();
    final model = payload['model']?.toString() ?? payload['deviceModel']?.toString();

    if (manufacturer != null && model != null) {
      return '$manufacturer $model';
    }

    return model ?? (kIsWeb ? 'web' : 'unknown_device');
  }

  String _osVersionFromNativePayload(Map<String, dynamic> payload) {
    final release = payload['release']?.toString();
    final sdkInt = payload['sdkInt']?.toString();

    if (release != null && sdkInt != null) {
      return 'Android $release (SDK $sdkInt)';
    }

    return payload['osVersion']?.toString() ?? Platform.operatingSystemVersion;
  }

  Future<DeviceRuntimeState> detectRuntimeState() async {
    return DeviceRuntimeState.safeDefault();
  }

  String _platformName() {
    if (kIsWeb) return 'web';

    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';

    return Platform.operatingSystem;
  }

  String _estimateTier({
    required int cpuCores,
    required int? ramMb,
    required String platform,
  }) {
    if (cpuCores <= 4) {
      return DeviceTier.lowEnd;
    }

    if (cpuCores <= 6) {
      return DeviceTier.midRange;
    }

    if (cpuCores <= 8) {
      return DeviceTier.highEnd;
    }

    return DeviceTier.flagship;
  }

  CodecSupport _safeCodecSupportForPlaceholder({
    required String platform,
    required String tier,
  }) {
    if (platform == 'ios') {
      return CodecSupport(
        h264Decode: true,
        h264Encode: true,
        hevcDecode: tier == DeviceTier.highEnd || tier == DeviceTier.flagship,
        hevcEncode: tier == DeviceTier.flagship,
        tenBitDecode: false,
        tenBitEncode: false,
        hdrPreview: false,
        hdrExport: false,
      );
    }

    if (platform == 'android') {
      return CodecSupport(
        h264Decode: true,
        h264Encode: true,
        hevcDecode: tier == DeviceTier.highEnd || tier == DeviceTier.flagship,
        hevcEncode: false,
        tenBitDecode: false,
        tenBitEncode: false,
        hdrPreview: false,
        hdrExport: false,
      );
    }

    return CodecSupport.safeDefault();
  }

  DeviceLimits _limitsForTier(String tier) {
    switch (tier) {
      case DeviceTier.lowEnd:
        return const DeviceLimits(
          safePreviewHeight: 540,
          recommendedProxyHeight: 540,
          maxExportHeight: 1080,
          maxExportFrameRate: 30,
          maxRealtimeVideoTracks: 1,
          maxRealtimeAudioTracks: 2,
          proxyRequiredFor4k: true,
          advancedEffectsEnabled: false,
          backgroundProxyEnabled: false,
          allow4kExport: false,
        );

      case DeviceTier.midRange:
        return const DeviceLimits(
          safePreviewHeight: 720,
          recommendedProxyHeight: 720,
          maxExportHeight: 1080,
          maxExportFrameRate: 60,
          maxRealtimeVideoTracks: 2,
          maxRealtimeAudioTracks: 4,
          proxyRequiredFor4k: true,
          advancedEffectsEnabled: true,
          backgroundProxyEnabled: true,
          allow4kExport: false,
        );

      case DeviceTier.highEnd:
        return const DeviceLimits(
          safePreviewHeight: 1080,
          recommendedProxyHeight: 960,
          maxExportHeight: 2160,
          maxExportFrameRate: 60,
          maxRealtimeVideoTracks: 3,
          maxRealtimeAudioTracks: 6,
          proxyRequiredFor4k: true,
          advancedEffectsEnabled: true,
          backgroundProxyEnabled: true,
          allow4kExport: true,
        );

      case DeviceTier.flagship:
      default:
        return const DeviceLimits(
          safePreviewHeight: 1080,
          recommendedProxyHeight: 1080,
          maxExportHeight: 2160,
          maxExportFrameRate: 60,
          maxRealtimeVideoTracks: 4,
          maxRealtimeAudioTracks: 8,
          proxyRequiredFor4k: false,
          advancedEffectsEnabled: true,
          backgroundProxyEnabled: true,
          allow4kExport: true,
        );
    }
  }

  String _recommendedPreviewQuality(String tier) {
    switch (tier) {
      case DeviceTier.lowEnd:
        return PreviewQualityMode.draft;

      case DeviceTier.midRange:
        return PreviewQualityMode.balanced;

      case DeviceTier.highEnd:
        return PreviewQualityMode.balanced;

      case DeviceTier.flagship:
      default:
        return PreviewQualityMode.adaptive;
    }
  }

  Map<String, dynamic>? _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  bool? _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is String) return bool.tryParse(value);
    return null;
  }
}
