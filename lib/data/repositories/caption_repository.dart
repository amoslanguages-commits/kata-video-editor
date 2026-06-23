import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/captions/caption_segment_models.dart';
import 'package:nle_editor/domain/captions/caption_value_models.dart';
import 'package:nle_editor/domain/captions/srt_codec.dart';
import 'package:nle_editor/domain/captions/subtitle_track_models.dart';
import 'package:nle_editor/domain/captions/webvtt_codec.dart';
import 'package:nle_editor/domain/titles/title_style_models.dart';

class CaptionRepository {
  final db.AppDatabase database;
  final NleSrtCodec srtCodec;
  final NleWebVttCodec webVttCodec;

  const CaptionRepository({
    required this.database,
    this.srtCodec = const NleSrtCodec(),
    this.webVttCodec = const NleWebVttCodec(),
  });

  Future<List<NleSubtitleTrack>> getTracks(String projectId) async {
    final trackRows = await database.getSubtitleTracksForProject(projectId);
    final out = <NleSubtitleTrack>[];

    for (final row in trackRows) {
      final segmentRows = await database.getCaptionSegmentsForTrack(row.id);

      out.add(
        _trackFromRow(
          row,
          segmentRows.map(_segmentFromRow).toList(),
        ),
      );
    }

    return out;
  }

  Future<NleSubtitleTrack> getTrack(String trackId) async {
    final row = await database.getSubtitleTrackById(trackId);
    final segmentRows = await database.getCaptionSegmentsForTrack(trackId);

    return _trackFromRow(
      row,
      segmentRows.map(_segmentFromRow).toList(),
    );
  }

  Future<String> createTrack({
    required String projectId,
    String name = 'Subtitles',
    String langCode = 'en',
    bool burnedIn = true,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final style = NleCaptionStylePreset.defaultReadable();

    await database.upsertSubtitleTrack(
      db.SubtitleTracksCompanion(
        id: Value(id),
        projectId: Value(projectId),
        name: Value(name),
        langCode: Value(langCode),
        type: Value(NleCaptionTrackType.subtitles.name),
        enabled: const Value(true),
        burnedIn: Value(burnedIn),
        exportSidecar: const Value(true),
        exportFormat: Value(NleSubtitleExportFormat.srt.name),
        speakerMode: Value(NleCaptionSpeakerMode.hidden.name),
        stylePresetJson: Value(jsonEncode(style.toJson())),
        createdAt: Value(now),
        updatedAt: Value(now),
        version: const Value(1),
      ),
    );

    return id;
  }

  Future<void> saveTrack(NleSubtitleTrack track) async {
    await database.upsertSubtitleTrack(
      db.SubtitleTracksCompanion(
        id: Value(track.id),
        projectId: Value(track.projectId),
        name: Value(track.name),
        langCode: Value(track.langCode),
        type: Value(track.type.name),
        enabled: Value(track.enabled),
        burnedIn: Value(track.burnedIn),
        exportSidecar: Value(track.exportSidecar),
        exportFormat: Value(track.exportFormat.name),
        speakerMode: Value(track.speakerMode.name),
        stylePresetJson: Value(jsonEncode(track.stylePreset.toJson())),
        createdAt: Value(track.createdAt),
        updatedAt: Value(DateTime.now()),
        version: Value(track.version),
      ),
    );

    for (final segment in track.segments) {
      await saveSegment(
        projectId: track.projectId,
        segment: segment,
      );
    }
  }

  Future<String> createSegment({
    required String projectId,
    required String trackId,
    required int startMicros,
    required int endMicros,
    String text = 'New caption',
  }) async {
    final id = const Uuid().v4();

    await saveSegment(
      projectId: projectId,
      segment: NleCaptionSegment(
        id: id,
        trackId: trackId,
        startMicros: startMicros,
        endMicros: endMicros,
        text: text,
        confidence: 1.0,
        locked: false,
        hidden: false,
        words: const [],
        version: 1,
      ),
    );

    return id;
  }

  Future<void> saveSegment({
    required String projectId,
    required NleCaptionSegment segment,
  }) async {
    final now = DateTime.now();

    await database.upsertCaptionSegment(
      db.CaptionSegmentsCompanion(
        id: Value(segment.id),
        projectId: Value(projectId),
        trackId: Value(segment.trackId),
        startMicros: Value(segment.startMicros),
        endMicros: Value(segment.endMicros),
        textContent: Value(segment.text),
        speaker: Value(segment.speaker),
        confidence: Value(segment.confidence),
        locked: Value(segment.locked),
        hidden: Value(segment.hidden),
        styleOverrideJson: Value(
          segment.styleOverride == null
              ? null
              : jsonEncode(segment.styleOverride!.toJson()),
        ),
        wordsJson: Value(jsonEncode(segment.words.map((w) => w.toJson()).toList())),
        createdAt: Value(now),
        updatedAt: Value(now),
        version: Value(segment.version),
      ),
    );
  }

  Future<void> deleteSegment(String segmentId) {
    return database.deleteCaptionSegmentById(segmentId);
  }

  Future<void> deleteTrack(String trackId) {
    return database.deleteSubtitleTrackById(trackId);
  }

  Future<int> importSrt({
    required String projectId,
    required String trackId,
    required String source,
  }) async {
    final segments = srtCodec.parse(
      trackId: trackId,
      source: source,
    );

    for (final segment in segments) {
      await saveSegment(
        projectId: projectId,
        segment: segment,
      );
    }

    return segments.length;
  }

  Future<int> importWebVtt({
    required String projectId,
    required String trackId,
    required String source,
  }) async {
    final segments = webVttCodec.parse(
      trackId: trackId,
      source: source,
    );

    for (final segment in segments) {
      await saveSegment(
        projectId: projectId,
        segment: segment,
      );
    }

    return segments.length;
  }

  Future<String> exportSrt(String trackId) async {
    final track = await getTrack(trackId);
    return srtCodec.encode(track.orderedSegments);
  }

  Future<String> exportWebVtt(String trackId) async {
    final track = await getTrack(trackId);
    return webVttCodec.encode(track.orderedSegments);
  }

  NleSubtitleTrack _trackFromRow(
    db.SubtitleTrack row,
    List<NleCaptionSegment> segments,
  ) {
    return NleSubtitleTrack(
      id: row.id,
      projectId: row.projectId,
      name: row.name,
      langCode: row.langCode,
      type: _enumByName(
        NleCaptionTrackType.values,
        row.type,
        NleCaptionTrackType.subtitles,
      ),
      enabled: row.enabled,
      burnedIn: row.burnedIn,
      exportSidecar: row.exportSidecar,
      exportFormat: _enumByName(
        NleSubtitleExportFormat.values,
        row.exportFormat,
        NleSubtitleExportFormat.srt,
      ),
      speakerMode: _enumByName(
        NleCaptionSpeakerMode.values,
        row.speakerMode,
        NleCaptionSpeakerMode.hidden,
      ),
      stylePreset: NleCaptionStylePreset.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.stylePresetJson) as Map),
      ),
      segments: segments,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }

  NleCaptionSegment _segmentFromRow(db.CaptionSegment row) {
    return NleCaptionSegment(
      id: row.id,
      trackId: row.trackId,
      startMicros: row.startMicros,
      endMicros: row.endMicros,
      text: row.textContent,
      speaker: row.speaker,
      confidence: row.confidence,
      locked: row.locked,
      hidden: row.hidden,
      styleOverride: row.styleOverrideJson == null
          ? null
          : NleTextStyleModel.fromJson(
              Map<String, dynamic>.from(jsonDecode(row.styleOverrideJson!) as Map),
            ),
      words: (jsonDecode(row.wordsJson ?? '[]') as List)
          .whereType<Map>()
          .map(
            (item) => NleCaptionWordTiming.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      version: row.version,
    );
  }

  T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    final string = name?.toString();
    if (string == null) return fallback;

    for (final value in values) {
      if (value.name == string) return value;
    }

    return fallback;
  }
}
