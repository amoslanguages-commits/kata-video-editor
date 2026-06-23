import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/core/constants/app_constants.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/data/repositories/project_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';

class TimelineCommandService {
  final TimelineRepository _timelineRepository;
  final AssetRepository _assetRepository;
  final ProjectRepository _projectRepository;
  final MediaAssetRepository? _mediaAssetRepository;

  TimelineCommandService(
    this._timelineRepository,
    this._assetRepository,
    this._projectRepository, [
    this._mediaAssetRepository,
  ]);

  static const _uuid = Uuid();

  // ─── Add media clip ────────────────────────────────────────────────────────

  Future<String?> addAssetToTimeline({
    required String projectId,
    required String assetId,
    required int timelineStartMicros,
  }) async {
    final legacyAsset = await _assetRepository.getAsset(assetId);

    if (legacyAsset != null) {
      final trackType = switch (legacyAsset.fileType) {
        'audio' => 'audio',
        'image' => 'overlay',
        _ => 'video',
      };

      final track =
          await _timelineRepository.getFirstTrackByType(projectId, trackType);
      if (track == null) return null;

      final clipId = _uuid.v4();
      final duration = legacyAsset.durationMicros ??
          (legacyAsset.fileType == 'image'
              ? AppConstants.defaultImageDurationMicros
              : AppConstants.defaultTextDurationMicros);

      await _timelineRepository.insertClip(
        ClipsCompanion.insert(
          id: clipId,
          projectId: projectId,
          trackId: track.id,
          assetId: Value(legacyAsset.id),
          clipType: Value(legacyAsset.fileType == 'image'
              ? 'image'
              : legacyAsset.fileType),
          timelineStartMicros: Value(timelineStartMicros),
          timelineEndMicros: Value(timelineStartMicros + duration),
          sourceInMicros: const Value(0),
          sourceOutMicros: Value(duration),
          sortOrder: Value(DateTime.now().microsecondsSinceEpoch),
        ),
      );

      final created = await _timelineRepository.getClip(clipId);
      if (created != null) {
        await _recordCommand(
          projectId: projectId,
          actionType: 'add_clip',
          description: 'Add clip',
          payload: {'after': _clipToJson(created)},
        );
      }

      await _refreshProjectDuration(projectId);
      return clipId;
    }

    final mediaAsset = await _mediaAssetRepository?.getAsset(assetId);
    if (mediaAsset == null) return null;

    final trackType = mediaAsset.isAudio
        ? 'audio'
        : mediaAsset.isImage
            ? 'overlay'
            : 'video';

    final track =
        await _timelineRepository.getFirstTrackByType(projectId, trackType);
    if (track == null) return null;

    final clipId = _uuid.v4();
    final duration = mediaAsset.durationMicros > 0
        ? mediaAsset.durationMicros
        : mediaAsset.isImage
            ? AppConstants.defaultImageDurationMicros
            : AppConstants.defaultTextDurationMicros;

    final clipType = mediaAsset.isImage
        ? 'image'
        : mediaAsset.isAudio
            ? 'audio'
            : 'video';

    await _timelineRepository.insertClip(
      ClipsCompanion.insert(
        id: clipId,
        projectId: projectId,
        trackId: track.id,
        assetId: Value(mediaAsset.id),
        clipType: Value(clipType),
        timelineStartMicros: Value(timelineStartMicros),
        timelineEndMicros: Value(timelineStartMicros + duration),
        sourceInMicros: const Value(0),
        sourceOutMicros: Value(duration),
        sortOrder: Value(DateTime.now().microsecondsSinceEpoch),
      ),
    );

    await _mediaAssetRepository?.setUsageState(
      assetId: mediaAsset.id,
      usageState: mediaAsset.usageState,
    );

    final created = await _timelineRepository.getClip(clipId);
    if (created != null) {
      await _recordCommand(
        projectId: projectId,
        actionType: 'add_clip',
        description: 'Add managed media clip',
        payload: {'after': _clipToJson(created)},
      );
    }

    await _refreshProjectDuration(projectId);
    return clipId;
  }

  // ─── Add text clip ─────────────────────────────────────────────────────────

  Future<String> addTextClip({
    required String projectId,
    required int timelineStartMicros,
    String text = 'New Text',
  }) async {
    final track =
        await _timelineRepository.getFirstTrackByType(projectId, 'text');
    if (track == null) throw StateError('No text track found');

    final clipId = _uuid.v4();
    const duration = AppConstants.defaultTextDurationMicros;

    await _timelineRepository.insertClip(
      ClipsCompanion.insert(
        id: clipId,
        projectId: projectId,
        trackId: track.id,
        clipType: const Value('text'),
        timelineStartMicros: Value(timelineStartMicros),
        timelineEndMicros: Value(timelineStartMicros + duration),
        sourceInMicros: const Value(0),
        sourceOutMicros: const Value(duration),
        textContent: Value(text),
        textStyle: const Value(
          '{"fontSize":32,"color":"#FFFFFF","fontWeight":"700","align":"center"}',
        ),
        positionX: const Value(0),
        positionY: const Value(0),
        scale: const Value(1),
        sortOrder: Value(DateTime.now().microsecondsSinceEpoch),
      ),
    );

    final created = await _timelineRepository.getClip(clipId);
    if (created != null) {
      await _recordCommand(
        projectId: projectId,
        actionType: 'add_clip',
        description: 'Add text',
        payload: {'after': _clipToJson(created)},
      );
    }

    await _refreshProjectDuration(projectId);
    return clipId;
  }

  // ─── Move clip ─────────────────────────────────────────────────────────────

  Future<void> moveClip({
    required String projectId,
    required String clipId,
    required int newTimelineStartMicros,
    String? newTrackId,
  }) async {
    final before = await _timelineRepository.getClip(clipId);
    if (before == null) return;

    final duration = before.timelineEndMicros - before.timelineStartMicros;
    final start = newTimelineStartMicros.clamp(0, 1 << 62);
    final end = start + duration;
    
    final timeDelta = start - before.timelineStartMicros;

    Clip? linkedBefore;
    if (before.isLinked && before.linkedClipId != null) {
      linkedBefore = await _timelineRepository.getClip(before.linkedClipId!);
    }

    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        timelineStartMicros: Value(start),
        timelineEndMicros: Value(end),
        trackId: newTrackId == null ? const Value.absent() : Value(newTrackId),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    if (linkedBefore != null) {
      final linkedStart = (linkedBefore.timelineStartMicros + timeDelta).clamp(0, 1 << 62);
      final linkedEnd = linkedStart + (linkedBefore.timelineEndMicros - linkedBefore.timelineStartMicros);
      
      await _timelineRepository.updateClipFields(
        linkedBefore.id,
        ClipsCompanion(
          timelineStartMicros: Value(linkedStart),
          timelineEndMicros: Value(linkedEnd),
          modifiedAt: Value(DateTime.now()),
        ),
      );
    }

    final after = await _timelineRepository.getClip(clipId);
    if (after != null) {
      final payload = {
        'before': _clipToJson(before),
        'after': _clipToJson(after),
      };
      
      if (linkedBefore != null) {
        final linkedAfter = await _timelineRepository.getClip(linkedBefore.id);
        if (linkedAfter != null) {
          payload['linkedBefore'] = _clipToJson(linkedBefore);
          payload['linkedAfter'] = _clipToJson(linkedAfter);
        }
      }

      await _recordCommand(
        projectId: projectId,
        actionType: 'move_clip',
        description: 'Move clip',
        payload: payload,
      );
    }

    await _refreshProjectDuration(projectId);
  }

  // ─── Trim clip ─────────────────────────────────────────────────────────────

  Future<void> trimClip({
    required String projectId,
    required String clipId,
    required int timelineStartMicros,
    required int timelineEndMicros,
    required int sourceInMicros,
    required int sourceOutMicros,
  }) async {
    final before = await _timelineRepository.getClip(clipId);
    if (before == null) return;

    final safeStart = timelineStartMicros.clamp(0, 1 << 62);
    final safeEnd = timelineEndMicros.clamp(
      safeStart + AppConstants.minClipDurationMicros,
      1 << 62,
    );

    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        timelineStartMicros: Value(safeStart),
        timelineEndMicros: Value(safeEnd),
        sourceInMicros: Value(sourceInMicros.clamp(0, 1 << 62)),
        sourceOutMicros: Value(sourceOutMicros.clamp(0, 1 << 62)),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    final after = await _timelineRepository.getClip(clipId);
    if (after != null) {
      await _recordCommand(
        projectId: projectId,
        actionType: 'trim_clip',
        description: 'Trim clip',
        payload: {
          'before': _clipToJson(before),
          'after': _clipToJson(after),
        },
      );
    }

    await _refreshProjectDuration(projectId);
  }

  // ─── Split clip ────────────────────────────────────────────────────────────

  Future<String?> splitClip({
    required String projectId,
    required String clipId,
    required int splitTimelineMicros,
  }) async {
    final clip = await _timelineRepository.getClip(clipId);
    if (clip == null) return null;

    if (splitTimelineMicros <= clip.timelineStartMicros ||
        splitTimelineMicros >= clip.timelineEndMicros) {
      return null;
    }

    final newClipId = _uuid.v4();

    // Calculate where in source the split falls
    final timelineOffset = splitTimelineMicros - clip.timelineStartMicros;
    final sourceSplitOffset =
        (timelineOffset * clip.speed).round();
    final sourceSplitMicros = clip.sourceInMicros + sourceSplitOffset;

    // Trim first half
    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        timelineEndMicros: Value(splitTimelineMicros),
        sourceOutMicros: Value(sourceSplitMicros),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    // Insert second half
    await _timelineRepository.insertClip(
      ClipsCompanion.insert(
        id: newClipId,
        projectId: clip.projectId,
        trackId: clip.trackId,
        assetId: Value(clip.assetId),
        clipType: Value(clip.clipType),
        timelineStartMicros: Value(splitTimelineMicros),
        timelineEndMicros: Value(clip.timelineEndMicros),
        sourceInMicros: Value(sourceSplitMicros),
        sourceOutMicros: Value(clip.sourceOutMicros),
        positionX: Value(clip.positionX),
        positionY: Value(clip.positionY),
        scale: Value(clip.scale),
        rotation: Value(clip.rotation),
        opacity: Value(clip.opacity),
        volume: Value(clip.volume),
        isAudioMuted: Value(clip.isAudioMuted),
        speed: Value(clip.speed),
        isReversed: Value(clip.isReversed),
        sortOrder: Value(splitTimelineMicros),
      ),
    );

    await _recordCommand(
      projectId: projectId,
      actionType: 'split_clip',
      description: 'Split clip',
      payload: {
        'originalClipId': clipId,
        'newClipId': newClipId,
        'splitTimelineMicros': splitTimelineMicros,
      },
    );

    return newClipId;
  }

  // ─── Delete clip ───────────────────────────────────────────────────────────

  Future<void> deleteClip({
    required String projectId,
    required String clipId,
    bool ripple = false,
  }) async {
    final clip = await _timelineRepository.getClip(clipId);
    if (clip == null) return;

    Clip? linkedClip;
    if (clip.isLinked && clip.linkedClipId != null) {
      linkedClip = await _timelineRepository.getClip(clip.linkedClipId!);
    }

    final payload = {'before': _clipToJson(clip)};
    if (linkedClip != null) {
      payload['linkedBefore'] = _clipToJson(linkedClip);
    }

    await _recordCommand(
      projectId: projectId,
      actionType: 'delete_clip',
      description: 'Delete clip',
      payload: payload,
    );

    await _timelineRepository.deleteClip(clipId);
    if (linkedClip != null) {
      await _timelineRepository.deleteClip(linkedClip.id);
    }
    
    await _refreshProjectDuration(projectId);

    if (ripple) {
      final duration = clip.timelineEndMicros - clip.timelineStartMicros;
      await _rippleShift(projectId, clip.trackId, clip.timelineStartMicros, -duration);
    }
  }

  // ─── Top & Tail Quick Trimming ─────────────────────────────────────────────

  Future<void> trimToPlayheadTop({
    required String projectId,
    required String clipId,
    required int playheadMicros,
    bool ripple = false,
  }) async {
    final clip = await _timelineRepository.getClip(clipId);
    if (clip == null) return;

    if (playheadMicros <= clip.timelineStartMicros || playheadMicros >= clip.timelineEndMicros) return;

    final trimAmount = playheadMicros - clip.timelineStartMicros;
    final sourceOffset = (trimAmount * clip.speed).round();

    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        timelineStartMicros: Value(playheadMicros),
        sourceInMicros: Value(clip.sourceInMicros + sourceOffset),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    if (ripple) {
      await _rippleShift(projectId, clip.trackId, clip.timelineStartMicros, -trimAmount, excludeClipId: clipId);
      // Shift the current clip back as well
      await moveClip(
        projectId: projectId, 
        clipId: clipId, 
        newTimelineStartMicros: clip.timelineStartMicros
      );
    }

    await _refreshProjectDuration(projectId);
  }

  Future<void> trimToPlayheadTail({
    required String projectId,
    required String clipId,
    required int playheadMicros,
    bool ripple = false,
  }) async {
    final clip = await _timelineRepository.getClip(clipId);
    if (clip == null) return;

    if (playheadMicros <= clip.timelineStartMicros || playheadMicros >= clip.timelineEndMicros) return;

    final trimAmount = clip.timelineEndMicros - playheadMicros;
    final sourceOffset = ((playheadMicros - clip.timelineStartMicros) * clip.speed).round();

    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        timelineEndMicros: Value(playheadMicros),
        sourceOutMicros: Value(clip.sourceInMicros + sourceOffset),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    if (ripple) {
      await _rippleShift(projectId, clip.trackId, clip.timelineEndMicros, -trimAmount);
    }

    await _refreshProjectDuration(projectId);
  }

  Future<void> _rippleShift(String projectId, String trackId, int afterMicros, int shiftAmount, {String? excludeClipId}) async {
    final clips = await _timelineRepository.getTrackClips(trackId);
    for (final c in clips) {
      if (c.id == excludeClipId) continue;
      if (c.timelineStartMicros >= afterMicros) {
        await _timelineRepository.updateClipFields(
          c.id,
          ClipsCompanion(
            timelineStartMicros: Value(c.timelineStartMicros + shiftAmount),
            timelineEndMicros: Value(c.timelineEndMicros + shiftAmount),
          ),
        );
      }
    }
  }

  // ─── Update transform ──────────────────────────────────────────────────────

  Future<void> updateClipTransform({
    required String projectId,
    required String clipId,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    double? opacity,
  }) async {
    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        positionX:
            positionX == null ? const Value.absent() : Value(positionX),
        positionY:
            positionY == null ? const Value.absent() : Value(positionY),
        scale: scale == null ? const Value.absent() : Value(scale),
        rotation: rotation == null ? const Value.absent() : Value(rotation),
        opacity: opacity == null ? const Value.absent() : Value(opacity),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    await _projectRepository.touchProject(projectId);
  }

  // ─── Update colour grading ─────────────────────────────────────────────────

  Future<void> updateClipColor({
    required String projectId,
    required String clipId,
    double? exposure,
    double? contrast,
    double? saturation,
    double? temperature,
    double? tint,
    double? highlights,
    double? shadows,
  }) async {
    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        exposure: exposure == null ? const Value.absent() : Value(exposure),
        contrast: contrast == null ? const Value.absent() : Value(contrast),
        saturation:
            saturation == null ? const Value.absent() : Value(saturation),
        temperature:
            temperature == null ? const Value.absent() : Value(temperature),
        tint: tint == null ? const Value.absent() : Value(tint),
        highlights:
            highlights == null ? const Value.absent() : Value(highlights),
        shadows: shadows == null ? const Value.absent() : Value(shadows),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    await _projectRepository.touchProject(projectId);
  }

  // ─── Update audio ──────────────────────────────────────────────────────────

  Future<void> updateClipAudio({
    required String projectId,
    required String clipId,
    double? volume,
    double? pan,
    bool? muted,
  }) async {
    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        volume: volume == null ? const Value.absent() : Value(volume),
        audioPan: pan == null ? const Value.absent() : Value(pan),
        isAudioMuted: muted == null ? const Value.absent() : Value(muted),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    await _projectRepository.touchProject(projectId);
  }

  // ─── Update speed ──────────────────────────────────────────────────────────

  Future<void> updateClipSpeed({
    required String projectId,
    required String clipId,
    required double speed,
    bool isReversed = false,
  }) async {
    final safeSpeed = speed.clamp(0.1, 8.0);

    final clip = await _timelineRepository.getClip(clipId);
    if (clip == null) return;

    final sourceDuration = clip.sourceOutMicros - clip.sourceInMicros;
    final newTimelineDuration = (sourceDuration / safeSpeed).round();
    final newEnd = clip.timelineStartMicros + newTimelineDuration;

    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        speed: Value(safeSpeed),
        isReversed: Value(isReversed),
        timelineEndMicros: Value(newEnd),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    await _refreshProjectDuration(projectId);
  }

  // ─── Update text ───────────────────────────────────────────────────────────

  Future<void> updateTextClip({
    required String projectId,
    required String clipId,
    required String text,
  }) async {
    await _timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        textContent: Value(text),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    await _projectRepository.touchProject(projectId);
  }

  // ─── Undo / Redo ───────────────────────────────────────────────────────────

  Future<bool> undo(String projectId) async {
    final entry = await _timelineRepository.getLastUndo(projectId);
    if (entry == null) return false;
    await _timelineRepository.moveHistoryToRedo(entry.id);
    await _applyInverse(projectId, entry);
    return true;
  }

  Future<bool> redo(String projectId) async {
    final entry = await _timelineRepository.getLastRedo(projectId);
    if (entry == null) return false;
    await _timelineRepository.moveHistoryToUndo(entry.id);
    await _applyForward(projectId, entry);
    return true;
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<void> _applyInverse(String projectId, UndoStackData entry) async {
    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    switch (entry.actionType) {
      case 'add_clip':
        final id = (payload['after'] as Map)['id'] as String;
        await _timelineRepository.deleteClip(id);
      case 'delete_clip':
        await _restoreClip(payload['before'] as Map<String, dynamic>);
        if (payload.containsKey('linkedBefore')) {
          await _restoreClip(payload['linkedBefore'] as Map<String, dynamic>);
        }
      case 'move_clip':
      case 'trim_clip':
        await _restoreClipFields(payload['before'] as Map<String, dynamic>);
        if (payload.containsKey('linkedBefore')) {
          await _restoreClipFields(payload['linkedBefore'] as Map<String, dynamic>);
        }
    }
    await _refreshProjectDuration(projectId);
  }

  Future<void> _applyForward(String projectId, UndoStackData entry) async {
    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    switch (entry.actionType) {
      case 'add_clip':
        await _restoreClip(payload['after'] as Map<String, dynamic>);
      case 'delete_clip':
        final id = (payload['before'] as Map)['id'] as String;
        await _timelineRepository.deleteClip(id);
        if (payload.containsKey('linkedBefore')) {
          final linkedId = (payload['linkedBefore'] as Map)['id'] as String;
          await _timelineRepository.deleteClip(linkedId);
        }
      case 'move_clip':
      case 'trim_clip':
        await _restoreClipFields(payload['after'] as Map<String, dynamic>);
        if (payload.containsKey('linkedAfter')) {
          await _restoreClipFields(payload['linkedAfter'] as Map<String, dynamic>);
        }
    }
    await _refreshProjectDuration(projectId);
  }

  Future<void> _restoreClip(Map<String, dynamic> data) async {
    await _timelineRepository.insertClip(
      ClipsCompanion.insert(
        id: data['id'] as String,
        projectId: data['projectId'] as String,
        trackId: data['trackId'] as String,
        assetId: Value(data['assetId'] as String?),
        clipType: Value(data['clipType'] as String),
        timelineStartMicros: Value(data['timelineStartMicros'] as int),
        timelineEndMicros: Value(data['timelineEndMicros'] as int),
        sourceInMicros: Value(data['sourceInMicros'] as int),
        sourceOutMicros: Value(data['sourceOutMicros'] as int),
        positionX: Value((data['positionX'] as num).toDouble()),
        positionY: Value((data['positionY'] as num).toDouble()),
        scale: Value((data['scale'] as num).toDouble()),
        isLinked: data.containsKey('isLinked') ? Value(data['isLinked'] as bool) : const Value.absent(),
        linkedClipId: data.containsKey('linkedClipId') ? Value(data['linkedClipId'] as String?) : const Value.absent(),
        sortOrder: const Value(0),
      ),
    );
  }

  Future<void> _restoreClipFields(Map<String, dynamic> data) async {
    await _timelineRepository.updateClipFields(
      data['id'] as String,
      ClipsCompanion(
        timelineStartMicros: Value(data['timelineStartMicros'] as int),
        timelineEndMicros: Value(data['timelineEndMicros'] as int),
        sourceInMicros: Value(data['sourceInMicros'] as int),
        sourceOutMicros: Value(data['sourceOutMicros'] as int),
        trackId: data['trackId'] == null ? const Value.absent() : Value(data['trackId'] as String),
      ),
    );
  }

  Future<void> _recordCommand({
    required String projectId,
    required String actionType,
    String? description,
    required Map<String, dynamic> payload,
  }) async {
    await _timelineRepository.clearRedoStack(projectId);
    await _timelineRepository.insertHistory(
      UndoStackCompanion.insert(
        id: _uuid.v4(),
        projectId: projectId,
        actionType: actionType,
        description: Value(description),
        payload: jsonEncode(payload),
        sequence: DateTime.now().microsecondsSinceEpoch,
      ),
    );
  }

  Future<void> _refreshProjectDuration(String projectId) async {
    final duration =
        await _timelineRepository.calculateProjectDuration(projectId);
    await _projectRepository.updateProjectDuration(projectId, duration);
  }

  Map<String, dynamic> _clipToJson(Clip clip) => {
        'id': clip.id,
        'projectId': clip.projectId,
        'trackId': clip.trackId,
        'assetId': clip.assetId,
        'clipType': clip.clipType,
        'timelineStartMicros': clip.timelineStartMicros,
        'timelineEndMicros': clip.timelineEndMicros,
        'sourceInMicros': clip.sourceInMicros,
        'sourceOutMicros': clip.sourceOutMicros,
        'positionX': clip.positionX,
        'positionY': clip.positionY,
        'scale': clip.scale,
        'rotation': clip.rotation,
        'opacity': clip.opacity,
        'speed': clip.speed,
        'isReversed': clip.isReversed,
      };
}
