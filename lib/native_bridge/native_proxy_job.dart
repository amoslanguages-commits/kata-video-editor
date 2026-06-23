class NativeProxyProfile {
  final int targetHeight;
  final int frameRate;
  final int videoBitrate;
  final int iFrameIntervalSeconds;
  final String codec;

  const NativeProxyProfile({
    this.targetHeight = 540,
    this.frameRate = 30,
    this.videoBitrate = 1500000,
    this.iFrameIntervalSeconds = 2,
    this.codec = 'video/avc',
  });

  factory NativeProxyProfile.lowQuality() => const NativeProxyProfile(
        targetHeight: 360,
        frameRate: 24,
        videoBitrate: 800000,
      );

  factory NativeProxyProfile.mediumQuality() => const NativeProxyProfile(
        targetHeight: 540,
        frameRate: 30,
        videoBitrate: 1500000,
      );

  factory NativeProxyProfile.highQuality() => const NativeProxyProfile(
        targetHeight: 720,
        frameRate: 30,
        videoBitrate: 3000000,
      );

  Map<String, dynamic> toJson() {
    return {
      'targetHeight': targetHeight,
      'frameRate': frameRate,
      'videoBitrate': videoBitrate,
      'iFrameIntervalSeconds': iFrameIntervalSeconds,
      'codec': codec,
    };
  }
}
