import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;

import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/models/temporary_export_progress.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

/// STEP 21 — Temporary FFmpeg-based V1 export that joins video clips into one file
/// and saves it to the device gallery via [Gal].
/// This will be replaced by the native NLE engine export pipeline.
class TemporaryExportService {
  final AssetRepository assetRepository;
  final TimelineRepository timelineRepository;
  final ProjectStorageService storageService;

  TemporaryExportService({
    required this.assetRepository,
    required this.timelineRepository,
    required this.storageService,
  });

  Stream<TemporaryExportProgress> exportSimpleV1Sequence({
    required String projectId,
    required int targetWidth,
    required int targetHeight,
    required int frameRate,
    required String preset,
    required String bitrate,
    String? outputFileName,
  }) async* {
    yield const TemporaryExportProgress(progress: 2, stage: 'Preparing timeline');

    final tracks = await timelineRepository.getProjectTracks(projectId);
    final videoTracks = tracks.where((t) => t.type == 'video').toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (videoTracks.isEmpty) throw StateError('No video track found.');

    final allClips = await timelineRepository.getProjectClips(projectId);
    final videoClips = allClips
        .where((c) =>
            c.trackId == videoTracks.first.id &&
            c.assetId != null &&
            c.clipType == 'video')
        .toList()
      ..sort((a, b) => a.timelineStartMicros.compareTo(b.timelineStartMicros));

    if (videoClips.isEmpty) throw StateError('No video clips on the main track.');

    final folders = await storageService.getProjectFolders(projectId);
    final exportId = DateTime.now().millisecondsSinceEpoch.toString();
    final segmentDir = Directory(p.join(folders.temp, 'export_$exportId'));
    await segmentDir.create(recursive: true);

    final segmentPaths = <String>[];

    yield const TemporaryExportProgress(progress: 6, stage: 'Rendering clips');

    for (var i = 0; i < videoClips.length; i++) {
      final clip = videoClips[i];
      final asset = await assetRepository.getAsset(clip.assetId!);
      if (asset == null) continue;

      if (!await File(asset.originalPath).exists()) {
        throw StateError('Missing file: ${asset.fileName}');
      }

      final segmentPath = p.join(segmentDir.path, 'segment_$i.mp4');
      final ssSeconds = (clip.sourceInMicros / 1000000.0).toStringAsFixed(3);
      final durationSeconds =
          ((clip.timelineEndMicros - clip.timelineStartMicros) / 1000000.0)
              .toStringAsFixed(3);

      final vf =
          'scale=$targetWidth:$targetHeight:force_original_aspect_ratio=decrease,'
          'pad=$targetWidth:$targetHeight:(ow-iw)/2:(oh-ih)/2,setsar=1';

      final cmd = [
        '-y',
        '-ss', ssSeconds,
        '-t', durationSeconds,
        '-i', _q(asset.originalPath),
        '-vf', _q(vf),
        '-r', frameRate.toString(),
        '-c:v', 'libx264',
        '-preset', 'veryfast',
        '-b:v', bitrate,
        '-pix_fmt', 'yuv420p',
        '-c:a', 'aac',
        '-b:a', '192k',
        '-movflags', '+faststart',
        _q(segmentPath),
      ].join(' ');

      final session = await FFmpegKit.execute(cmd);
      if (!ReturnCode.isSuccess(await session.getReturnCode())) {
        throw StateError(
            'Clip render failed:\n${await session.getAllLogsAsString()}');
      }

      segmentPaths.add(segmentPath);

      final progress = 6 + (((i + 1) / videoClips.length) * 54).round();
      yield TemporaryExportProgress(
        progress: progress,
        stage: 'Rendered clip ${i + 1} of ${videoClips.length}',
      );
    }

    if (segmentPaths.isEmpty) throw StateError('No clips were rendered.');

    yield const TemporaryExportProgress(progress: 64, stage: 'Joining clips');

    final concatListPath = p.join(segmentDir.path, 'concat.txt');
    final concatList = segmentPaths
        .map((p) => "file '${p.replaceAll("'", r"'\''")}'")
        .join('\n');
    await File(concatListPath).writeAsString(concatList);

    final fallbackName = 'export_${DateTime.now().millisecondsSinceEpoch}_$preset.mp4';
    final finalName = outputFileName == null || outputFileName.trim().isEmpty
        ? fallbackName
        : outputFileName.trim();
    final outputPath = p.join(folders.exports, finalName);

    final concatCmd = [
      '-y',
      '-f', 'concat',
      '-safe', '0',
      '-i', _q(concatListPath),
      '-c', 'copy',
      _q(outputPath),
    ].join(' ');

    final concatSession = await FFmpegKit.execute(concatCmd);
    if (!ReturnCode.isSuccess(await concatSession.getReturnCode())) {
      throw StateError(
          'Concat failed:\n${await concatSession.getAllLogsAsString()}');
    }

    yield const TemporaryExportProgress(progress: 86, stage: 'Saving to gallery');

    try {
      await Gal.putVideo(outputPath);
    } catch (_) {
      // Export is still valid even if gallery save fails.
    }

    yield TemporaryExportProgress(
      progress: 100,
      stage: 'Complete',
      outputPath: outputPath,
    );

    try {
      await segmentDir.delete(recursive: true);
    } catch (_) {}
  }

  String _q(String value) => '"${value.replaceAll('"', r'\"')}"';
}
