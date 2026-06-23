// lib/domain/color/device_color_capability.dart
//
// 30A-PRO: Dart-side representation of the device's GPU color capabilities.
//
// Populated by the native Android/iOS scanner and delivered via the native
// device-QA channel.  Used to resolve the final pipeline quality tier.

class DeviceColorCapability {
  final bool supportsGles3;
  final bool supportsHalfFloatRenderTarget;
  final bool supportsFloatRenderTarget;
  final bool supportsWideColorPreview;
  final bool supportsHdrPreview;
  final bool supportsHdrExport;
  final int maxTextureSize;
  final String renderer;
  final String vendor;
  final String recommendedQuality;

  const DeviceColorCapability({
    required this.supportsGles3,
    required this.supportsHalfFloatRenderTarget,
    required this.supportsFloatRenderTarget,
    required this.supportsWideColorPreview,
    required this.supportsHdrPreview,
    required this.supportsHdrExport,
    required this.maxTextureSize,
    required this.renderer,
    required this.vendor,
    required this.recommendedQuality,
  });

  /// Fallback capability for devices that have not yet been scanned.
  factory DeviceColorCapability.unknown() {
    return const DeviceColorCapability(
      supportsGles3: false,
      supportsHalfFloatRenderTarget: false,
      supportsFloatRenderTarget: false,
      supportsWideColorPreview: false,
      supportsHdrPreview: false,
      supportsHdrExport: false,
      maxTextureSize: 4096,
      renderer: 'unknown',
      vendor: 'unknown',
      recommendedQuality: 'compatibility8bit',
    );
  }

  factory DeviceColorCapability.fromJson(Map<String, dynamic> json) {
    return DeviceColorCapability(
      supportsGles3: json['supportsGles3'] == true,
      supportsHalfFloatRenderTarget:
          json['supportsHalfFloatRenderTarget'] == true,
      supportsFloatRenderTarget: json['supportsFloatRenderTarget'] == true,
      supportsWideColorPreview: json['supportsWideColorPreview'] == true,
      supportsHdrPreview: json['supportsHdrPreview'] == true,
      supportsHdrExport: json['supportsHdrExport'] == true,
      maxTextureSize: (json['maxTextureSize'] as num?)?.toInt() ?? 0,
      renderer: json['renderer']?.toString() ?? '',
      vendor: json['vendor']?.toString() ?? '',
      recommendedQuality:
          json['recommendedQuality']?.toString() ?? 'compatibility8bit',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supportsGles3': supportsGles3,
      'supportsHalfFloatRenderTarget': supportsHalfFloatRenderTarget,
      'supportsFloatRenderTarget': supportsFloatRenderTarget,
      'supportsWideColorPreview': supportsWideColorPreview,
      'supportsHdrPreview': supportsHdrPreview,
      'supportsHdrExport': supportsHdrExport,
      'maxTextureSize': maxTextureSize,
      'renderer': renderer,
      'vendor': vendor,
      'recommendedQuality': recommendedQuality,
    };
  }
}
