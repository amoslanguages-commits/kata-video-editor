import 'dart:convert';

import 'package:nle_editor/domain/export/advanced_export_settings.dart';

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
  final String encoderProfile;
  final bool preferHardwareEncoder;
  final int audioBitrateKbps;
  final int audioSampleRate;
  final int audioChannels;
  final bool muteAllAudio;
  final bool normalizeAudio;
  final String colorSpace;
  final String colorRange;
  final bool hdrExport;
  final bool toneMapHdrToSdr;
  final bool bakeLut;
  final String destinationMode;
  final String? customDirectoryPath;
  final bool saveToGallery;
  final bool shareAfterExport;
  final bool generateThumbnail;
  final bool showCompletionNotification;
  final bool recoverAfterCrash;
  final bool enableMultiTrackQa;
  final Map<String, dynamic> metadata;

  const NativeExportProfile({
    this.width = 1920,
    this.height = 1080,
    this.frameRate = 30,
    this.bitrateBps = 8000000,
    this.gopInterval = 30,
    this.codec = ExportVideoCodecs.h264,
    this.containerFormat = 'video/mp4',
    this.encoderProfile = 'high',
    this.preferHardwareEncoder = true,
    this.audioBitrateKbps = 192,
    this.audioSampleRate = 48000,
    this.audioChannels = 2,
    this.muteAllAudio = false,
    this.normalizeAudio = false,
    this.colorSpace = ExportColorSpaces.rec709,
    this.colorRange = 'limited',
    this.hdrExport = false,
    this.toneMapHdrToSdr = true,
    this.bakeLut = false,
    this.destinationMode = ExportDestinationModes.appExports,
    this.customDirectoryPath,
    this.saveToGallery = false,
    this.shareAfterExport = false,
    this.generateThumbnail = true,
    this.showCompletionNotification = true,
    this.recoverAfterCrash = true,
    this.enableMultiTrackQa = true,
    this.metadata = const {},
  });

  /// Creates a [NativeExportProfile] from a settings map.
  factory NativeExportProfile.fromSettings(Map<String, dynamic> settings) {
    final resolutionHeight = (settings['resolution'] as int?) ?? 1080;
    final aspectRatio = settings['aspectRatio'] as String? ?? '16:9';

    int targetWidth = (settings['width'] as int?) ?? resolutionHeight * 16 ~/ 9;
    if (settings['width'] == null) {
      if (aspectRatio == '9:16') targetWidth = resolutionHeight * 9 ~/ 16;
      if (aspectRatio == '1:1') targetWidth = resolutionHeight;
      if (aspectRatio == '4:5') targetWidth = resolutionHeight * 4 ~/ 5;
      if (aspectRatio == '21:9') targetWidth = resolutionHeight * 21 ~/ 9;
    }
    targetWidth = (targetWidth ~/ 2) * 2;

    int bitrateBps = 8000000;
    final bitrateStr = settings['bitrate'] as String? ?? '8M';
    final bitrateMatch = RegExp(r'^(\d+(?:\.\d+)?)([KkMmGg])?$').firstMatch(bitrateStr);
    if (bitrateMatch != null) {
      final value = double.parse(bitrateMatch.group(1)!);
      final unit = bitrateMatch.group(2)?.toUpperCase() ?? '';
      bitrateBps = switch (unit) {
        'K' => (value * 1000).toInt(),
        'M' => (value * 1000000).toInt(),
        'G' => (value * 1000000000).toInt(),
        _ => value.toInt(),
      };
    }

    final advanced = AdvancedExportSettings.fromMap(settings);
    final metadata = <String, dynamic>{
      'title': advanced.metadataTitle,
      'creator': advanced.metadataCreator,
      'app': 'Kata Video Editor',
      'writeMetadata': advanced.writeMetadata,
    };

    return NativeExportProfile(
      width: targetWidth,
      height: resolutionHeight,
      frameRate: (settings['frameRate'] as int?) ?? 30,
      bitrateBps: bitrateBps,
      codec: advanced.videoCodec,
      containerFormat: advanced.videoCodec == ExportVideoCodecs.proRes ? 'video/quicktime' : 'video/mp4',
      encoderProfile: advanced.encoderProfile,
      preferHardwareEncoder: advanced.preferHardwareEncoder,
      audioBitrateKbps: advanced.audioBitrateKbps,
      audioSampleRate: advanced.audioSampleRate,
      audioChannels: advanced.audioChannels,
      muteAllAudio: advanced.muteAllAudio,
      normalizeAudio: advanced.normalizeAudio,
      colorSpace: advanced.colorSpace,
      colorRange: advanced.colorRange,
      hdrExport: advanced.hdrExport,
      toneMapHdrToSdr: advanced.toneMapHdrToSdr,
      bakeLut: advanced.bakeLut,
      destinationMode: advanced.destinationMode,
      customDirectoryPath: advanced.customDirectoryPath,
      saveToGallery: advanced.saveToGallery,
      shareAfterExport: advanced.shareAfterExport,
      generateThumbnail: advanced.generateThumbnail,
      showCompletionNotification: advanced.showCompletionNotification,
      recoverAfterCrash: advanced.recoverAfterCrash,
      enableMultiTrackQa: advanced.enableMultiTrackQa,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toMap() => {
        'width': width,
        'height': height,
        'frameRate': frameRate,
        'bitrateBps': bitrateBps,
        'gopInterval': gopInterval,
        'codec': codec,
        'containerFormat': containerFormat,
        'encoderProfile': encoderProfile,
        'preferHardwareEncoder': preferHardwareEncoder,
        'audioBitrateKbps': audioBitrateKbps,
        'audioSampleRate': audioSampleRate,
        'audioChannels': audioChannels,
        'muteAllAudio': muteAllAudio,
        'normalizeAudio': normalizeAudio,
        'colorSpace': colorSpace,
        'colorRange': colorRange,
        'hdrExport': hdrExport,
        'toneMapHdrToSdr': toneMapHdrToSdr,
        'bakeLut': bakeLut,
        'destinationMode': destinationMode,
        'customDirectoryPath': customDirectoryPath,
        'saveToGallery': saveToGallery,
        'shareAfterExport': shareAfterExport,
        'generateThumbnail': generateThumbnail,
        'showCompletionNotification': showCompletionNotification,
        'recoverAfterCrash': recoverAfterCrash,
        'enableMultiTrackQa': enableMultiTrackQa,
        'metadata': metadata,
      };

  String toJson() => jsonEncode(toMap());

  @override
  String toString() => 'NativeExportProfile($width×$height @${frameRate}fps)';
}
