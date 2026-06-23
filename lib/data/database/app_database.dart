import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

// ============ PROJECTS TABLE ============

class Projects extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get aspectRatio => text().withDefault(const Constant('16:9'))();

  IntColumn get targetWidth => integer().withDefault(const Constant(1920))();
  IntColumn get targetHeight => integer().withDefault(const Constant(1080))();
  IntColumn get targetFrameRate => integer().withDefault(const Constant(30))();

  IntColumn get durationMicros => integer().withDefault(const Constant(0))();

  TextColumn get colorSpace => text().withDefault(const Constant('rec709'))();
  TextColumn get projectFolderPath => text().nullable()();

  TextColumn get previewQuality => text().withDefault(const Constant('auto'))();
  TextColumn get proxyMode => text().withDefault(const Constant('auto'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get modifiedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
  BoolColumn get hasWatermark => boolean().withDefault(const Constant(true))();

  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get exportPreset =>
      text().withDefault(const Constant('standard'))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get recoveryStatus =>
      text().withDefault(const Constant('clean'))();

  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSavedAt => dateTime().nullable()();

  // 30A-PRO: Color management pipeline settings (JSON blob).
  TextColumn get colorSettingsJson => text().nullable()();

  TextColumn get timelineColorGraphJson => text().nullable()();
  TextColumn get projectOutputColorGraphJson => text().nullable()();

  // 30I-PRO: Film look settings (JSON blob).
  TextColumn get timelineFilmLookJson => text().nullable()();

  // 30J-PRO: HDR output settings (JSON blob).
  TextColumn get hdrOutputSettingsJson => text().nullable()();

  // 33C-PRO: Audio effect rack master chain settings (JSON blob).
  TextColumn get masterEffectChainJson => text().nullable()();

  // 34B-PRO: Proxy Settings JSON blob
  TextColumn get proxySettingsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ ASSETS TABLE ============

class Assets extends Table {
  TextColumn get id => text()();

  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();

  TextColumn get originalPath => text()();
  TextColumn get originalUri => text().nullable()();

  TextColumn get fileName => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();

  TextColumn get fileType => text()(); // video, image, audio, unknown
  TextColumn get mimeType => text().nullable()();

  IntColumn get durationMicros => integer().nullable()();

  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();

  RealColumn get frameRate => real().nullable()();

  TextColumn get codec => text().nullable()();
  TextColumn get audioCodec => text().nullable()();

  IntColumn get bitrate => integer().nullable()();
  IntColumn get bitDepth => integer().nullable()();

  TextColumn get colorSpace => text().nullable()();

  IntColumn get audioChannels => integer().nullable()();
  IntColumn get audioSampleRate => integer().nullable()();

  IntColumn get rotation => integer().withDefault(const Constant(0))();

  BoolColumn get hasVideo => boolean().withDefault(const Constant(false))();
  BoolColumn get hasAudio => boolean().withDefault(const Constant(false))();
  BoolColumn get isVariableFrameRate =>
      boolean().withDefault(const Constant(false))();

  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get waveformPath => text().nullable()();
  TextColumn get proxyPath => text().nullable()();

  TextColumn get thumbnailStatus =>
      text().withDefault(const Constant('pending'))();
  TextColumn get waveformStatus =>
      text().withDefault(const Constant('pending'))();
  TextColumn get proxyStatus =>
      text().withDefault(const Constant('not_needed'))();

  IntColumn get proxyWidth => integer().nullable()();
  IntColumn get proxyHeight => integer().nullable()();
  TextColumn get proxyCodec => text().nullable()();
  IntColumn get proxyFileSize => integer().nullable()();

  TextColumn get importStatus =>
      text().withDefault(const Constant('imported'))();
  TextColumn get importMode =>
      text().withDefault(const Constant('reference'))();

  BoolColumn get isMissing => boolean().withDefault(const Constant(false))();

  TextColumn get errorMessage => text().nullable()();

  // 30A-PRO: Per-asset detected color metadata.
  TextColumn get inputColorSpace =>
      text().withDefault(const Constant('auto'))();
  TextColumn get inputTransferCurve =>
      text().withDefault(const Constant('auto'))();
  BoolColumn get isHdr => boolean().withDefault(const Constant(false))();
  BoolColumn get isWideGamut => boolean().withDefault(const Constant(false))();
  BoolColumn get isFullRange => boolean().withDefault(const Constant(true))();
  TextColumn get cameraLogProfile => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastKnownModifiedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ TRACKS TABLE ============

class Tracks extends Table {
  TextColumn get id => text()();

  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text()();
  TextColumn get type => text()(); // video, overlay, audio, text, adjustment

  IntColumn get index => integer().withDefault(const Constant(0))();

  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSolo => boolean().withDefault(const Constant(false))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();
  BoolColumn get isCollapsed => boolean().withDefault(const Constant(false))();

  RealColumn get volume => real().withDefault(const Constant(1.0))();
  RealColumn get opacity => real().withDefault(const Constant(1.0))();

  IntColumn get height => integer().withDefault(const Constant(64))();
  TextColumn get color => text().nullable()();

  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  TextColumn get colorHex => text().nullable()();
  TextColumn get trackRole => text().nullable()();

  // 33B-PRO: Audio automation (keyframes + effects + ducking) per track
  TextColumn get audioAutomationJson => text().nullable()();

  // 33C-PRO: Audio effect rack chain settings (JSON blob) per track.
  TextColumn get effectChainJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ CLIPS TABLE ============

class Clips extends Table {
  TextColumn get id => text()();

  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();

  TextColumn get trackId =>
      text().references(Tracks, #id, onDelete: KeyAction.cascade)();

  TextColumn get assetId =>
      text().references(Assets, #id, onDelete: KeyAction.setNull).nullable()();

  TextColumn get clipType => text().withDefault(const Constant('media'))();

  IntColumn get timelineStartMicros =>
      integer().withDefault(const Constant(0))();
  IntColumn get timelineEndMicros => integer().withDefault(const Constant(0))();

  IntColumn get sourceInMicros => integer().withDefault(const Constant(0))();
  IntColumn get sourceOutMicros => integer().withDefault(const Constant(0))();

  RealColumn get positionX => real().withDefault(const Constant(0.0))();
  RealColumn get positionY => real().withDefault(const Constant(0.0))();
  RealColumn get anchorX => real().withDefault(const Constant(0.5))();
  RealColumn get anchorY => real().withDefault(const Constant(0.5))();

  RealColumn get scale => real().withDefault(const Constant(1.0))();
  RealColumn get rotation => real().withDefault(const Constant(0.0))();
  RealColumn get opacity => real().withDefault(const Constant(1.0))();

  RealColumn get cropLeft => real().withDefault(const Constant(0.0))();
  RealColumn get cropTop => real().withDefault(const Constant(0.0))();
  RealColumn get cropRight => real().withDefault(const Constant(0.0))();
  RealColumn get cropBottom => real().withDefault(const Constant(0.0))();

  TextColumn get blendMode => text().withDefault(const Constant('normal'))();

  RealColumn get exposure => real().withDefault(const Constant(0.0))();
  RealColumn get contrast => real().withDefault(const Constant(1.0))();
  RealColumn get saturation => real().withDefault(const Constant(1.0))();
  RealColumn get temperature => real().withDefault(const Constant(0.0))();
  RealColumn get tint => real().withDefault(const Constant(0.0))();
  RealColumn get highlights => real().withDefault(const Constant(0.0))();
  RealColumn get shadows => real().withDefault(const Constant(0.0))();

  TextColumn get lutPath => text().nullable()();

  RealColumn get volume => real().withDefault(const Constant(1.0))();
  RealColumn get audioPan => real().withDefault(const Constant(0.0))();

  BoolColumn get isAudioMuted => boolean().withDefault(const Constant(false))();

  IntColumn get fadeInMicros => integer().withDefault(const Constant(5000))();
  IntColumn get fadeOutMicros => integer().withDefault(const Constant(5000))();

  TextColumn get textContent => text().nullable()();
  TextColumn get textStyle => text().nullable()();

  RealColumn get speed => real().withDefault(const Constant(1.0))();
  BoolColumn get isReversed => boolean().withDefault(const Constant(false))();

  BoolColumn get isLinked => boolean().withDefault(const Constant(false))();
  TextColumn get linkedClipId => text().nullable()();

  BoolColumn get isDisabled => boolean().withDefault(const Constant(false))();

  TextColumn get effectStack => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get fitMode => text().withDefault(const Constant('fit'))();
  RealColumn get brightness => real().withDefault(const Constant(0.0))();
  TextColumn get textStyleJson => text().nullable()();
  TextColumn get colorHex => text().nullable()();

  TextColumn get lutStackJson => text().nullable()();
  TextColumn get primaryGradeJson => text().nullable()();
  TextColumn get colorCurveStackJson => text().nullable()();
  TextColumn get secondaryGradeStackJson => text().nullable()();

  TextColumn get colorNodeGraphJson => text().nullable()();
  BoolColumn get isAdjustmentLayer => boolean().withDefault(const Constant(false))();
  TextColumn get adjustmentColorGraphJson => text().nullable()();

  // 30I-PRO: Film look settings (JSON blob).
  TextColumn get filmLookJson => text().nullable()();

  // 32A-PRO: Title Clip JSON data & type flag.
  TextColumn get titleDataJson => text().nullable()();
  BoolColumn get isTitleClip => boolean().withDefault(const Constant(false))();

  // 32C-PRO: Shape / sticker overlay data
  TextColumn get overlayDataJson => text().nullable()();
  BoolColumn get isOverlayClip => boolean().withDefault(const Constant(false))();

  // 32D-PRO: Motion templates tracking
  TextColumn get templateGroupId => text().nullable()();
  TextColumn get sourceTemplateId => text().nullable()();

  // 32E-PRO: Keyframe animation data
  TextColumn get keyframeTrackJson => text().nullable()();

  // 33B-PRO: Audio automation (keyframes + effects + ducking) per clip
  TextColumn get audioAutomationJson => text().nullable()();

  // 33C-PRO: Audio effect rack chain settings (JSON blob) per clip.
  TextColumn get effectChainJson => text().nullable()();

  // 33D-PRO: Voice recording studio takes integration
  TextColumn get voiceTakeId => text().nullable()();
  BoolColumn get isVoiceRecording => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get modifiedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ KEYFRAMES TABLE ============

class Keyframes extends Table {
  TextColumn get id => text()();

  TextColumn get clipId =>
      text().references(Clips, #id, onDelete: KeyAction.cascade)();

  TextColumn get parameter => text()();

  IntColumn get timeMicros => integer()();

  TextColumn get valueType => text().withDefault(const Constant('number'))();
  TextColumn get valueJson => text()();

  TextColumn get interpolation =>
      text().withDefault(const Constant('linear'))();
  TextColumn get easing => text().withDefault(const Constant('linear'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ UNDO / REDO COMMAND HISTORY ============

class UndoStack extends Table {
  TextColumn get id => text()();

  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();

  TextColumn get stackType =>
      text().withDefault(const Constant('undo'))(); // undo or redo

  TextColumn get actionType => text()();
  TextColumn get description => text().nullable()();

  TextColumn get payload => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get sequence => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ EXPORT JOBS ============

class ExportJobs extends Table {
  TextColumn get id => text()();

  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get progress => integer().withDefault(const Constant(0))();

  TextColumn get stage => text().withDefault(const Constant('Waiting'))();

  TextColumn get outputPath => text().nullable()();
  TextColumn get errorMessage => text().nullable()();

  TextColumn get settings => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BackgroundJobs extends Table {
  TextColumn get id => text()();

  TextColumn get projectId => text()
      .references(Projects, #id, onDelete: KeyAction.cascade)
      .nullable()();

  TextColumn get jobType => text()();

  TextColumn get status => text().withDefault(const Constant('queued'))();

  IntColumn get priority => integer().withDefault(const Constant(50))();

  IntColumn get progress => integer().withDefault(const Constant(0))();

  TextColumn get stage => text().withDefault(const Constant('Waiting'))();

  TextColumn get payload => text().withDefault(const Constant('{}'))();

  TextColumn get result => text().nullable()();

  TextColumn get errorMessage => text().nullable()();

  BoolColumn get cancellable => boolean().withDefault(const Constant(true))();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  IntColumn get maxRetries => integer().withDefault(const Constant(2))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get startedAt => dateTime().nullable()();

  DateTimeColumn get finishedAt => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ClipTransitions extends Table {
  TextColumn get id => text()();

  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();

  TextColumn get outgoingClipId =>
      text().references(Clips, #id, onDelete: KeyAction.cascade)();

  TextColumn get incomingClipId =>
      text().references(Clips, #id, onDelete: KeyAction.cascade)();

  TextColumn get transitionType =>
      text().withDefault(const Constant('dissolve'))();

  IntColumn get durationMicros =>
      integer().withDefault(const Constant(500000))();

  TextColumn get direction => text().withDefault(const Constant('center'))();

  TextColumn get easing => text().withDefault(const Constant('ease_in_out'))();

  TextColumn get parametersJson => text().withDefault(const Constant('{}'))();

  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();

  BoolColumn get isDisabled => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalTextPresets extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get category => text().withDefault(const Constant('Custom'))();

  TextColumn get styleJson => text().withDefault(const Constant('{}'))();

  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ APP LIFECYCLE CHECKPOINTS TABLE ============

/// One row per "session" for a project.
/// The app writes an OPEN record when the editor opens.
/// On clean exit it writes a CLOSE record.
/// If the CLOSE is missing on next launch → the previous session crashed.
class AppLifecycleCheckpoints extends Table {
  TextColumn get id => text()();

  /// Which project (null = app-level, e.g. dashboard open)
  TextColumn get projectId => text()
      .references(Projects, #id, onDelete: KeyAction.cascade)
      .nullable()();

  /// 'open' | 'close' | 'crash_detected'
  TextColumn get event => text()();

  /// App build / version string so we can detect version-related recoveries.
  TextColumn get appVersion => text().withDefault(const Constant(''))();

  /// Free-form JSON payload (e.g. last known playhead, export progress).
  TextColumn get contextJson => text().withDefault(const Constant('{}'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AppErrorLogs extends Table {
  TextColumn get id => text()();

  TextColumn get category => text()();

  TextColumn get code => text()();

  TextColumn get severity => text().withDefault(const Constant('warning'))();

  TextColumn get userMessage => text()();

  TextColumn get technicalMessage => text().nullable()();

  TextColumn get recoverySuggestion => text().nullable()();

  TextColumn get projectId => text()
      .references(Projects, #id, onDelete: KeyAction.setNull)
      .nullable()();

  TextColumn get source => text().nullable()();

  TextColumn get nativeCode => text().nullable()();

  TextColumn get actionLabel => text().nullable()();

  TextColumn get actionPayload => text().withDefault(const Constant('{}'))();

  TextColumn get contextJson => text().withDefault(const Constant('{}'))();

  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserCreativePresetData')
class UserCreativePresets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get sourceItemId => text().nullable()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LutAssets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get filePath => text()();
  TextColumn get sourceType => text().withDefault(const Constant('cube'))();
  IntColumn get size => integer().withDefault(const Constant(0))();
  BoolColumn get isValid => boolean().withDefault(const Constant(false))();
  TextColumn get previewThumbnailPath => text().nullable()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SubtitleTracks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get langCode => text().withDefault(const Constant('en'))();
  TextColumn get type => text().withDefault(const Constant('subtitles'))();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get burnedIn => boolean().withDefault(const Constant(true))();
  BoolColumn get exportSidecar => boolean().withDefault(const Constant(true))();

  TextColumn get exportFormat => text().withDefault(const Constant('srt'))();
  TextColumn get speakerMode => text().withDefault(const Constant('hidden'))();

  TextColumn get stylePresetJson => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class CaptionSegments extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get trackId => text()();

  IntColumn get startMicros => integer()();
  IntColumn get endMicros => integer()();

  TextColumn get textContent => text().named('text')();
  TextColumn get speaker => text().nullable()();

  RealColumn get confidence => real().withDefault(const Constant(1.0))();

  BoolColumn get locked => boolean().withDefault(const Constant(false))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  TextColumn get styleOverrideJson => text().nullable()();
  TextColumn get wordsJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ 33A-PRO: AUDIO WAVEFORM CACHE TABLE ============

/// Stores pre-rendered waveform peak data paths for audio assets.
/// One row per asset — keyed by assetId (not per-project).
class AudioWaveformCaches extends Table {
  /// The asset this waveform belongs to.
  TextColumn get assetId =>
      text().references(Assets, #id, onDelete: KeyAction.cascade)();

  /// Absolute path to the peak data binary/json file on device.
  TextColumn get peakDataPath => text().nullable()();

  /// Serialised inline samples (small, for short clips).
  TextColumn get samplesJson => text().nullable()();

  /// Samples stored per second.
  IntColumn get samplesPerSecond => integer().withDefault(const Constant(100))();

  /// 'pending' | 'rendering' | 'ready' | 'error'
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  TextColumn get errorMessage => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {assetId};
}

class MotionTemplatePacks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get source => text()();
  TextColumn get access => text()();
  TextColumn get packJson => text()();
  DateTimeColumn get installedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class MotionTemplateUsage extends Table {
  TextColumn get templateId => text()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {templateId};
}

class VoiceTakes extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get sessionId => text()();

  TextColumn get name => text()();
  TextColumn get localPath => text()();

  IntColumn get durationMicros => integer()();
  IntColumn get timelineStartMicros => integer()();

  TextColumn get status => text()();
  TextColumn get cleanupPreset => text()();

  TextColumn get audioClipId => text().nullable()();
  TextColumn get waveformCacheId => text().nullable()();

  TextColumn get formatInfoJson => text()();

  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ 34A-PRO: MEDIA ASSETS TABLES ============

class MediaAssets extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();

  TextColumn get displayName => text()();
  TextColumn get type => text()();
  TextColumn get importSource => text()();
  TextColumn get storageMode => text()();
  TextColumn get availability => text()();

  TextColumn get originalPath => text().nullable()();
  TextColumn get projectPath => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get waveformCacheId => text().nullable()();
  TextColumn get proxyPath => text().nullable()();

  TextColumn get proxyStatus => text()();
  TextColumn get usageState => text()();

  TextColumn get fileInfoJson => text()();
  TextColumn get videoInfoJson => text()();
  TextColumn get audioInfoJson => text()();
  TextColumn get timecodeInfoJson => text()();

  TextColumn get notes => text().nullable()();
  TextColumn get tagsJson => text()();

  DateTimeColumn get importedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  // 34B-PRO: Proxy metadata, error, and creation timestamp
  TextColumn get proxyMetadataJson => text().nullable()();
  TextColumn get proxyError => text().nullable()();
  DateTimeColumn get proxyCreatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ 34B-PRO: PROXY JOBS TABLE ============

class ProxyJobs extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get assetId => text().references(MediaAssets, #id, onDelete: KeyAction.cascade)();
  TextColumn get sourcePath => text()();
  TextColumn get outputPath => text()();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  TextColumn get reason => text().withDefault(const Constant('manual'))();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  TextColumn get specJson => text()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class MediaBins extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();

  TextColumn get name => text()();
  TextColumn get parentBinId => text().nullable()();

  IntColumn get sortIndex => integer()();
  BoolColumn get smartBin => boolean().withDefault(const Constant(false))();
  TextColumn get smartQuery => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class AssetBinLinks extends Table {
  TextColumn get assetId => text()();
  TextColumn get binId => text()();
  DateTimeColumn get linkedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {assetId, binId};
}

class MissingMediaRecords extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get lastKnownPath => text().nullable()();
  DateTimeColumn get detectedAt => dateTime()();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {assetId};
}

@DriftDatabase(
  tables: [
    Projects,
    Assets,
    Tracks,
    Clips,
    Keyframes,
    UndoStack,
    ExportJobs,
    BackgroundJobs,
    ClipTransitions,
    LocalTextPresets,
    AppErrorLogs,
    AppLifecycleCheckpoints,
    UserCreativePresets,
    LutAssets,
    SubtitleTracks,
    CaptionSegments,
    MotionTemplatePacks,
    MotionTemplateUsage,
    AudioWaveformCaches,
    VoiceTakes,
    MediaAssets,
    MediaBins,
    AssetBinLinks,
    MissingMediaRecords,
    ProxyJobs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 49;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(backgroundJobs);
        }
        if (from < 3) {
          await m.createTable(clipTransitions);
        }
        if (from < 4) {
          await m.createTable(localTextPresets);
        }
        if (from < 5) {
          await m.createTable(appErrorLogs);
        }
        if (from < 6) {
          await m.createTable(appLifecycleCheckpoints);
        }
        if (from < 7) {
          await m.createTable(userCreativePresets);
        }
        if (from < 8) {
          await m.addColumn(tracks, tracks.isHidden);
          await m.addColumn(tracks, tracks.colorHex);
          await m.addColumn(tracks, tracks.trackRole);
        }
        if (from < 9) {
          await m.addColumn(clips, clips.fitMode);
          await m.addColumn(clips, clips.brightness);
          await m.addColumn(clips, clips.textStyleJson);
          await m.addColumn(clips, clips.colorHex);
        }
        if (from < 10) {
          await m.addColumn(projects, projects.isDirty);
          await m.addColumn(projects, projects.lastSavedAt);
        }
        // 30A-PRO: Color management pipeline
        if (from < 11) {
          await m.addColumn(projects, projects.colorSettingsJson);
          await m.addColumn(assets, assets.inputColorSpace);
          await m.addColumn(assets, assets.inputTransferCurve);
          await m.addColumn(assets, assets.isHdr);
          await m.addColumn(assets, assets.isWideGamut);
          await m.addColumn(assets, assets.isFullRange);
          await m.addColumn(assets, assets.cameraLogProfile);
        }
        if (from < 12) {
          await m.createTable(lutAssets);
          await m.addColumn(clips, clips.lutStackJson);
        }
        if (from < 13) {
          await m.addColumn(clips, clips.primaryGradeJson);
        }
        if (from < 14) {
          await m.addColumn(clips, clips.colorCurveStackJson);
        }
        if (from < 15) {
          await m.addColumn(clips, clips.secondaryGradeStackJson);
        }
        if (from < 16) {
          await m.addColumn(clips, clips.colorNodeGraphJson);
          await m.addColumn(projects, projects.timelineColorGraphJson);
          await m.addColumn(projects, projects.projectOutputColorGraphJson);
          await m.addColumn(clips, clips.isAdjustmentLayer);
          await m.addColumn(clips, clips.adjustmentColorGraphJson);
        }
        if (from < 17) {
          await m.addColumn(clips, clips.filmLookJson);
          await m.addColumn(projects, projects.timelineFilmLookJson);
        }
        if (from < 18) {
          await m.addColumn(projects, projects.hdrOutputSettingsJson);
        }
        if (from < 39) {
          await m.addColumn(clips, clips.titleDataJson);
          await m.addColumn(clips, clips.isTitleClip);
        }
        if (from < 40) {
          await m.createTable(subtitleTracks);
          await m.createTable(captionSegments);
        }
        if (from < 41) {
          await m.addColumn(clips, clips.overlayDataJson);
          await m.addColumn(clips, clips.isOverlayClip);
        }
        if (from < 42) {
          await m.createTable(motionTemplatePacks);
          await m.createTable(motionTemplateUsage);
          await m.addColumn(clips, clips.templateGroupId);
          await m.addColumn(clips, clips.sourceTemplateId);
        }
        if (from < 43) {
          await m.addColumn(clips, clips.keyframeTrackJson);
        }
        // 33A-PRO: Audio Engine Foundation
        if (from < 44) {
          await m.createTable(audioWaveformCaches);
        }
        // 33B-PRO: Audio Automation
        if (from < 45) {
          await m.addColumn(clips, clips.audioAutomationJson);
          await m.addColumn(tracks, tracks.audioAutomationJson);
        }
        // 33C-PRO: Audio Effects Rack
        if (from < 46) {
          await m.addColumn(clips, clips.effectChainJson);
          await m.addColumn(tracks, tracks.effectChainJson);
          await m.addColumn(projects, projects.masterEffectChainJson);
        }
        // 33D-PRO: Voice recording studio
        if (from < 47) {
          await m.createTable(voiceTakes);
          await m.addColumn(clips, clips.voiceTakeId);
          await m.addColumn(clips, clips.isVoiceRecording);
        }
        // 34A-PRO: Media Library / Asset Management
        if (from < 48) {
          await m.createTable(mediaAssets);
          await m.createTable(mediaBins);
          await m.createTable(assetBinLinks);
          await m.createTable(missingMediaRecords);
        }
        // 34B-PRO: Proxy Media Workflow
        if (from < 49) {
          try { await m.addColumn(projects, projects.proxySettingsJson); } catch (_) {}
          try { await m.addColumn(mediaAssets, mediaAssets.proxyMetadataJson); } catch (_) {}
          try { await m.addColumn(mediaAssets, mediaAssets.proxyError); } catch (_) {}
          try { await m.addColumn(mediaAssets, mediaAssets.proxyCreatedAt); } catch (_) {}
          try { await m.createTable(proxyJobs); } catch (_) {}
        }
      },
    );
  }

  // ---------- User Creative Presets ----------

  Future<void> insertUserCreativePreset(UserCreativePresetsCompanion preset) {
    return into(userCreativePresets).insertOnConflictUpdate(preset);
  }

  Stream<List<UserCreativePresetData>> watchUserCreativePresets(String type) {
    return (select(userCreativePresets)
          ..where((tbl) => tbl.type.equals(type))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
        .watch();
  }

  Future<List<UserCreativePresetData>> getUserCreativePresets(String type) {
    return (select(userCreativePresets)
          ..where((tbl) => tbl.type.equals(type))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
        .get();
  }

  Future<void> deleteUserCreativePreset(String id) {
    return (delete(userCreativePresets)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  // ---------- 30A-PRO: Color Management ----------

  Future<void> updateProjectColorSettingsJson({
    required String projectId,
    required String colorSettingsJson,
  }) async {
    await (update(projects)..where((tbl) => tbl.id.equals(projectId))).write(
      ProjectsCompanion(
        colorSettingsJson: Value(colorSettingsJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipColorNodeGraphJson({
    required String clipId,
    required String colorNodeGraphJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        colorNodeGraphJson: Value(colorNodeGraphJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipAdjustmentColorGraphJson({
    required String clipId,
    required String adjustmentColorGraphJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        adjustmentColorGraphJson: Value(adjustmentColorGraphJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateProjectTimelineColorGraphJson({
    required String projectId,
    required String timelineColorGraphJson,
  }) async {
    await (update(projects)..where((tbl) => tbl.id.equals(projectId))).write(
      ProjectsCompanion(
        timelineColorGraphJson: Value(timelineColorGraphJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateProjectOutputColorGraphJson({
    required String projectId,
    required String projectOutputColorGraphJson,
  }) async {
    await (update(projects)..where((tbl) => tbl.id.equals(projectId))).write(
      ProjectsCompanion(
        projectOutputColorGraphJson: Value(projectOutputColorGraphJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- 30I-PRO: Film Look ----------

  Future<void> updateClipFilmLookJson({
    required String clipId,
    required String filmLookJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        filmLookJson: Value(filmLookJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateProjectTimelineFilmLookJson({
    required String projectId,
    required String timelineFilmLookJson,
  }) async {
    await (update(projects)..where((tbl) => tbl.id.equals(projectId))).write(
      ProjectsCompanion(
        timelineFilmLookJson: Value(timelineFilmLookJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateProjectHdrOutputSettingsJson({
    required String projectId,
    required String hdrOutputSettingsJson,
  }) async {
    await (update(projects)..where((tbl) => tbl.id.equals(projectId))).write(
      ProjectsCompanion(
        hdrOutputSettingsJson: Value(hdrOutputSettingsJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- 32A-PRO: Titles ----------

  Future<void> updateClipTitleDataJson({
    required String clipId,
    required String titleDataJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        titleDataJson: Value(titleDataJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> insertTitleClip({
    required String id,
    required String projectId,
    required String trackId,
    required String name,
    required int timelineStartMicros,
    required int durationMicros,
    required String titleDataJson,
  }) async {
    await into(clips).insert(
      ClipsCompanion.insert(
        id: id,
        projectId: projectId,
        trackId: trackId,
        assetId: const Value(null),
        clipType: const Value('title'),
        timelineStartMicros: Value(timelineStartMicros),
        timelineEndMicros: Value(timelineStartMicros + durationMicros),
        sourceInMicros: const Value(0),
        sourceOutMicros: Value(durationMicros),
        isTitleClip: const Value(true),
        titleDataJson: Value(titleDataJson),
        createdAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipOverlayDataJson({
    required String clipId,
    required String overlayDataJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        overlayDataJson: Value(overlayDataJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> insertOverlayClip({
    required String id,
    required String projectId,
    required String trackId,
    required String name,
    required int timelineStartMicros,
    required int durationMicros,
    required String overlayDataJson,
  }) async {
    await into(clips).insert(
      ClipsCompanion.insert(
        id: id,
        projectId: projectId,
        trackId: trackId,
        assetId: const Value(null),
        clipType: const Value('overlay'),
        timelineStartMicros: Value(timelineStartMicros),
        timelineEndMicros: Value(timelineStartMicros + durationMicros),
        sourceInMicros: const Value(0),
        sourceOutMicros: Value(durationMicros),
        isOverlayClip: const Value(true),
        overlayDataJson: Value(overlayDataJson),
        createdAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateAssetColorMetadata({
    required String assetId,
    required String inputColorSpace,
    required String inputTransferCurve,
    required bool isHdr,
    required bool isWideGamut,
    required bool isFullRange,
    String? cameraLogProfile,
  }) async {
    await (update(assets)..where((tbl) => tbl.id.equals(assetId))).write(
      AssetsCompanion(
        inputColorSpace: Value(inputColorSpace),
        inputTransferCurve: Value(inputTransferCurve),
        isHdr: Value(isHdr),
        isWideGamut: Value(isWideGamut),
        isFullRange: Value(isFullRange),
        cameraLogProfile: Value(cameraLogProfile),
      ),
    );
  }

  // ---------- Projects ----------

  Stream<List<Project>> watchAllProjects() {
    return (select(projects)
          ..where((p) => p.isArchived.equals(false))
          ..orderBy([
            (p) => OrderingTerm(
                  expression: p.modifiedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<List<Project>> getAllProjects() {
    return (select(projects)
          ..where((p) => p.isArchived.equals(false))
          ..orderBy([
            (p) => OrderingTerm(
                  expression: p.modifiedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  Future<Project?> getProject(String id) {
    return (select(projects)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<Project> getProjectById(String projectId) {
    final query = select(projects)..where((tbl) => tbl.id.equals(projectId));
    return query.getSingle();
  }

  Future<List<Asset>> getProjectAssetsOnce(String projectId) {
    final query = select(assets)
      ..where((tbl) => tbl.projectId.equals(projectId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);
    return query.get();
  }

  Future<List<Asset>> getAssetsByIds(List<String> assetIds) {
    if (assetIds.isEmpty) {
      return Future.value(const []);
    }
    final query = select(assets)..where((tbl) => tbl.id.isIn(assetIds));
    return query.get();
  }

  Future<void> insertProject(ProjectsCompanion project) async {
    await into(projects).insert(project);
  }

  Future<void> touchProject(String projectId) async {
    await (update(projects)..where((p) => p.id.equals(projectId))).write(
      ProjectsCompanion(
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateProjectDuration(
      String projectId, int durationMicros) async {
    await (update(projects)..where((p) => p.id.equals(projectId))).write(
      ProjectsCompanion(
        durationMicros: Value(durationMicros),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteProject(String id) {
    return (delete(projects)..where((p) => p.id.equals(id))).go();
  }

  // ---------- Assets ----------

  Stream<List<Asset>> watchProjectAssets(String projectId) {
    return (select(assets)
          ..where((a) => a.projectId.equals(projectId))
          ..orderBy([
            (a) => OrderingTerm(
                  expression: a.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<List<Asset>> getProjectAssets(String projectId) {
    return (select(assets)
          ..where((a) => a.projectId.equals(projectId))
          ..orderBy([
            (a) => OrderingTerm(
                  expression: a.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  Future<Asset?> getAsset(String id) {
    return (select(assets)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertAsset(AssetsCompanion asset) async {
    await into(assets).insert(asset);
  }

  Future<int> deleteAsset(String id) {
    return (delete(assets)..where((a) => a.id.equals(id))).go();
  }

  // ---------- Tracks ----------

  Stream<List<Track>> watchProjectTracks(String projectId) {
    return (select(tracks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.index),
          ]))
        .watch();
  }

  Future<List<Track>> getProjectTracks(String projectId) {
    return (select(tracks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.index),
          ]))
        .get();
  }

  Future<Track?> getFirstTrackByType(String projectId, String type) {
    return (select(tracks)
          ..where((t) => t.projectId.equals(projectId) & t.type.equals(type))
          ..orderBy([
            (t) => OrderingTerm(expression: t.index),
          ]))
        .getSingleOrNull();
  }

  Future<void> insertTrack(TracksCompanion track) async {
    await into(tracks).insert(track);
  }

  Future<void> updateTrackFields(
      String trackId, TracksCompanion companion) async {
    await (update(tracks)..where((t) => t.id.equals(trackId))).write(companion);
  }

  Future<Track> getTrack(String trackId) {
    final query = select(tracks)..where((tbl) => tbl.id.equals(trackId));
    return query.getSingle();
  }

  Future<void> renameTrack({
    required String trackId,
    required String name,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Track name cannot be empty.');
    }
    await updateTrackFields(
      trackId,
      TracksCompanion(
        name: Value(cleanName),
      ),
    );
  }

  Future<void> setTrackMuted({
    required String trackId,
    required bool muted,
  }) async {
    await updateTrackFields(
      trackId,
      TracksCompanion(
        isMuted: Value(muted),
      ),
    );
  }

  Future<void> setTrackSolo({
    required String trackId,
    required bool solo,
  }) async {
    await updateTrackFields(
      trackId,
      TracksCompanion(
        isSolo: Value(solo),
      ),
    );
  }

  Future<void> setTrackLocked({
    required String trackId,
    required bool locked,
  }) async {
    await updateTrackFields(
      trackId,
      TracksCompanion(
        isLocked: Value(locked),
      ),
    );
  }

  Future<void> setTrackHidden({
    required String trackId,
    required bool hidden,
  }) async {
    await updateTrackFields(
      trackId,
      TracksCompanion(
        isHidden: Value(hidden),
      ),
    );
  }

  Future<void> setTrackHeight({
    required String trackId,
    required double height,
  }) async {
    final clamped = height.clamp(36.0, 120.0).toDouble();
    await updateTrackFields(
      trackId,
      TracksCompanion(
        height: Value(clamped.round()),
      ),
    );
  }

  Future<void> setTrackColor({
    required String trackId,
    required String colorHex,
  }) async {
    await updateTrackFields(
      trackId,
      TracksCompanion(
        colorHex: Value(colorHex),
      ),
    );
  }

  // ---------- Clips ----------

  Stream<List<Clip>> watchTrackClips(String trackId) {
    return (select(clips)
          ..where((c) => c.trackId.equals(trackId))
          ..orderBy([
            (c) => OrderingTerm(expression: c.timelineStartMicros),
            (c) => OrderingTerm(expression: c.sortOrder),
          ]))
        .watch();
  }

  Future<List<Clip>> getTrackClips(String trackId) {
    return (select(clips)
          ..where((c) => c.trackId.equals(trackId))
          ..orderBy([
            (c) => OrderingTerm(expression: c.timelineStartMicros),
            (c) => OrderingTerm(expression: c.sortOrder),
          ]))
        .get();
  }

  Future<List<Clip>> getProjectClips(String projectId) {
    return (select(clips)
          ..where((c) => c.projectId.equals(projectId))
          ..orderBy([
            (c) => OrderingTerm(expression: c.timelineStartMicros),
          ]))
        .get();
  }

  Future<Clip?> getClip(String clipId) {
    return (select(clips)..where((c) => c.id.equals(clipId))).getSingleOrNull();
  }

  Future<void> insertClip(ClipsCompanion clip) async {
    await into(clips).insert(clip);
  }

  // ── 29F: source preview insert helpers ─────────────────────────────────

  /// Returns the first track compatible with [assetType] in the given project,
  /// ordered by track index ascending.
  Future<Track?> getFirstCompatibleTrackForAsset({
    required String projectId,
    required String assetType,
  }) async {
    final type = assetType.toLowerCase();
    final isAudio =
        type == 'audio' || type == 'music' || type == 'voice' || type == 'sfx';

    return (select(tracks)
          ..where((tbl) => tbl.projectId.equals(projectId))
          ..where((tbl) {
            if (isAudio) return tbl.type.equals('audio');
            return tbl.type.equals('video') |
                tbl.type.equals('overlay') |
                tbl.type.equals('text');
          })
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.index)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Inserts a new clip trimmed to [sourceStartMicros]..[sourceEndMicros] at
  /// [timelineStartMicros] on track [trackId].  Returns the new clip id.
  Future<String> insertSourceRangeClip({
    required String projectId,
    required String assetId,
    required String assetType,
    required String name,
    required String trackId,
    required int timelineStartMicros,
    required int sourceStartMicros,
    required int sourceEndMicros,
  }) async {
    final clipId = const Uuid().v4();
    final duration = sourceEndMicros - sourceStartMicros;
    final now = DateTime.now();

    final clipType = _clipTypeForAsset(assetType);

    await into(clips).insert(
      ClipsCompanion.insert(
        id: clipId,
        projectId: projectId,
        trackId: trackId,
        assetId: Value(assetId),
        clipType: Value(clipType),
        timelineStartMicros: Value(timelineStartMicros),
        timelineEndMicros: Value(timelineStartMicros + duration),
        sourceInMicros: Value(sourceStartMicros),
        sourceOutMicros: Value(sourceEndMicros),
        createdAt: Value(now),
        modifiedAt: Value(now),
      ),
    );

    return clipId;
  }

  /// Inserts TWO linked clips (video and audio) for the same source asset,
  /// placing them on different tracks. Returns the video clip ID.
  Future<String> insertLinkedSourceRangeClips({
    required String projectId,
    required String assetId,
    required String name,
    required String videoTrackId,
    required String audioTrackId,
    required int timelineStartMicros,
    required int sourceStartMicros,
    required int sourceEndMicros,
  }) async {
    final videoClipId = const Uuid().v4();
    final audioClipId = const Uuid().v4();
    final duration = sourceEndMicros - sourceStartMicros;
    final now = DateTime.now();

    await transaction(() async {
      // Insert Video Clip
      await into(clips).insert(
        ClipsCompanion.insert(
          id: videoClipId,
          projectId: projectId,
          trackId: videoTrackId,
          assetId: Value(assetId),
          clipType: const Value('video'), // Force video
          timelineStartMicros: Value(timelineStartMicros),
          timelineEndMicros: Value(timelineStartMicros + duration),
          sourceInMicros: Value(sourceStartMicros),
          sourceOutMicros: Value(sourceEndMicros),
          isLinked: const Value(true),
          linkedClipId: Value(audioClipId),
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );

      // Insert Audio Clip
      await into(clips).insert(
        ClipsCompanion.insert(
          id: audioClipId,
          projectId: projectId,
          trackId: audioTrackId,
          assetId: Value(assetId),
          clipType: const Value('audio'), // Force audio
          timelineStartMicros: Value(timelineStartMicros),
          timelineEndMicros: Value(timelineStartMicros + duration),
          sourceInMicros: Value(sourceStartMicros),
          sourceOutMicros: Value(sourceEndMicros),
          isLinked: const Value(true),
          linkedClipId: Value(videoClipId),
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );
    });

    return videoClipId;
  }

  String _clipTypeForAsset(String assetType) {
    final t = assetType.toLowerCase();
    if (t == 'photo') return 'image';
    if (t == 'music' || t == 'voice' || t == 'sfx') return 'audio';
    return t;
  }

  Future<void> updateClipFields(String clipId, ClipsCompanion companion) async {
    await (update(clips)..where((c) => c.id.equals(clipId))).write(companion);
  }

  Future<int> deleteClip(String id) {
    return (delete(clips)..where((c) => c.id.equals(id))).go();
  }

  Stream<Clip?> watchClip(String clipId) {
    final query = select(clips)..where((tbl) => tbl.id.equals(clipId));
    return query.watchSingleOrNull();
  }

  Future<void> updateClipTransform({
    required String clipId,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    double? opacity,
  }) async {
    await updateClipFields(
      clipId,
      ClipsCompanion(
        positionX: positionX == null ? const Value.absent() : Value(positionX),
        positionY: positionY == null ? const Value.absent() : Value(positionY),
        scale: scale == null ? const Value.absent() : Value(scale),
        rotation: rotation == null ? const Value.absent() : Value(rotation),
        opacity: opacity == null ? const Value.absent() : Value(opacity),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipFitAndCrop({
    required String clipId,
    String? fitMode,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
  }) async {
    await updateClipFields(
      clipId,
      ClipsCompanion(
        fitMode: fitMode == null ? const Value.absent() : Value(fitMode),
        cropLeft: cropLeft == null ? const Value.absent() : Value(cropLeft),
        cropTop: cropTop == null ? const Value.absent() : Value(cropTop),
        cropRight: cropRight == null ? const Value.absent() : Value(cropRight),
        cropBottom:
            cropBottom == null ? const Value.absent() : Value(cropBottom),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipSpeed({
    required String clipId,
    required double speed,
  }) async {
    await updateClipFields(
      clipId,
      ClipsCompanion(
        speed: Value(speed.clamp(0.1, 8.0)),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipAudio({
    required String clipId,
    double? volume,
    int? fadeInMicros,
    int? fadeOutMicros,
  }) async {
    await updateClipFields(
      clipId,
      ClipsCompanion(
        volume: volume == null
            ? const Value.absent()
            : Value(volume.clamp(0.0, 2.0)),
        fadeInMicros: fadeInMicros == null
            ? const Value.absent()
            : Value(fadeInMicros.clamp(0, 60000000)),
        fadeOutMicros: fadeOutMicros == null
            ? const Value.absent()
            : Value(fadeOutMicros.clamp(0, 60000000)),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipColorAdjustments({
    required String clipId,
    double? brightness,
    double? contrast,
    double? saturation,
    double? exposure,
    double? temperature,
    double? tint,
    double? highlights,
    double? shadows,
  }) async {
    await updateClipFields(
      clipId,
      ClipsCompanion(
        brightness: brightness == null
            ? const Value.absent()
            : Value(brightness.clamp(-1.0, 1.0)),
        contrast: contrast == null
            ? const Value.absent()
            : Value(contrast.clamp(0.0, 3.0)),
        saturation: saturation == null
            ? const Value.absent()
            : Value(saturation.clamp(0.0, 3.0)),
        exposure: exposure == null
            ? const Value.absent()
            : Value(exposure.clamp(-2.0, 2.0)),
        temperature: temperature == null
            ? const Value.absent()
            : Value(temperature.clamp(-1.0, 1.0)),
        tint: tint == null
            ? const Value.absent()
            : Value(tint.clamp(-1.0, 1.0)),
        highlights: highlights == null
            ? const Value.absent()
            : Value(highlights.clamp(-1.0, 1.0)),
        shadows: shadows == null
            ? const Value.absent()
            : Value(shadows.clamp(-1.0, 1.0)),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipPrimaryGradeJson({
    required String clipId,
    required String primaryGradeJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        primaryGradeJson: Value(primaryGradeJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTextClip({
    required String clipId,
    String? textContent,
    String? textStyleJson,
    String? colorHex,
  }) async {
    await updateClipFields(
      clipId,
      ClipsCompanion(
        textContent:
            textContent == null ? const Value.absent() : Value(textContent),
        textStyleJson:
            textStyleJson == null ? const Value.absent() : Value(textStyleJson),
        colorHex: colorHex == null ? const Value.absent() : Value(colorHex),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> resetClipVisualAdjustments(String clipId) async {
    await updateClipFields(
      clipId,
      ClipsCompanion(
        positionX: const Value(0.0),
        positionY: const Value(0.0),
        scale: const Value(1.0),
        rotation: const Value(0.0),
        opacity: const Value(1.0),
        fitMode: const Value('fit'),
        cropLeft: const Value(0.0),
        cropTop: const Value(0.0),
        cropRight: const Value(0.0),
        cropBottom: const Value(0.0),
        brightness: const Value(0.0),
        contrast: const Value(1.0),
        saturation: const Value(1.0),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- Undo / Redo ----------

  Future<void> insertHistory(UndoStackCompanion entry) async {
    await into(undoStack).insert(entry);
  }

  Future<UndoStackData?> getLastHistory(String projectId, String stackType) {
    return (select(undoStack)
          ..where((u) =>
              u.projectId.equals(projectId) & u.stackType.equals(stackType))
          ..orderBy([
            (u) => OrderingTerm(
                  expression: u.sequence,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> moveHistoryToStack(String id, String stackType) async {
    await (update(undoStack)..where((u) => u.id.equals(id))).write(
      UndoStackCompanion(
        stackType: Value(stackType),
      ),
    );
  }

  Future<void> clearRedoStack(String projectId) async {
    await (delete(undoStack)
          ..where((u) =>
              u.projectId.equals(projectId) & u.stackType.equals('redo')))
        .go();
  }

  Future<void> clearAllHistory(String projectId) async {
    await (delete(undoStack)..where((u) => u.projectId.equals(projectId))).go();
  }

  // ---------- Export Jobs ----------

  Stream<List<ExportJob>> watchProjectExports(String projectId) {
    return (select(exportJobs)
          ..where((e) => e.projectId.equals(projectId))
          ..orderBy([
            (e) => OrderingTerm(
                  expression: e.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<void> insertExportJob(ExportJobsCompanion job) async {
    await into(exportJobs).insert(job);
  }

  Future<void> updateExportJob(
      String jobId, ExportJobsCompanion companion) async {
    await (update(exportJobs)..where((e) => e.id.equals(jobId)))
        .write(companion);
  }

  // ---------- Extra helpers ----------

  Future<void> updateProjectFields(
      String projectId, ProjectsCompanion companion) async {
    await (update(projects)..where((p) => p.id.equals(projectId)))
        .write(companion);
  }

  Future<void> updateAssetFields(
      String assetId, AssetsCompanion companion) async {
    await (update(assets)..where((a) => a.id.equals(assetId))).write(companion);
  }

  Future<void> markAssetMissing(String assetId, String message) async {
    await (update(assets)..where((a) => a.id.equals(assetId))).write(
      AssetsCompanion(
        isMissing: const Value(true),
        importStatus: const Value('missing'),
        errorMessage: Value(message),
      ),
    );
  }

  Stream<List<Clip>> watchProjectClips(String projectId) {
    return (select(clips)
          ..where((c) => c.projectId.equals(projectId))
          ..orderBy([
            (c) => OrderingTerm(expression: c.timelineStartMicros),
            (c) => OrderingTerm(expression: c.sortOrder),
          ]))
        .watch();
  }

  Future<void> markAssetAvailable(String assetId) async {
    await (update(assets)..where((a) => a.id.equals(assetId))).write(
      const AssetsCompanion(
        isMissing: Value(false),
        errorMessage: Value(null),
      ),
    );
  }

  Future<Asset?> getAssetByOriginalPath(String projectId, String path) {
    return (select(assets)
          ..where((a) =>
              a.projectId.equals(projectId) & a.originalPath.equals(path)))
        .getSingleOrNull();
  }

  Stream<List<Keyframe>> watchClipKeyframes(String clipId) {
    return (select(keyframes)
          ..where((k) => k.clipId.equals(clipId))
          ..orderBy([
            (k) => OrderingTerm(expression: k.parameter),
            (k) => OrderingTerm(expression: k.timeMicros),
          ]))
        .watch();
  }

  Future<List<Keyframe>> getClipKeyframes(String clipId) {
    return (select(keyframes)
          ..where((k) => k.clipId.equals(clipId))
          ..orderBy([
            (k) => OrderingTerm(expression: k.parameter),
            (k) => OrderingTerm(expression: k.timeMicros),
          ]))
        .get();
  }

  Future<List<Keyframe>> getClipParameterKeyframes({
    required String clipId,
    required String parameter,
  }) {
    return (select(keyframes)
          ..where(
            (k) => k.clipId.equals(clipId) & k.parameter.equals(parameter),
          )
          ..orderBy([
            (k) => OrderingTerm(expression: k.timeMicros),
          ]))
        .get();
  }

  Future<Keyframe?> getKeyframe(String keyframeId) {
    return (select(keyframes)..where((k) => k.id.equals(keyframeId)))
        .getSingleOrNull();
  }

  Future<void> insertKeyframe(KeyframesCompanion keyframe) async {
    await into(keyframes).insert(keyframe);
  }

  Future<void> updateKeyframeFields(
    String keyframeId,
    KeyframesCompanion companion,
  ) async {
    await (update(keyframes)..where((k) => k.id.equals(keyframeId))).write(
      companion,
    );
  }

  Future<int> deleteKeyframe(String keyframeId) {
    return (delete(keyframes)..where((k) => k.id.equals(keyframeId))).go();
  }

  Future<int> deleteClipKeyframes(String clipId) {
    return (delete(keyframes)..where((k) => k.clipId.equals(clipId))).go();
  }

  Future<List<Keyframe>> getProjectKeyframes(String projectId) async {
    final projectClips = await getProjectClips(projectId);

    if (projectClips.isEmpty) {
      return [];
    }

    final clipIds = projectClips.map((clip) => clip.id).toList();

    return (select(keyframes)
          ..where((k) => k.clipId.isIn(clipIds))
          ..orderBy([
            (k) => OrderingTerm(expression: k.clipId),
            (k) => OrderingTerm(expression: k.parameter),
            (k) => OrderingTerm(expression: k.timeMicros),
          ]))
        .get();
  }

  Future<void> insertBackgroundJob(BackgroundJobsCompanion job) async {
    await into(backgroundJobs).insert(job);
  }

  Future<BackgroundJob?> getBackgroundJob(String jobId) {
    return (select(backgroundJobs)..where((j) => j.id.equals(jobId)))
        .getSingleOrNull();
  }

  Stream<List<BackgroundJob>> watchProjectJobs(String projectId) {
    return (select(backgroundJobs)
          ..where((j) => j.projectId.equals(projectId))
          ..orderBy([
            (j) => OrderingTerm(
                  expression: j.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Stream<List<BackgroundJob>> watchActiveJobs() {
    return (select(backgroundJobs)
          ..where(
            (j) =>
                j.status.equals('queued') |
                j.status.equals('running') |
                j.status.equals('waiting'),
          )
          ..orderBy([
            (j) => OrderingTerm(
                  expression: j.priority,
                  mode: OrderingMode.desc,
                ),
            (j) => OrderingTerm(expression: j.createdAt),
          ]))
        .watch();
  }

  Future<BackgroundJob?> getNextQueuedJob() {
    return (select(backgroundJobs)
          ..where((j) => j.status.equals('queued'))
          ..orderBy([
            (j) => OrderingTerm(
                  expression: j.priority,
                  mode: OrderingMode.desc,
                ),
            (j) => OrderingTerm(expression: j.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> updateBackgroundJobFields(
    String jobId,
    BackgroundJobsCompanion companion,
  ) async {
    await (update(backgroundJobs)..where((j) => j.id.equals(jobId))).write(
      companion.copyWith(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> cancelBackgroundJob(String jobId) async {
    await (update(backgroundJobs)..where((j) => j.id.equals(jobId))).write(
      BackgroundJobsCompanion(
        status: const Value('cancelled'),
        stage: const Value('Cancelled'),
        finishedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<BackgroundJob>> getInterruptedBackgroundJobs({
    String? projectId,
  }) {
    final query = select(backgroundJobs)
      ..where(
        (j) =>
            j.status.equals('running') |
            j.status.equals('waiting') |
            j.status.equals('paused'),
      );

    if (projectId != null) {
      query.where((j) => j.projectId.equals(projectId));
    }

    return query.get();
  }

  Future<int> markInterruptedBackgroundJobs({
    String? projectId,
  }) {
    final query = update(backgroundJobs)
      ..where(
        (j) =>
            j.status.equals('running') |
            j.status.equals('waiting') |
            j.status.equals('paused'),
      );

    if (projectId != null) {
      query.where((j) => j.projectId.equals(projectId));
    }

    return query.write(
      BackgroundJobsCompanion(
        status: const Value('failed'),
        stage: const Value('Interrupted'),
        errorMessage: const Value(
          'The app was closed or interrupted while this job was running.',
        ),
        finishedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateProjectRecoveryStatus({
    required String projectId,
    required String recoveryStatus,
  }) async {
    await (update(projects)..where((p) => p.id.equals(projectId))).write(
      ProjectsCompanion(
        recoveryStatus: Value(recoveryStatus),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<ClipTransition>> watchProjectTransitions(String projectId) {
    return (select(clipTransitions)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch();
  }

  Future<List<ClipTransition>> getProjectTransitions(String projectId) {
    return (select(clipTransitions)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
  }

  Future<ClipTransition?> getClipTransition(String transitionId) {
    return (select(clipTransitions)..where((t) => t.id.equals(transitionId)))
        .getSingleOrNull();
  }

  Future<ClipTransition?> getTransitionBetween({
    required String outgoingClipId,
    required String incomingClipId,
  }) {
    return (select(clipTransitions)
          ..where(
            (t) =>
                t.outgoingClipId.equals(outgoingClipId) &
                t.incomingClipId.equals(incomingClipId),
          ))
        .getSingleOrNull();
  }

  Future<void> insertClipTransition(ClipTransitionsCompanion transition) async {
    await into(clipTransitions).insert(transition);
  }

  Future<void> updateClipTransitionFields(
    String transitionId,
    ClipTransitionsCompanion companion,
  ) async {
    await (update(clipTransitions)..where((t) => t.id.equals(transitionId)))
        .write(
      companion.copyWith(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteClipTransition(String transitionId) {
    return (delete(clipTransitions)..where((t) => t.id.equals(transitionId)))
        .go();
  }

  Future<int> deleteTransitionsForClip(String clipId) {
    return (delete(clipTransitions)
          ..where(
            (t) =>
                t.outgoingClipId.equals(clipId) |
                t.incomingClipId.equals(clipId),
          ))
        .go();
  }

  Stream<List<LocalTextPreset>> watchLocalTextPresets() {
    return (select(localTextPresets)
          ..orderBy([
            (p) =>
                OrderingTerm(expression: p.isFavorite, mode: OrderingMode.desc),
            (p) => OrderingTerm(expression: p.category),
            (p) => OrderingTerm(expression: p.name),
          ]))
        .watch();
  }

  Future<List<LocalTextPreset>> getLocalTextPresets() {
    return (select(localTextPresets)
          ..orderBy([
            (p) =>
                OrderingTerm(expression: p.isFavorite, mode: OrderingMode.desc),
            (p) => OrderingTerm(expression: p.category),
            (p) => OrderingTerm(expression: p.name),
          ]))
        .get();
  }

  Future<LocalTextPreset?> getLocalTextPreset(String presetId) {
    return (select(localTextPresets)..where((p) => p.id.equals(presetId)))
        .getSingleOrNull();
  }

  Future<void> insertLocalTextPreset(LocalTextPresetsCompanion preset) async {
    await into(localTextPresets).insert(preset);
  }

  Future<void> updateLocalTextPresetFields(
    String presetId,
    LocalTextPresetsCompanion companion,
  ) async {
    await (update(localTextPresets)..where((p) => p.id.equals(presetId))).write(
      companion.copyWith(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteLocalTextPreset(String presetId) {
    return (delete(localTextPresets)..where((p) => p.id.equals(presetId))).go();
  }

  Future<void> insertAppErrorLog(AppErrorLogsCompanion log) async {
    await into(appErrorLogs).insert(log);
  }

  Stream<List<AppErrorLog>> watchRecentErrorLogs({
    int limit = 100,
  }) {
    return (select(appErrorLogs)
          ..orderBy([
            (e) => OrderingTerm(
                  expression: e.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .watch();
  }

  Stream<List<AppErrorLog>> watchUnresolvedErrorLogs({
    String? projectId,
  }) {
    final query = select(appErrorLogs)
      ..where((e) => e.isResolved.equals(false))
      ..orderBy([
        (e) => OrderingTerm(
              expression: e.createdAt,
              mode: OrderingMode.desc,
            ),
      ]);

    if (projectId != null) {
      query.where((e) => e.projectId.equals(projectId));
    }

    return query.watch();
  }

  Future<List<AppErrorLog>> getRecentErrorLogs({
    int limit = 100,
  }) {
    return (select(appErrorLogs)
          ..orderBy([
            (e) => OrderingTerm(
                  expression: e.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .get();
  }

  Future<void> markAppErrorResolved(String errorId) async {
    await (update(appErrorLogs)..where((e) => e.id.equals(errorId))).write(
      AppErrorLogsCompanion(
        isResolved: const Value(true),
        resolvedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> clearResolvedAppErrors() {
    return (delete(appErrorLogs)..where((e) => e.isResolved.equals(true))).go();
  }

  Future<int> clearAllAppErrorLogs() {
    return delete(appErrorLogs).go();
  }

  // ---------- Lifecycle Checkpoints ----------

  Future<void> insertLifecycleCheckpoint(
    AppLifecycleCheckpointsCompanion entry,
  ) async {
    await into(appLifecycleCheckpoints).insert(entry);
  }

  /// Returns the most recent 'open' checkpoint for [projectId] that has no
  /// matching 'close' checkpoint — i.e. a potentially un-closed session.
  Future<AppLifecycleCheckpoint?> findUnclosedSession(
    String projectId,
  ) async {
    final opens = await (select(appLifecycleCheckpoints)
          ..where(
            (c) => c.projectId.equals(projectId) & c.event.equals('open'),
          )
          ..orderBy([
            (c) => OrderingTerm(
                  expression: c.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .get();

    if (opens.isEmpty) return null;
    final lastOpen = opens.first;

    // Look for a 'close' that came AFTER this open.
    final closes = await (select(appLifecycleCheckpoints)
          ..where(
            (c) =>
                c.projectId.equals(projectId) &
                c.event.equals('close') &
                c.createdAt.isBiggerThanValue(lastOpen.createdAt),
          )
          ..limit(1))
        .get();

    return closes.isEmpty ? lastOpen : null;
  }

  Future<List<AppLifecycleCheckpoint>> getRecentCheckpoints({
    String? projectId,
    int limit = 50,
  }) {
    final query = select(appLifecycleCheckpoints)
      ..orderBy([
        (c) => OrderingTerm(
              expression: c.createdAt,
              mode: OrderingMode.desc,
            ),
      ])
      ..limit(limit);

    if (projectId != null) {
      query.where((c) => c.projectId.equals(projectId));
    }

    return query.get();
  }

  Future<int> clearOldCheckpoints({int keepDays = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    return (delete(appLifecycleCheckpoints)
          ..where((c) => c.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  Future<List<Track>> getProjectTracksOnce(String projectId) {
    final query = select(tracks)
      ..where((tbl) => tbl.projectId.equals(projectId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.type),
        (tbl) => OrderingTerm.asc(tbl.index),
      ]);
    return query.get();
  }

  Future<List<Clip>> getProjectClipsOnce(String projectId) {
    final query = select(clips)
      ..where((tbl) => tbl.projectId.equals(projectId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.trackId),
        (tbl) => OrderingTerm.asc(tbl.timelineStartMicros),
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
      ]);
    return query.get();
  }

  Future<int> getProjectDurationMicrosFromClips(String projectId) async {
    final projectClips = await getProjectClipsOnce(projectId);
    if (projectClips.isEmpty) {
      return 60 * 1000000;
    }
    var maxEnd = 0;
    for (final clip in projectClips) {
      if (clip.timelineEndMicros > maxEnd) {
        maxEnd = clip.timelineEndMicros;
      }
    }
    return maxEnd <= 0 ? 60 * 1000000 : maxEnd;
  }

  Future<void> ensureDefaultMultitrackTracks(String projectId) async {
    final existing = await getProjectTracksOnce(projectId);
    if (existing.isNotEmpty) {
      return;
    }
    await batch((batch) {
      batch.insertAll(tracks, [
        TracksCompanion.insert(
          id: 'track_v1_${const Uuid().v4()}',
          projectId: projectId,
          name: 'V1 Main',
          type: 'video',
          index: const Value(1),
          trackRole: const Value('main'),
          colorHex: const Value('#235BFF'),
          height: const Value(64),
          isMuted: const Value(false),
          isSolo: const Value(false),
          isLocked: const Value(false),
          isVisible: const Value(true),
          isHidden: const Value(false),
        ),
        TracksCompanion.insert(
          id: 'track_v2_${const Uuid().v4()}',
          projectId: projectId,
          name: 'V2 B-roll',
          type: 'video',
          index: const Value(2),
          trackRole: const Value('broll'),
          colorHex: const Value('#00B8FF'),
          height: const Value(64),
          isMuted: const Value(false),
          isSolo: const Value(false),
          isLocked: const Value(false),
          isVisible: const Value(true),
          isHidden: const Value(false),
        ),
        TracksCompanion.insert(
          id: 'track_v3_${const Uuid().v4()}',
          projectId: projectId,
          name: 'V3 Overlay',
          type: 'overlay',
          index: const Value(3),
          trackRole: const Value('overlay'),
          colorHex: const Value('#7C4DFF'),
          height: const Value(58),
          isMuted: const Value(false),
          isSolo: const Value(false),
          isLocked: const Value(false),
          isVisible: const Value(true),
          isHidden: const Value(false),
        ),
        TracksCompanion.insert(
          id: 'track_v4_${const Uuid().v4()}',
          projectId: projectId,
          name: 'V4 Text',
          type: 'text',
          index: const Value(4),
          trackRole: const Value('text'),
          colorHex: const Value('#FF8A00'),
          height: const Value(52),
          isMuted: const Value(false),
          isSolo: const Value(false),
          isLocked: const Value(false),
          isVisible: const Value(true),
          isHidden: const Value(false),
        ),
        TracksCompanion.insert(
          id: 'track_v5_${const Uuid().v4()}',
          projectId: projectId,
          name: 'V5 Adjustment',
          type: 'adjustment',
          index: const Value(5),
          trackRole: const Value('adjustment'),
          colorHex: const Value('#B000FF'),
          height: const Value(44),
          isMuted: const Value(false),
          isSolo: const Value(false),
          isLocked: const Value(false),
          isVisible: const Value(true),
          isHidden: const Value(false),
        ),
        TracksCompanion.insert(
          id: 'track_a1_${const Uuid().v4()}',
          projectId: projectId,
          name: 'A1 Voice',
          type: 'audio',
          index: const Value(1),
          trackRole: const Value('voice'),
          colorHex: const Value('#1DB954'),
          height: const Value(54),
          isMuted: const Value(false),
          isSolo: const Value(false),
          isLocked: const Value(false),
          isVisible: const Value(true),
          isHidden: const Value(false),
        ),
        TracksCompanion.insert(
          id: 'track_a2_${const Uuid().v4()}',
          projectId: projectId,
          name: 'A2 Music',
          type: 'audio',
          index: const Value(2),
          trackRole: const Value('music'),
          colorHex: const Value('#00C853'),
          height: const Value(54),
          isMuted: const Value(false),
          isSolo: const Value(false),
          isLocked: const Value(false),
          isVisible: const Value(true),
          isHidden: const Value(false),
        ),
        TracksCompanion.insert(
          id: 'track_a3_${const Uuid().v4()}',
          projectId: projectId,
          name: 'A3 SFX',
          type: 'audio',
          index: const Value(3),
          trackRole: const Value('sfx'),
          colorHex: const Value('#64DD17'),
          height: const Value(54),
          isMuted: const Value(false),
          isSolo: const Value(false),
          isLocked: const Value(false),
          isVisible: const Value(true),
          isHidden: const Value(false),
        ),
      ]);
    });
  }

  Future<void> updateClipTiming({
    required String clipId,
    String? trackId,
    required int timelineStartMicros,
    required int timelineEndMicros,
    int? sourceStartMicros,
    int? sourceEndMicros,
  }) async {
    if (timelineEndMicros <= timelineStartMicros) {
      throw ArgumentError('Clip end must be greater than clip start.');
    }

    await updateClipFields(
      clipId,
      ClipsCompanion(
        trackId: trackId == null ? const Value.absent() : Value(trackId),
        timelineStartMicros: Value(timelineStartMicros),
        timelineEndMicros: Value(timelineEndMicros),
        sourceInMicros: sourceStartMicros == null
            ? const Value.absent()
            : Value(sourceStartMicros),
        sourceOutMicros: sourceEndMicros == null
            ? const Value.absent()
            : Value(sourceEndMicros),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteClipById(String clipId) async {
    await deleteClip(clipId);
  }

  Future<String> duplicateClip({
    required String clipId,
    int offsetMicros = 500000,
  }) async {
    final originalOpt = await getClip(clipId);
    if (originalOpt == null) {
      throw StateError('Clip not found: $clipId');
    }
    final original = originalOpt;
    final now = DateTime.now();
    final newId = const Uuid().v4();

    final duration = original.timelineEndMicros - original.timelineStartMicros;
    final newStart = original.timelineEndMicros + offsetMicros;
    final newEnd = newStart + duration;

    await into(clips).insert(
      ClipsCompanion.insert(
        id: newId,
        projectId: original.projectId,
        trackId: original.trackId,
        assetId: Value(original.assetId),
        clipType: Value(original.clipType),
        timelineStartMicros: Value(newStart),
        timelineEndMicros: Value(newEnd),
        sourceInMicros: Value(original.sourceInMicros),
        sourceOutMicros: Value(original.sourceOutMicros),
        speed: Value(original.speed),
        opacity: Value(original.opacity),
        positionX: Value(original.positionX),
        positionY: Value(original.positionY),
        scale: Value(original.scale),
        rotation: Value(original.rotation),
        textContent: Value(original.textContent),
        isDisabled: Value(original.isDisabled),
        createdAt: Value(now),
        modifiedAt: Value(now),
      ),
    );

    return newId;
  }

  Future<String> splitClipAt({
    required String clipId,
    required int splitMicros,
  }) async {
    final originalOpt = await getClip(clipId);
    if (originalOpt == null) {
      throw StateError('Clip not found: $clipId');
    }
    final original = originalOpt;

    if (splitMicros <= original.timelineStartMicros ||
        splitMicros >= original.timelineEndMicros) {
      throw ArgumentError('Split point must be inside the clip.');
    }

    final now = DateTime.now();
    final rightClipId = const Uuid().v4();

    final leftTimelineStart = original.timelineStartMicros;
    final leftTimelineEnd = splitMicros;

    final rightTimelineStart = splitMicros;
    final rightTimelineEnd = original.timelineEndMicros;

    final localSplitMicros = splitMicros - original.timelineStartMicros;
    final sourceSplitMicros =
        original.sourceInMicros + (localSplitMicros * original.speed).round();

    await transaction(() async {
      await updateClipFields(
        clipId,
        ClipsCompanion(
          timelineStartMicros: Value(leftTimelineStart),
          timelineEndMicros: Value(leftTimelineEnd),
          sourceInMicros: Value(original.sourceInMicros),
          sourceOutMicros: Value(sourceSplitMicros),
          modifiedAt: Value(now),
        ),
      );

      await into(clips).insert(
        ClipsCompanion.insert(
          id: rightClipId,
          projectId: original.projectId,
          trackId: original.trackId,
          assetId: Value(original.assetId),
          clipType: Value(original.clipType),
          timelineStartMicros: Value(rightTimelineStart),
          timelineEndMicros: Value(rightTimelineEnd),
          sourceInMicros: Value(sourceSplitMicros),
          sourceOutMicros: Value(original.sourceOutMicros),
          speed: Value(original.speed),
          opacity: Value(original.opacity),
          positionX: Value(original.positionX),
          positionY: Value(original.positionY),
          scale: Value(original.scale),
          rotation: Value(original.rotation),
          textContent: Value(original.textContent),
          isDisabled: Value(original.isDisabled),
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );
    });

    return rightClipId;
  }

  Future<int?> getAssetDurationMicros(String? assetId) async {
    if (assetId == null || assetId.trim().isEmpty) {
      return null;
    }

    final query = select(assets)..where((tbl) => tbl.id.equals(assetId));
    final asset = await query.getSingleOrNull();

    return asset?.durationMicros;
  }

  Future<Map<String, dynamic>> clipSnapshot(String clipId) async {
    final row = await getClip(clipId);
    if (row == null) return const {};

    return {
      'id': row.id,
      'projectId': row.projectId,
      'trackId': row.trackId,
      'assetId': row.assetId,
      'clipType': row.clipType,
      'timelineStartMicros': row.timelineStartMicros,
      'timelineEndMicros': row.timelineEndMicros,
      'sourceInMicros': row.sourceInMicros,
      'sourceOutMicros': row.sourceOutMicros,
      'positionX': row.positionX,
      'positionY': row.positionY,
      'anchorX': row.anchorX,
      'anchorY': row.anchorY,
      'scale': row.scale,
      'rotation': row.rotation,
      'opacity': row.opacity,
      'cropLeft': row.cropLeft,
      'cropTop': row.cropTop,
      'cropRight': row.cropRight,
      'cropBottom': row.cropBottom,
      'blendMode': row.blendMode,
      'exposure': row.exposure,
      'contrast': row.contrast,
      'saturation': row.saturation,
      'temperature': row.temperature,
      'tint': row.tint,
      'highlights': row.highlights,
      'shadows': row.shadows,
      'lutPath': row.lutPath,
      'volume': row.volume,
      'audioPan': row.audioPan,
      'isAudioMuted': row.isAudioMuted,
      'fadeInMicros': row.fadeInMicros,
      'fadeOutMicros': row.fadeOutMicros,
      'textContent': row.textContent,
      'textStyle': row.textStyle,
      'speed': row.speed,
      'isReversed': row.isReversed,
      'isLinked': row.isLinked,
      'linkedClipId': row.linkedClipId,
      'isDisabled': row.isDisabled,
      'effectStack': row.effectStack,
      'sortOrder': row.sortOrder,
      'fitMode': row.fitMode,
      'brightness': row.brightness,
      'textStyleJson': row.textStyleJson,
      'colorHex': row.colorHex,
      'overlayDataJson': row.overlayDataJson,
      'isOverlayClip': row.isOverlayClip,
      'templateGroupId': row.templateGroupId,
      'sourceTemplateId': row.sourceTemplateId,
      'keyframeTrackJson': row.keyframeTrackJson,
      'createdAt': row.createdAt.toIso8601String(),
      'modifiedAt': row.modifiedAt.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> trackSnapshot(String trackId) async {
    final row = await getTrack(trackId);
    return {
      'id': row.id,
      'projectId': row.projectId,
      'name': row.name,
      'type': row.type,
      'index': row.index,
      'isMuted': row.isMuted,
      'isSolo': row.isSolo,
      'isLocked': row.isLocked,
      'isVisible': row.isVisible,
      'isCollapsed': row.isCollapsed,
      'volume': row.volume,
      'opacity': row.opacity,
      'height': row.height,
      'color': row.color,
      'isHidden': row.isHidden,
      'colorHex': row.colorHex,
      'trackRole': row.trackRole,
    };
  }

  Future<void> restoreClipFromSnapshot(Map<String, dynamic> json) async {
    final clipId = json['id']?.toString();
    if (clipId == null || clipId.isEmpty) return;

    final existing = await (select(clips)
          ..where((tbl) => tbl.id.equals(clipId)))
        .getSingleOrNull();

    final companion = ClipsCompanion(
      id: Value(clipId),
      projectId: Value(json['projectId']?.toString() ?? ''),
      trackId: Value(json['trackId']?.toString() ?? ''),
      assetId: Value(json['assetId']?.toString()),
      clipType: Value(json['clipType']?.toString() ?? 'media'),
      timelineStartMicros:
          Value((json['timelineStartMicros'] as num?)?.toInt() ?? 0),
      timelineEndMicros:
          Value((json['timelineEndMicros'] as num?)?.toInt() ?? 0),
      sourceInMicros: Value((json['sourceInMicros'] as num?)?.toInt() ?? 0),
      sourceOutMicros: Value((json['sourceOutMicros'] as num?)?.toInt() ?? 0),
      positionX: Value((json['positionX'] as num?)?.toDouble() ?? 0.0),
      positionY: Value((json['positionY'] as num?)?.toDouble() ?? 0.0),
      anchorX: Value((json['anchorX'] as num?)?.toDouble() ?? 0.5),
      anchorY: Value((json['anchorY'] as num?)?.toDouble() ?? 0.5),
      scale: Value((json['scale'] as num?)?.toDouble() ?? 1.0),
      rotation: Value((json['rotation'] as num?)?.toDouble() ?? 0.0),
      opacity: Value((json['opacity'] as num?)?.toDouble() ?? 1.0),
      cropLeft: Value((json['cropLeft'] as num?)?.toDouble() ?? 0.0),
      cropTop: Value((json['cropTop'] as num?)?.toDouble() ?? 0.0),
      cropRight: Value((json['cropRight'] as num?)?.toDouble() ?? 0.0),
      cropBottom: Value((json['cropBottom'] as num?)?.toDouble() ?? 0.0),
      blendMode: Value(json['blendMode']?.toString() ?? 'normal'),
      exposure: Value((json['exposure'] as num?)?.toDouble() ?? 0.0),
      contrast: Value((json['contrast'] as num?)?.toDouble() ?? 1.0),
      saturation: Value((json['saturation'] as num?)?.toDouble() ?? 1.0),
      temperature: Value((json['temperature'] as num?)?.toDouble() ?? 0.0),
      tint: Value((json['tint'] as num?)?.toDouble() ?? 0.0),
      highlights: Value((json['highlights'] as num?)?.toDouble() ?? 0.0),
      shadows: Value((json['shadows'] as num?)?.toDouble() ?? 0.0),
      lutPath: Value(json['lutPath']?.toString()),
      volume: Value((json['volume'] as num?)?.toDouble() ?? 1.0),
      audioPan: Value((json['audioPan'] as num?)?.toDouble() ?? 0.0),
      isAudioMuted: Value(json['isAudioMuted'] == true),
      fadeInMicros: Value((json['fadeInMicros'] as num?)?.toInt() ?? 5000),
      fadeOutMicros: Value((json['fadeOutMicros'] as num?)?.toInt() ?? 5000),
      textContent: Value(json['textContent']?.toString()),
      textStyle: Value(json['textStyle']?.toString()),
      speed: Value((json['speed'] as num?)?.toDouble() ?? 1.0),
      isReversed: Value(json['isReversed'] == true),
      isLinked: Value(json['isLinked'] == true),
      linkedClipId: Value(json['linkedClipId']?.toString()),
      isDisabled: Value(json['isDisabled'] == true),
      effectStack: Value(json['effectStack']?.toString()),
      sortOrder: Value((json['sortOrder'] as num?)?.toInt() ?? 0),
      fitMode: Value(json['fitMode']?.toString() ?? 'fit'),
      brightness: Value((json['brightness'] as num?)?.toDouble() ?? 0.0),
      textStyleJson: Value(json['textStyleJson']?.toString()),
      colorHex: Value(json['colorHex']?.toString()),
      overlayDataJson: Value(json['overlayDataJson']?.toString()),
      isOverlayClip: Value(json['isOverlayClip'] == true),
      templateGroupId: Value(json['templateGroupId']?.toString()),
      sourceTemplateId: Value(json['sourceTemplateId']?.toString()),
      keyframeTrackJson: Value(json['keyframeTrackJson']?.toString()),
      modifiedAt: Value(DateTime.now()),
    );

    if (existing == null) {
      await into(clips).insert(companion);
    } else {
      await (update(clips)..where((tbl) => tbl.id.equals(clipId)))
          .write(companion);
    }
  }

  Future<void> restoreTrackFromSnapshot(Map<String, dynamic> json) async {
    final trackId = json['id']?.toString();
    if (trackId == null || trackId.isEmpty) return;

    await (update(tracks)..where((tbl) => tbl.id.equals(trackId))).write(
      TracksCompanion(
        name: Value(json['name']?.toString() ?? 'Track'),
        isMuted: Value(json['isMuted'] == true),
        isSolo: Value(json['isSolo'] == true),
        isLocked: Value(json['isLocked'] == true),
        isVisible: Value(json['isVisible'] == true),
        isCollapsed: Value(json['isCollapsed'] == true),
        volume: Value((json['volume'] as num?)?.toDouble() ?? 1.0),
        opacity: Value((json['opacity'] as num?)?.toDouble() ?? 1.0),
        height: Value((json['height'] as num?)?.toInt() ?? 64),
        color: Value(json['color']?.toString()),
        isHidden: Value(json['isHidden'] == true),
        colorHex: Value(json['colorHex']?.toString()),
        trackRole: Value(json['trackRole']?.toString()),
      ),
    );
  }

  Future<void> deleteClipSnapshot(String clipId) async {
    await (delete(clips)..where((tbl) => tbl.id.equals(clipId))).go();
  }

  Future<void> markProjectDirty(String projectId) async {
    await (update(projects)..where((tbl) => tbl.id.equals(projectId))).write(
      ProjectsCompanion(
        isDirty: const Value(true),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markProjectSaved(String projectId) async {
    await (update(projects)..where((tbl) => tbl.id.equals(projectId))).write(
      ProjectsCompanion(
        isDirty: const Value(false),
        lastSavedAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> insertLutAsset({
    required String id,
    required String name,
    required String filePath,
    required String sourceType,
    required int size,
    required bool isValid,
    String? previewThumbnailPath,
  }) async {
    await into(lutAssets).insert(
      LutAssetsCompanion.insert(
        id: id,
        name: name,
        filePath: filePath,
        sourceType: Value(sourceType),
        size: Value(size),
        isValid: Value(isValid),
        previewThumbnailPath: Value(previewThumbnailPath),
        importedAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<List<LutAsset>> getAllLutAssets() {
    final query = select(lutAssets)
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.importedAt),
      ]);

    return query.get();
  }

  Stream<List<LutAsset>> watchAllLutAssets() {
    final query = select(lutAssets)
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.importedAt),
      ]);

    return query.watch();
  }

  Future<LutAsset> getLutAssetById(String lutAssetId) {
    return (select(lutAssets)..where((tbl) => tbl.id.equals(lutAssetId)))
        .getSingle();
  }

  Future<void> updateClipLutStackJson({
    required String clipId,
    required String lutStackJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        lutStackJson: Value(lutStackJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipColorCurveStackJson({
    required String clipId,
    required String colorCurveStackJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        colorCurveStackJson: Value(colorCurveStackJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateClipSecondaryGradeStackJson({
    required String clipId,
    required String secondaryGradeStackJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        secondaryGradeStackJson: Value(secondaryGradeStackJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- 32B-PRO: Subtitles & Captions ----------

  Future<List<SubtitleTrack>> getSubtitleTracksForProject(String projectId) {
    return (select(subtitleTracks)
          ..where((tbl) => tbl.projectId.equals(projectId)))
        .get();
  }

  Future<SubtitleTrack> getSubtitleTrackById(String trackId) {
    return (select(subtitleTracks)..where((tbl) => tbl.id.equals(trackId)))
        .getSingle();
  }

  Future<List<CaptionSegment>> getCaptionSegmentsForTrack(String trackId) {
    return (select(captionSegments)
          ..where((tbl) => tbl.trackId.equals(trackId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.startMicros)]))
        .get();
  }

  Future<void> upsertSubtitleTrack(SubtitleTracksCompanion row) {
    return into(subtitleTracks).insertOnConflictUpdate(row);
  }

  Future<void> upsertCaptionSegment(CaptionSegmentsCompanion row) {
    return into(captionSegments).insertOnConflictUpdate(row);
  }

  Future<void> deleteCaptionSegmentById(String segmentId) {
    return (delete(captionSegments)..where((tbl) => tbl.id.equals(segmentId)))
        .go();
  }

  Future<void> deleteSubtitleTrackById(String trackId) async {
    await (delete(captionSegments)..where((tbl) => tbl.trackId.equals(trackId)))
        .go();
    await (delete(subtitleTracks)..where((tbl) => tbl.id.equals(trackId))).go();
  }

  // ---------- 32D-PRO: Motion Templates ----------

  Future<List<MotionTemplatePack>> getMotionTemplatePacks() {
    return select(motionTemplatePacks).get();
  }

  Future<void> upsertMotionTemplatePack(MotionTemplatePacksCompanion row) {
    return into(motionTemplatePacks).insertOnConflictUpdate(row);
  }

  Future<MotionTemplateUsageData?> getTemplateUsage(String templateId) {
    return (select(motionTemplateUsage)
          ..where((tbl) => tbl.templateId.equals(templateId)))
        .getSingleOrNull();
  }

  Future<void> upsertTemplateUsage(MotionTemplateUsageCompanion row) {
    return into(motionTemplateUsage).insertOnConflictUpdate(row);
  }

  Future<void> markTemplateUsed(String templateId) async {
    final current = await getTemplateUsage(templateId);

    await upsertTemplateUsage(
      MotionTemplateUsageCompanion(
        templateId: Value(templateId),
        favorite: Value(current?.favorite ?? false),
        useCount: Value((current?.useCount ?? 0) + 1),
        lastUsedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setTemplateFavorite({
    required String templateId,
    required bool favorite,
  }) async {
    final current = await getTemplateUsage(templateId);

    await upsertTemplateUsage(
      MotionTemplateUsageCompanion(
        templateId: Value(templateId),
        favorite: Value(favorite),
        useCount: Value(current?.useCount ?? 0),
        lastUsedAt: Value(current?.lastUsedAt),
      ),
    );
  }

  // ---------- 32E-PRO: Keyframes ----------

  Future<void> updateClipKeyframeTrackJson({
    required String clipId,
    required String keyframeTrackJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        keyframeTrackJson: Value(keyframeTrackJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> getClipKeyframeTrackJson(String clipId) async {
    final row = await getClip(clipId);
    return row?.keyframeTrackJson;
  }

  // ---------- 33A-PRO: Audio Engine — Waveform Cache ----------

  Future<AudioWaveformCache?> getWaveformCache(String assetId) {
    return (select(audioWaveformCaches)
          ..where((tbl) => tbl.assetId.equals(assetId)))
        .getSingleOrNull();
  }

  Future<void> upsertWaveformCache(AudioWaveformCachesCompanion row) {
    return into(audioWaveformCaches).insertOnConflictUpdate(row);
  }

  Future<void> deleteWaveformCache(String assetId) {
    return (delete(audioWaveformCaches)
          ..where((tbl) => tbl.assetId.equals(assetId)))
        .go();
  }

  Stream<AudioWaveformCache?> watchWaveformCache(String assetId) {
    return (select(audioWaveformCaches)
          ..where((tbl) => tbl.assetId.equals(assetId)))
        .watchSingleOrNull();
  }

  // ---------- 33A-PRO: Audio Engine — Clip Volume / Fades ----------

  Future<void> updateClipAudioSettings({
    required String clipId,
    double? volume,
    double? audioPan,
    bool? isAudioMuted,
    int? fadeInMicros,
    int? fadeOutMicros,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        volume:       volume       == null ? const Value.absent() : Value(volume),
        audioPan:     audioPan     == null ? const Value.absent() : Value(audioPan),
        isAudioMuted: isAudioMuted == null ? const Value.absent() : Value(isAudioMuted),
        fadeInMicros: fadeInMicros == null ? const Value.absent() : Value(fadeInMicros),
        fadeOutMicros: fadeOutMicros == null
            ? const Value.absent()
            : Value(fadeOutMicros),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- 33A-PRO: Audio Track Volume / Pan ----------

  Future<void> setTrackVolume({
    required String trackId,
    required double volume,
  }) async {
    await updateTrackFields(
      trackId,
      TracksCompanion(volume: Value(volume.clamp(0.0, 2.0))),
    );
  }

  // ---------- 33B-PRO: Audio Automation JSON ----------

  Future<String?> getClipAudioAutomationJson(String clipId) async {
    final row = await (select(clips)
          ..where((tbl) => tbl.id.equals(clipId)))
        .getSingleOrNull();
    return row?.audioAutomationJson;
  }

  Future<void> updateClipAudioAutomationJson({
    required String clipId,
    required String automationJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        audioAutomationJson: Value(automationJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> getTrackAudioAutomationJson(String trackId) async {
    final row = await (select(tracks)
          ..where((tbl) => tbl.id.equals(trackId)))
        .getSingleOrNull();
    return row?.audioAutomationJson;
  }

  Future<void> updateTrackAudioAutomationJson({
    required String trackId,
    required String automationJson,
  }) async {
    await updateTrackFields(
      trackId,
      TracksCompanion(audioAutomationJson: Value(automationJson)),
    );
  }

  // ---------- 33C-PRO: Audio Effects Rack JSON ----------

  Future<String?> getClipEffectChainJson(String clipId) async {
    final row = await (select(clips)..where((tbl) => tbl.id.equals(clipId)))
        .getSingleOrNull();
    return row?.effectChainJson;
  }

  Future<void> updateClipEffectChainJson({
    required String clipId,
    required String effectChainJson,
  }) async {
    await (update(clips)..where((tbl) => tbl.id.equals(clipId))).write(
      ClipsCompanion(
        effectChainJson: Value(effectChainJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> getTrackEffectChainJson(String trackId) async {
    final row = await (select(tracks)..where((tbl) => tbl.id.equals(trackId)))
        .getSingleOrNull();
    return row?.effectChainJson;
  }

  Future<void> updateTrackEffectChainJson({
    required String trackId,
    required String effectChainJson,
  }) async {
    await updateTrackFields(
      trackId,
      TracksCompanion(effectChainJson: Value(effectChainJson)),
    );
  }

  Future<void> updateProjectMasterEffectChainJson({
    required String projectId,
    required String masterEffectChainJson,
  }) async {
    await (update(projects)..where((tbl) => tbl.id.equals(projectId))).write(
      ProjectsCompanion(
        masterEffectChainJson: Value(masterEffectChainJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<VoiceTake>> getVoiceTakesForProject(String projectId) {
    return (select(voiceTakes)
          ..where((tbl) => tbl.projectId.equals(projectId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.recordedAt)]))
        .get();
  }

  Future<List<VoiceTake>> getVoiceTakesForSession(String sessionId) {
    return (select(voiceTakes)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.recordedAt)]))
        .get();
  }

  Future<void> upsertVoiceTake(VoiceTakesCompanion row) {
    return into(voiceTakes).insertOnConflictUpdate(row);
  }

  Future<void> deleteVoiceTakeById(String id) {
    return (delete(voiceTakes)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateVoiceTakeAudioClipId({
    required String takeId,
    required String audioClipId,
  }) async {
    await (update(voiceTakes)..where((tbl) => tbl.id.equals(takeId))).write(
      VoiceTakesCompanion(
        audioClipId: Value(audioClipId),
        status: const Value('inserted'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- 34A-PRO: Media Assets & Bins ----------

  Future<List<MediaAsset>> getMediaAssetsForProject(String projectId) {
    return (select(mediaAssets)
          ..where((tbl) => tbl.projectId.equals(projectId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.importedAt)]))
        .get();
  }

  Future<MediaAsset?> getMediaAssetById(String assetId) {
    return (select(mediaAssets)..where((tbl) => tbl.id.equals(assetId)))
        .getSingleOrNull();
  }

  Future<List<MediaAsset>> getMediaAssetsByIds(List<String> assetIds) {
    if (assetIds.isEmpty) {
      return Future.value(const []);
    }
    final query = select(mediaAssets)..where((tbl) => tbl.id.isIn(assetIds));
    return query.get();
  }

  Future<void> upsertMediaAsset(MediaAssetsCompanion row) {
    return into(mediaAssets).insertOnConflictUpdate(row);
  }

  Future<void> deleteMediaAssetById(String assetId) {
    return (delete(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).go();
  }

  Future<List<MediaBin>> getMediaBinsForProject(String projectId) {
    return (select(mediaBins)
          ..where((tbl) => tbl.projectId.equals(projectId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortIndex)]))
        .get();
  }

  Future<void> upsertMediaBin(MediaBinsCompanion row) {
    return into(mediaBins).insertOnConflictUpdate(row);
  }

  Future<void> linkAssetToBin({
    required String assetId,
    required String binId,
  }) {
    return into(assetBinLinks).insertOnConflictUpdate(
      AssetBinLinksCompanion(
        assetId: Value(assetId),
        binId: Value(binId),
        linkedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<AssetBinLink>> getAssetBinLinksForBin(String binId) {
    return (select(assetBinLinks)..where((tbl) => tbl.binId.equals(binId))).get();
  }

  Future<void> updateMediaAssetAvailability({
    required String assetId,
    required String availability,
  }) async {
    await (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(
        availability: Value(availability),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateMediaAssetUsageState({
    required String assetId,
    required String usageState,
  }) async {
    await (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(
        usageState: Value(usageState),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- 34B-PRO: Proxy Media helpers ----------

  Future<String?> getProjectProxySettingsJson(String projectId) async {
    final query = select(projects)..where((tbl) => tbl.id.equals(projectId));
    final row = await query.getSingleOrNull();
    return row?.proxySettingsJson;
  }

  Future<void> updateProjectProxySettingsJson({
    required String projectId,
    required String proxySettingsJson,
  }) async {
    await (update(projects)..where((tbl) => tbl.id.equals(projectId))).write(
      ProjectsCompanion(
        proxySettingsJson: Value(proxySettingsJson),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<ProxyJob>> getProxyJobsForProject(String projectId) {
    final query = select(proxyJobs)
      ..where((tbl) => tbl.projectId.equals(projectId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return query.get();
  }

  Future<List<ProxyJob>> getRunnableProxyJobs(String projectId) {
    final query = select(proxyJobs)
      ..where((tbl) => tbl.projectId.equals(projectId))
      ..where((tbl) => tbl.status.isIn(['queued', 'generating']))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.get();
  }

  Future<void> upsertProxyJob(ProxyJobsCompanion companion) {
    return into(proxyJobs).insertOnConflictUpdate(companion);
  }

  Future<void> updateMediaAssetProxyReady({
    required String assetId,
    required String proxyPath,
    required String proxyMetadataJson,
  }) async {
    await (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(
        proxyPath: Value(proxyPath),
        proxyStatus: Value('ready'),
        proxyMetadataJson: Value(proxyMetadataJson),
        proxyError: const Value(null),
        proxyCreatedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateMediaAssetProxyStatus({
    required String assetId,
    required String proxyStatus,
    String? proxyError,
  }) async {
    await (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(
        proxyStatus: Value(proxyStatus),
        proxyError: Value(proxyError),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearMediaAssetProxy({required String assetId}) async {
    await (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(
        proxyPath: const Value(null),
        proxyStatus: Value('none'),
        proxyMetadataJson: const Value(null),
        proxyError: const Value(null),
        proxyCreatedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (delete(proxyJobs)..where((tbl) => tbl.assetId.equals(assetId))).go();
  }
}
