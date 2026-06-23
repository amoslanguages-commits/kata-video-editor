import 'dart:convert';

/// Dart mirror of [NleExportProfile] on the Kotlin side.
///
/// Instances are serialised to a plain [Map] that is sent across the
/// MethodChannel as the `profile` key in a `start_export_job` command.
class NativeExportProfile {
  final int width;
  final int height;
  final int frameRate;
  final int bitrateBps;
  final int gopInterval;
  final String codec;
  final String containerFormat;

  const NativeExportProfile({
    this.width          = 1920,
    this.height         = 1080,
    this.frameRate      = 30,
    this.bitrateBps     = 8000000,
    this.gopInterval    = 30,
    this.codec          = 'video/avc',
    this.containerFormat = 'video/mp4',
  });

  /// Creates a [NativeExportProfile] from a settings map (e.g. from the
  /// export dialog). Accepts the same keys used by [ExportStateNotifier].
  factory NativeExportProfile.fromSettings(Map<String, dynamic> settings) {
    final resolutionHeight = (settings['resolution'] as int?) ?? 1080;
    final aspectRatio      = settings['aspectRatio'] as String? ?? '16:9';

    int targetWidth = resolutionHeight * 16 ~/ 9;
    if (aspectRatio == '9:16')  targetWidth = resolutionHeight * 9 ~/ 16;
    if (aspectRatio == '1:1')   targetWidth = resolutionHeight;
    if (aspectRatio == '4:5')   targetWidth = resolutionHeight * 4 ~/ 5;
    if (aspectRatio == '21:9')  targetWidth = resolutionHeight * 21 ~/ 9;
    targetWidth = (targetWidth ~/ 2) * 2;  // ensure even

    // Parse "8M" / "16M" bitrate strings to bps
    int bitrateBps = 8000000;
    final bitrateStr = settings['bitrate'] as String? ?? '8M';
    final bitrateMatch = RegExp(r'^(\d+(?:\.\d+)?)([KkMmGg])?$').firstMatch(bitrateStr);
    if (bitrateMatch != null) {
      final value  = double.parse(bitrateMatch.group(1)!);
      final unit   = bitrateMatch.group(2)?.toUpperCase() ?? '';
      bitrateBps = switch (unit) {
        'K' => (value * 1000).toInt(),
        'M' => (value * 1000000).toInt(),
        'G' => (value * 1000000000).toInt(),
        _   => value.toInt(),
      };
    }

    return NativeExportProfile(
      width:      targetWidth,
      height:     resolutionHeight,
      frameRate:  (settings['frameRate'] as int?) ?? 30,
      bitrateBps: bitrateBps,
    );
  }

  Map<String, dynamic> toMap() => {
    'width':           width,
    'height':          height,
    'frameRate':       frameRate,
    'bitrateBps':      bitrateBps,
    'gopInterval':     gopInterval,
    'codec':           codec,
    'containerFormat': containerFormat,
  };

  String toJson() => jsonEncode(toMap());

  @override
  String toString() => 'NativeExportProfile($width×$height @${frameRate}fps)';
}
