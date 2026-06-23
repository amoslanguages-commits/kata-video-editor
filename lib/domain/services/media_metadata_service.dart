import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';

class MediaMetadata {
  final int? durationMicros;
  final int? width;
  final int? height;
  final double? frameRate;
  final String? codec;
  final String? audioCodec;
  final int? audioChannels;
  final int? audioSampleRate;
  final int rotation;
  final bool hasVideo;
  final bool hasAudio;
  final String? mimeType;

  const MediaMetadata({
    this.durationMicros,
    this.width,
    this.height,
    this.frameRate,
    this.codec,
    this.audioCodec,
    this.audioChannels,
    this.audioSampleRate,
    this.rotation = 0,
    this.hasVideo = false,
    this.hasAudio = false,
    this.mimeType,
  });
}

class MediaMetadataService {
  Future<MediaMetadata> extract({
    required String path,
    required String fileType,
  }) async {
    final mimeType = lookupMimeType(path);

    if (fileType == 'video') {
      return _extractVideoMetadata(path, mimeType);
    }

    if (fileType == 'image') {
      return _extractImageMetadata(path, mimeType);
    }

    if (fileType == 'audio') {
      return MediaMetadata(
        mimeType: mimeType,
        hasAudio: true,
        hasVideo: false,
      );
    }

    return MediaMetadata(mimeType: mimeType);
  }

  Future<MediaMetadata> _extractVideoMetadata(
      String path, String? mimeType) async {
    final controller = VideoPlayerController.file(File(path));

    try {
      await controller.initialize();
      final value = controller.value;
      final size = value.size;

      return MediaMetadata(
        durationMicros: value.duration.inMicroseconds,
        width: size.width > 0 ? size.width.round() : null,
        height: size.height > 0 ? size.height.round() : null,
        rotation: 0,
        hasVideo: true,
        hasAudio: true,
        mimeType: mimeType,
      );
    } catch (_) {
      return MediaMetadata(
        mimeType: mimeType,
        hasVideo: true,
        hasAudio: true,
      );
    } finally {
      await controller.dispose();
    }
  }

  Future<MediaMetadata> _extractImageMetadata(
      String path, String? mimeType) async {
    try {
      final bytes = await File(path).readAsBytes();
      final image = await _decodeImage(bytes);

      return MediaMetadata(
        width: image.width,
        height: image.height,
        hasVideo: false,
        hasAudio: false,
        mimeType: mimeType,
      );
    } catch (_) {
      return MediaMetadata(
        hasVideo: false,
        hasAudio: false,
        mimeType: mimeType,
      );
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }
}
