class DeviceCapabilityProfile {
  final bool available;
  final String profileSchema;
  final int profileVersion;
  final int generatedAtMs;
  final Map<String, Object?> deviceCapability;
  final Map<String, Object?> colorCapability;
  final AdaptiveExportProfile adaptiveExportProfile;

  const DeviceCapabilityProfile({
    required this.available,
    required this.profileSchema,
    required this.profileVersion,
    required this.generatedAtMs,
    required this.deviceCapability,
    required this.colorCapability,
    required this.adaptiveExportProfile,
  });

  factory DeviceCapabilityProfile.fromNativePayload(Map<String, Object?> json) {
    return DeviceCapabilityProfile(
      available: _bool(json['available']),
      profileSchema: json['profileSchema']?.toString() ?? 'nle.device_capability_profile',
      profileVersion: _int(json['profileVersion'], fallback: 1),
      generatedAtMs: _int(json['generatedAtMs']),
      deviceCapability: _map(json['deviceCapability']),
      colorCapability: _map(json['colorCapability']),
      adaptiveExportProfile: AdaptiveExportProfile.fromJson(_map(json['adaptiveExportProfile'])),
    );
  }

  Map<String, Object?> toJson() => {
        'available': available,
        'profileSchema': profileSchema,
        'profileVersion': profileVersion,
        'generatedAtMs': generatedAtMs,
        'deviceCapability': deviceCapability,
        'colorCapability': colorCapability,
        'adaptiveExportProfile': adaptiveExportProfile.toJson(),
      };
}

class AdaptiveExportProfile {
  final int maxResolution;
  final int maxFrameRate;
  final int maxVideoBitrate;
  final int audioBitrate;
  final bool preferProxyPreview;
  final String proxyPolicy;
  final bool requireProxyFor4k;
  final bool allow4kExport;
  final bool exportBlocked;
  final List<String> blockReason;
  final String previewQuality;
  final double preferredPreviewScale;
  final String colorPipelineQuality;
  final bool supportsHdrExport;
  final bool supportsWideColorPreview;
  final List<String> notes;

  const AdaptiveExportProfile({
    required this.maxResolution,
    required this.maxFrameRate,
    required this.maxVideoBitrate,
    required this.audioBitrate,
    required this.preferProxyPreview,
    required this.proxyPolicy,
    required this.requireProxyFor4k,
    required this.allow4kExport,
    required this.exportBlocked,
    required this.blockReason,
    required this.previewQuality,
    required this.preferredPreviewScale,
    required this.colorPipelineQuality,
    required this.supportsHdrExport,
    required this.supportsWideColorPreview,
    required this.notes,
  });

  factory AdaptiveExportProfile.fromJson(Map<String, Object?> json) {
    return AdaptiveExportProfile(
      maxResolution: _int(json['maxResolution']),
      maxFrameRate: _int(json['maxFrameRate'], fallback: 30),
      maxVideoBitrate: _int(json['maxVideoBitrate']),
      audioBitrate: _int(json['audioBitrate'], fallback: 192000),
      preferProxyPreview: _bool(json['preferProxyPreview']),
      proxyPolicy: json['proxyPolicy']?.toString() ?? 'optional',
      requireProxyFor4k: _bool(json['requireProxyFor4k']),
      allow4kExport: _bool(json['allow4kExport']),
      exportBlocked: _bool(json['exportBlocked']),
      blockReason: _stringList(json['blockReason']),
      previewQuality: json['previewQuality']?.toString() ?? 'balanced',
      preferredPreviewScale: _double(json['preferredPreviewScale'], fallback: 0.75),
      colorPipelineQuality: json['colorPipelineQuality']?.toString() ?? 'compatibility_8bit',
      supportsHdrExport: _bool(json['supportsHdrExport']),
      supportsWideColorPreview: _bool(json['supportsWideColorPreview']),
      notes: _stringList(json['notes']),
    );
  }

  Map<String, Object?> toJson() => {
        'maxResolution': maxResolution,
        'maxFrameRate': maxFrameRate,
        'maxVideoBitrate': maxVideoBitrate,
        'audioBitrate': audioBitrate,
        'preferProxyPreview': preferProxyPreview,
        'proxyPolicy': proxyPolicy,
        'requireProxyFor4k': requireProxyFor4k,
        'allow4kExport': allow4kExport,
        'exportBlocked': exportBlocked,
        'blockReason': blockReason,
        'previewQuality': previewQuality,
        'preferredPreviewScale': preferredPreviewScale,
        'colorPipelineQuality': colorPipelineQuality,
        'supportsHdrExport': supportsHdrExport,
        'supportsWideColorPreview': supportsWideColorPreview,
        'notes': notes,
      };
}

class RequestedExportSettings {
  final int width;
  final int height;
  final int frameRate;
  final int videoBitrate;
  final int audioBitrate;
  final bool preferProxy;
  final bool hdrRequested;

  const RequestedExportSettings({
    required this.width,
    required this.height,
    required this.frameRate,
    required this.videoBitrate,
    this.audioBitrate = 192000,
    this.preferProxy = false,
    this.hdrRequested = false,
  });

  int get longEdge => width > height ? width : height;
  double get aspectRatio => height == 0 ? 1.0 : width / height;

  RequestedExportSettings copyWith({
    int? width,
    int? height,
    int? frameRate,
    int? videoBitrate,
    int? audioBitrate,
    bool? preferProxy,
    bool? hdrRequested,
  }) {
    return RequestedExportSettings(
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      preferProxy: preferProxy ?? this.preferProxy,
      hdrRequested: hdrRequested ?? this.hdrRequested,
    );
  }

  Map<String, Object?> toNativeProfile() => {
        'width': width,
        'height': height,
        'targetWidth': width,
        'targetHeight': height,
        'frameRate': frameRate,
        'videoBitrate': videoBitrate,
        'videoBitrateBps': videoBitrate,
        'audioBitrate': audioBitrate,
        'preferProxy': preferProxy,
        'hdrRequested': hdrRequested,
      };
}

class AdaptiveExportSettingsDecision {
  final RequestedExportSettings requested;
  final RequestedExportSettings resolved;
  final bool blocked;
  final List<String> reasons;
  final Map<String, Object?> profileSnapshot;

  const AdaptiveExportSettingsDecision({
    required this.requested,
    required this.resolved,
    required this.blocked,
    required this.reasons,
    required this.profileSnapshot,
  });

  Map<String, Object?> toNativeProfile() => {
        ...resolved.toNativeProfile(),
        'adaptiveExport': true,
        'adaptiveBlocked': blocked,
        'adaptiveReasons': reasons,
        'deviceProfile': profileSnapshot,
      };
}

class AdaptiveExportSettingsResolver {
  const AdaptiveExportSettingsResolver();

  AdaptiveExportSettingsDecision resolve({
    required RequestedExportSettings requested,
    required AdaptiveExportProfile profile,
  }) {
    final reasons = <String>[];
    if (profile.exportBlocked) {
      reasons.addAll(
        profile.blockReason.isEmpty ? ['export_blocked_by_device'] : profile.blockReason,
      );
    }

    final maxResolution = profile.maxResolution <= 0 ? requested.longEdge : profile.maxResolution;
    final requestedLongEdge = requested.longEdge;
    final scale = requestedLongEdge <= maxResolution
        ? 1.0
        : maxResolution / requestedLongEdge;
    final resolvedWidth = _even((requested.width * scale).round())
        .clamp(2, requested.width)
        .toInt();
    final resolvedHeight = _even((requested.height * scale).round())
        .clamp(2, requested.height)
        .toInt();

    if (scale < 1.0) {
      reasons.add('resolution_clamped_to_${maxResolution}p');
    }

    final maxFrameRate = profile.maxFrameRate <= 0 ? requested.frameRate : profile.maxFrameRate;
    final resolvedFrameRate = requested.frameRate.clamp(24, maxFrameRate).toInt();
    if (resolvedFrameRate != requested.frameRate) {
      reasons.add('frame_rate_clamped_to_$resolvedFrameRate');
    }

    final maxVideoBitrate = profile.maxVideoBitrate <= 0 ? requested.videoBitrate : profile.maxVideoBitrate;
    final resolvedVideoBitrate = requested.videoBitrate.clamp(1, maxVideoBitrate).toInt();
    if (resolvedVideoBitrate != requested.videoBitrate) {
      reasons.add('video_bitrate_clamped');
    }

    final maxAudioBitrate = profile.audioBitrate <= 0 ? requested.audioBitrate : profile.audioBitrate;
    final resolvedAudioBitrate = requested.audioBitrate.clamp(64000, maxAudioBitrate).toInt();
    if (resolvedAudioBitrate != requested.audioBitrate) {
      reasons.add('audio_bitrate_clamped');
    }

    final shouldPreferProxy = requested.preferProxy ||
        profile.proxyPolicy == 'required' ||
        (profile.proxyPolicy == 'required_for_4k' && requestedLongEdge >= 2160);
    if (shouldPreferProxy && !requested.preferProxy) {
      reasons.add('proxy_required_by_device_profile');
    }

    final hdrAllowed = requested.hdrRequested && profile.supportsHdrExport;
    if (requested.hdrRequested && !hdrAllowed) {
      reasons.add('hdr_export_disabled_by_device_profile');
    }

    return AdaptiveExportSettingsDecision(
      requested: requested,
      resolved: requested.copyWith(
        width: resolvedWidth,
        height: resolvedHeight,
        frameRate: resolvedFrameRate,
        videoBitrate: resolvedVideoBitrate,
        audioBitrate: resolvedAudioBitrate,
        preferProxy: shouldPreferProxy,
        hdrRequested: hdrAllowed,
      ),
      blocked: profile.exportBlocked,
      reasons: reasons,
      profileSnapshot: profile.toJson(),
    );
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
  return const <String, Object?>{};
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(Object? value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

List<String> _stringList(Object? value) {
  if (value is Iterable) return value.map((item) => item.toString()).toList(growable: false);
  return const <String>[];
}

int _even(int value) => value.isEven ? value : value - 1;
