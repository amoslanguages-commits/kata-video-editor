class ExportDestinationModes {
  ExportDestinationModes._();

  static const String appExports = 'app_exports';
  static const String gallery = 'gallery';
  static const String shareOnly = 'share_only';
  static const String customFolder = 'custom_folder';
}

class ExportVideoCodecs {
  ExportVideoCodecs._();

  static const String h264 = 'video/avc';
  static const String h265 = 'video/hevc';
  static const String proRes = 'video/prores';
}

class ExportColorSpaces {
  ExportColorSpaces._();

  static const String rec709 = 'rec709';
  static const String rec2020 = 'rec2020';
  static const String displayP3 = 'display_p3';
}

class AdvancedExportSettings {
  final String destinationMode;
  final String? customDirectoryPath;
  final bool saveToGallery;
  final bool shareAfterExport;
  final String videoCodec;
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
  final String metadataTitle;
  final String metadataCreator;
  final bool writeMetadata;
  final bool generateThumbnail;
  final bool showCompletionNotification;
  final bool recoverAfterCrash;
  final bool enableMultiTrackQa;

  const AdvancedExportSettings({
    this.destinationMode = ExportDestinationModes.appExports,
    this.customDirectoryPath,
    this.saveToGallery = false,
    this.shareAfterExport = false,
    this.videoCodec = ExportVideoCodecs.h264,
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
    this.metadataTitle = '',
    this.metadataCreator = '',
    this.writeMetadata = true,
    this.generateThumbnail = true,
    this.showCompletionNotification = true,
    this.recoverAfterCrash = true,
    this.enableMultiTrackQa = true,
  });

  Map<String, dynamic> toSettingsMap() {
    return {
      'destinationMode': destinationMode,
      'customDirectoryPath': customDirectoryPath,
      'saveToGallery': saveToGallery,
      'shareAfterExport': shareAfterExport,
      'videoCodec': videoCodec,
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
      'metadataTitle': metadataTitle,
      'metadataCreator': metadataCreator,
      'writeMetadata': writeMetadata,
      'generateThumbnail': generateThumbnail,
      'showCompletionNotification': showCompletionNotification,
      'recoverAfterCrash': recoverAfterCrash,
      'enableMultiTrackQa': enableMultiTrackQa,
    };
  }

  factory AdvancedExportSettings.fromMap(Map<String, dynamic> map) {
    return AdvancedExportSettings(
      destinationMode: map['destinationMode']?.toString() ?? ExportDestinationModes.appExports,
      customDirectoryPath: map['customDirectoryPath']?.toString(),
      saveToGallery: map['saveToGallery'] == true,
      shareAfterExport: map['shareAfterExport'] == true,
      videoCodec: map['videoCodec']?.toString() ?? ExportVideoCodecs.h264,
      encoderProfile: map['encoderProfile']?.toString() ?? 'high',
      preferHardwareEncoder: map['preferHardwareEncoder'] != false,
      audioBitrateKbps: _asInt(map['audioBitrateKbps'], 192),
      audioSampleRate: _asInt(map['audioSampleRate'], 48000),
      audioChannels: _asInt(map['audioChannels'], 2),
      muteAllAudio: map['muteAllAudio'] == true,
      normalizeAudio: map['normalizeAudio'] == true,
      colorSpace: map['colorSpace']?.toString() ?? ExportColorSpaces.rec709,
      colorRange: map['colorRange']?.toString() ?? 'limited',
      hdrExport: map['hdrExport'] == true,
      toneMapHdrToSdr: map['toneMapHdrToSdr'] != false,
      bakeLut: map['bakeLut'] == true,
      metadataTitle: map['metadataTitle']?.toString() ?? '',
      metadataCreator: map['metadataCreator']?.toString() ?? '',
      writeMetadata: map['writeMetadata'] != false,
      generateThumbnail: map['generateThumbnail'] != false,
      showCompletionNotification: map['showCompletionNotification'] != false,
      recoverAfterCrash: map['recoverAfterCrash'] != false,
      enableMultiTrackQa: map['enableMultiTrackQa'] != false,
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
