import 'dart:math' as math;

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/timeline/clip_interaction_models.dart';

class ClipInteractionsRepository {
  final db.AppDatabase database;

  static const int minClipDurationMicros = 100000;
  static const int duplicateOffsetMicros = 500000;

  const ClipInteractionsRepository({
    required this.database,
  });

  Future<db.Clip> getClip(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      throw ClipInteractionException('Clip $clipId not found.');
    }
    return clip;
  }

  Future<void> moveClipBy({
    required String clipId,
    required int deltaMicros,
  }) async {
    final clip = await getClip(clipId);
    final track = await database.getTrack(clip.trackId);

    _throwIfTrackLocked(track);

    final duration = clip.timelineEndMicros - clip.timelineStartMicros;

    final newStart = math.max(
      0,
      clip.timelineStartMicros + deltaMicros,
    );

    final newEnd = newStart + duration;

    await database.updateClipTiming(
      clipId: clipId,
      timelineStartMicros: newStart,
      timelineEndMicros: newEnd,
    );
  }

  Future<void> moveClipTo({
    required String clipId,
    required String targetTrackId,
    required int newStartMicros,
  }) async {
    final clip = await getClip(clipId);
    final sourceTrack = await database.getTrack(clip.trackId);
    final targetTrack = await database.getTrack(targetTrackId);

    _throwIfTrackLocked(sourceTrack);
    _throwIfTrackLocked(targetTrack);

    if (!_isTrackCompatibleWithClip(targetTrack, clip)) {
      throw const ClipInteractionException(
        'This clip type cannot be moved to that track.',
      );
    }

    final duration = clip.timelineEndMicros - clip.timelineStartMicros;

    final safeStart = math.max(0, newStartMicros);
    final safeEnd = safeStart + duration;

    await database.updateClipTiming(
      clipId: clipId,
      trackId: targetTrackId,
      timelineStartMicros: safeStart,
      timelineEndMicros: safeEnd,
    );
  }

  Future<void> trimLeftBy({
    required String clipId,
    required int deltaMicros,
    bool ripple = false,
  }) async {
    final clip = await getClip(clipId);
    final track = await database.getTrack(clip.trackId);

    _throwIfTrackLocked(track);

    final minStart = 0;
    final maxStart = clip.timelineEndMicros - minClipDurationMicros;

    final proposedStart = clip.timelineStartMicros + deltaMicros;
    final newStart = proposedStart.clamp(minStart, maxStart).toInt();

    final actualDelta = newStart - clip.timelineStartMicros;
    final sourceDelta = (actualDelta * clip.speed).round();

    final newSourceStart = math.max(
      0,
      clip.sourceInMicros + sourceDelta,
    );

    if (newSourceStart >= clip.sourceOutMicros) {
      throw const ClipInteractionException(
        'Cannot trim beyond available source media.',
      );
    }

    await database.transaction(() async {
      await database.updateClipTiming(
        clipId: clipId,
        timelineStartMicros: newStart,
        timelineEndMicros: clip.timelineEndMicros,
        sourceStartMicros: newSourceStart,
        sourceEndMicros: clip.sourceOutMicros,
      );

      if (ripple && actualDelta != 0) {
        final allClips = await database.getTrackClips(clip.trackId);
        final clipsToShift = allClips.where((c) => c.id != clipId && c.timelineStartMicros >= clip.timelineStartMicros).toList();
        for (final c in clipsToShift) {
          await database.updateClipTiming(
            clipId: c.id,
            timelineStartMicros: c.timelineStartMicros + actualDelta,
            timelineEndMicros: c.timelineEndMicros + actualDelta,
          );
        }
      }
    });
  }

  Future<void> trimRightBy({
    required String clipId,
    required int deltaMicros,
    bool ripple = false,
  }) async {
    final clip = await getClip(clipId);
    final track = await database.getTrack(clip.trackId);

    _throwIfTrackLocked(track);

    final minEnd = clip.timelineStartMicros + minClipDurationMicros;

    final assetDuration = await database.getAssetDurationMicros(clip.assetId);
    final sourceMax = assetDuration ?? clip.sourceOutMicros;

    final proposedEnd = clip.timelineEndMicros + deltaMicros;

    final currentTimelineDuration = clip.timelineEndMicros - clip.timelineStartMicros;

    final maxTimelineDurationFromSource = clip.speed <= 0
        ? currentTimelineDuration
        : (sourceMax - clip.sourceInMicros) / clip.speed;

    final maxEnd = clip.timelineStartMicros +
        math.max(
          minClipDurationMicros,
          maxTimelineDurationFromSource.round(),
        );

    final newEnd = proposedEnd.clamp(minEnd, maxEnd).toInt();

    final actualDelta = newEnd - clip.timelineEndMicros;

    final newTimelineDuration = newEnd - clip.timelineStartMicros;
    final newSourceEnd = clip.sourceInMicros +
        (newTimelineDuration * clip.speed).round();

    if (newSourceEnd <= clip.sourceInMicros) {
      throw const ClipInteractionException(
        'Cannot trim clip to zero duration.',
      );
    }

    if (newSourceEnd > sourceMax) {
      throw const ClipInteractionException(
        'Cannot trim beyond available source media.',
      );
    }

    await database.transaction(() async {
      await database.updateClipTiming(
        clipId: clipId,
        timelineStartMicros: clip.timelineStartMicros,
        timelineEndMicros: newEnd,
        sourceStartMicros: clip.sourceInMicros,
        sourceEndMicros: newSourceEnd,
      );

      if (ripple && actualDelta != 0) {
        final allClips = await database.getTrackClips(clip.trackId);
        final clipsToShift = allClips.where((c) => c.id != clipId && c.timelineStartMicros >= clip.timelineEndMicros).toList();
        for (final c in clipsToShift) {
          await database.updateClipTiming(
            clipId: c.id,
            timelineStartMicros: c.timelineStartMicros + actualDelta,
            timelineEndMicros: c.timelineEndMicros + actualDelta,
          );
        }
      }
    });
  }

  Future<String> splitClipAt({
    required String clipId,
    required int splitMicros,
  }) async {
    final clip = await getClip(clipId);
    final track = await database.getTrack(clip.trackId);

    _throwIfTrackLocked(track);

    if (splitMicros <= clip.timelineStartMicros + minClipDurationMicros ||
        splitMicros >= clip.timelineEndMicros - minClipDurationMicros) {
      throw const ClipInteractionException(
        'Split point is too close to the clip edge.',
      );
    }

    return database.splitClipAt(
      clipId: clipId,
      splitMicros: splitMicros,
    );
  }

  Future<void> deleteClip(String clipId) async {
    final clip = await getClip(clipId);
    final track = await database.getTrack(clip.trackId);

    _throwIfTrackLocked(track);

    await database.deleteClipById(clipId);
  }

  Future<String> duplicateClip(String clipId) async {
    final clip = await getClip(clipId);
    final track = await database.getTrack(clip.trackId);

    _throwIfTrackLocked(track);

    return database.duplicateClip(
      clipId: clipId,
      offsetMicros: duplicateOffsetMicros,
    );
  }

  void _throwIfTrackLocked(db.Track track) {
    if (track.isLocked) {
      throw const ClipInteractionException(
        'This track is locked. Unlock it before editing clips.',
      );
    }
  }

  bool _isTrackCompatibleWithClip(
    db.Track track,
    db.Clip clip,
  ) {
    final trackType = track.type.toLowerCase();
    final clipType = clip.clipType.toLowerCase();

    if (clipType == 'audio' || clipType == 'music' || clipType == 'voice') {
      return trackType == 'audio';
    }

    if (clipType == 'text' || clipType == 'caption' || clipType == 'title') {
      return trackType == 'text' || trackType == 'overlay';
    }

    if (clipType == 'image' || clipType == 'sticker') {
      return trackType == 'video' || trackType == 'overlay';
    }

    if (clipType == 'adjustment') {
      return trackType == 'adjustment';
    }

    if (clipType == 'video') {
      return trackType == 'video' || trackType == 'overlay';
    }

    return true;
  }

  Future<void> slipClipBy({
    required String clipId,
    required int deltaMicros,
  }) async {
    final clip = await getClip(clipId);
    final track = await database.getTrack(clip.trackId);
    _throwIfTrackLocked(track);

    final assetDuration = await database.getAssetDurationMicros(clip.assetId) ?? clip.sourceOutMicros;
    final duration = clip.timelineEndMicros - clip.timelineStartMicros;
    final sourceDuration = (duration * clip.speed).round();

    int newSourceIn = clip.sourceInMicros + deltaMicros;
    int newSourceOut = newSourceIn + sourceDuration;

    if (newSourceIn < 0) {
      newSourceIn = 0;
      newSourceOut = sourceDuration;
    } else if (newSourceOut > assetDuration) {
      newSourceOut = assetDuration;
      newSourceIn = assetDuration - sourceDuration;
    }

    if (newSourceIn == clip.sourceInMicros) return;

    await database.updateClipTiming(
      clipId: clipId,
      timelineStartMicros: clip.timelineStartMicros,
      timelineEndMicros: clip.timelineEndMicros,
      sourceStartMicros: newSourceIn,
      sourceEndMicros: newSourceOut,
    );
  }

  Future<void> slideClipBy({
    required String clipId,
    required int deltaMicros,
  }) async {
    final clip = await getClip(clipId);
    final track = await database.getTrack(clip.trackId);
    _throwIfTrackLocked(track);

    final duration = clip.timelineEndMicros - clip.timelineStartMicros;
    
    final allClips = await database.getTrackClips(clip.trackId);
    allClips.sort((a, b) => a.timelineStartMicros.compareTo(b.timelineStartMicros));
    
    final index = allClips.indexWhere((c) => c.id == clipId);
    if (index == -1) return;
    
    final prevClip = index > 0 ? allClips[index - 1] : null;
    final nextClip = index < allClips.length - 1 ? allClips[index + 1] : null;

    final proposedStart = clip.timelineStartMicros + deltaMicros;
    final proposedEnd = proposedStart + duration;

    int actualDelta = deltaMicros;
    if (deltaMicros < 0 && prevClip != null) {
      final minStart = prevClip.timelineStartMicros + minClipDurationMicros;
      if (proposedStart < minStart) {
        actualDelta = minStart - clip.timelineStartMicros;
      }
    } else if (deltaMicros > 0 && nextClip != null) {
      final maxEnd = nextClip.timelineEndMicros - minClipDurationMicros;
      if (proposedEnd > maxEnd) {
        actualDelta = maxEnd - clip.timelineEndMicros;
      }
    }

    if (actualDelta == 0) return;

    final newStart = clip.timelineStartMicros + actualDelta;
    final newEnd = clip.timelineEndMicros + actualDelta;

    await database.transaction(() async {
      await database.updateClipTiming(
        clipId: clipId,
        timelineStartMicros: newStart,
        timelineEndMicros: newEnd,
      );

      if (prevClip != null && prevClip.timelineEndMicros == clip.timelineStartMicros) {
         final prevNewEnd = prevClip.timelineEndMicros + actualDelta;
         final prevDuration = prevNewEnd - prevClip.timelineStartMicros;
         final prevSourceEnd = prevClip.sourceInMicros + (prevDuration * prevClip.speed).round();
         await database.updateClipTiming(
           clipId: prevClip.id,
           timelineStartMicros: prevClip.timelineStartMicros,
           timelineEndMicros: prevNewEnd,
           sourceStartMicros: prevClip.sourceInMicros,
           sourceEndMicros: prevSourceEnd,
         );
      }

      if (nextClip != null && nextClip.timelineStartMicros == clip.timelineEndMicros) {
         final nextNewStart = nextClip.timelineStartMicros + actualDelta;
         final nextDelta = nextNewStart - nextClip.timelineStartMicros;
         final nextSourceStart = nextClip.sourceInMicros + (nextDelta * nextClip.speed).round();
         await database.updateClipTiming(
           clipId: nextClip.id,
           timelineStartMicros: nextNewStart,
           timelineEndMicros: nextClip.timelineEndMicros,
           sourceStartMicros: nextSourceStart,
           sourceEndMicros: nextClip.sourceOutMicros,
         );
      }
    });
  }

  Future<void> rollEditAt({
    required String leftClipId,
    required String rightClipId,
    required int deltaMicros,
  }) async {
    final leftClip = await getClip(leftClipId);
    final rightClip = await getClip(rightClipId);

    if (leftClip.trackId != rightClip.trackId) {
      throw const ClipInteractionException('Clips must be on the same track.');
    }

    final track = await database.getTrack(leftClip.trackId);
    _throwIfTrackLocked(track);

    if (leftClip.timelineEndMicros != rightClip.timelineStartMicros) {
       throw const ClipInteractionException('Clips must be adjacent.');
    }

    final leftAssetDuration = await database.getAssetDurationMicros(leftClip.assetId) ?? leftClip.sourceOutMicros;

    final minLeftEnd = leftClip.timelineStartMicros + minClipDurationMicros;
    final maxLeftDuration = (leftAssetDuration - leftClip.sourceInMicros) / leftClip.speed;
    final maxLeftEnd = leftClip.timelineStartMicros + math.max(minClipDurationMicros, maxLeftDuration.round());

    final minRightStart = rightClip.timelineStartMicros - (rightClip.sourceInMicros / rightClip.speed).round();
    final maxRightStart = rightClip.timelineEndMicros - minClipDurationMicros;

    final proposedSplit = leftClip.timelineEndMicros + deltaMicros;

    final clamp1 = proposedSplit.clamp(minLeftEnd, maxLeftEnd).toInt();
    final newSplit = clamp1.clamp(math.max(minLeftEnd, minRightStart), math.min(maxLeftEnd, maxRightStart)).toInt();

    if (newSplit == leftClip.timelineEndMicros) return;

    final leftNewDuration = newSplit - leftClip.timelineStartMicros;
    final leftNewSourceEnd = leftClip.sourceInMicros + (leftNewDuration * leftClip.speed).round();

    final rightDelta = newSplit - rightClip.timelineStartMicros;
    final rightNewSourceStart = rightClip.sourceInMicros + (rightDelta * rightClip.speed).round();

    await database.transaction(() async {
      await database.updateClipTiming(
        clipId: leftClip.id,
        timelineStartMicros: leftClip.timelineStartMicros,
        timelineEndMicros: newSplit,
        sourceStartMicros: leftClip.sourceInMicros,
        sourceEndMicros: leftNewSourceEnd,
      );
      await database.updateClipTiming(
        clipId: rightClip.id,
        timelineStartMicros: newSplit,
        timelineEndMicros: rightClip.timelineEndMicros,
        sourceStartMicros: rightNewSourceStart,
        sourceEndMicros: rightClip.sourceOutMicros,
      );
    });
  }
}
