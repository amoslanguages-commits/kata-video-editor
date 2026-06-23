import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/titles/title_clip_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

class MultitrackDbMapper {
  const MultitrackDbMapper();

  MultitrackTrack trackFromDb(db.Track row) {
    return MultitrackTrack(
      id: row.id,
      projectId: row.projectId,
      name: row.name,
      type: _trackType(row.type),
      role: _trackRole(row.trackRole),
      sortOrder: row.index,
      isMuted: row.isMuted,
      isSolo: row.isSolo,
      isLocked: row.isLocked,
      isHidden: row.isHidden || !row.isVisible,
      height: row.height.toDouble(),
      color: _parseColor(
        row.colorHex ?? row.color,
        fallback: _fallbackTrackColor(
          row.type,
          row.trackRole,
          row.index,
        ),
      ),
    );
  }

  MultitrackClip clipFromDb(db.Clip row) {
    String? textContent = _emptyToNull(row.textContent);
    String? textStyleJson = _emptyToNull(row.textStyleJson);
    String? colorHex = _emptyToNull(row.colorHex);

    if (row.isTitleClip && row.titleDataJson != null && row.titleDataJson!.trim().isNotEmpty) {
      try {
        final data = NleTitleClipData.fromJson(
          Map<String, dynamic>.from(jsonDecode(row.titleDataJson!) as Map),
        );
        textContent = data.text;
        
        // Convert rich nested styling to flat JSON format for Android native rasterizer
        final flatStyle = {
          'fontSize': data.style.fontSize,
          'color': _rgbaToHex(data.style.fillColor),
          'opacity': data.style.opacity,
          'strokeColor': _rgbaToHex(data.style.stroke.color),
          'strokeWidth': data.style.stroke.enabled ? data.style.stroke.width : 0.0,
          'shadowEnabled': data.style.shadow.enabled,
          'shadowColor': _rgbaToHex(data.style.shadow.color),
          'shadowBlur': data.style.shadow.blur,
          'shadowOffsetX': data.style.shadow.offsetX,
          'shadowOffsetY': data.style.shadow.offsetY,
          'backgroundEnabled': data.style.background.enabled,
          'backgroundColor': _rgbaToHex(data.style.background.color),
          'backgroundRadius': data.style.background.radius,
          'alignment': data.layout.horizontalAlign.name,
        };
        textStyleJson = jsonEncode(flatStyle);
        colorHex = _rgbaToHex(data.style.fillColor);
      } catch (_) {
        // Keep original if JSON decode fails
      }
    }

    if (row.isOverlayClip && row.overlayDataJson != null && row.overlayDataJson!.trim().isNotEmpty) {
      try {
        final data = NleOverlayClipData.fromJson(
          Map<String, dynamic>.from(jsonDecode(row.overlayDataJson!) as Map),
        );
        textContent = data.name;
        if (data.shapeStyle != null && data.shapeStyle!.fillEnabled) {
          colorHex = _rgbaToHex(data.shapeStyle!.fillColor);
        } else if (data.lineStyle != null) {
          colorHex = _rgbaToHex(data.lineStyle!.color);
        }
      } catch (_) {
        // Keep original if JSON decode fails
      }
    }

    return MultitrackClip(
      id: row.id,
      projectId: row.projectId,
      trackId: row.trackId,
      assetId: _emptyToNull(row.assetId),
      type: _clipType(row.clipType),
      name: _clipName(row),
      timelineStartMicros: row.timelineStartMicros,
      timelineEndMicros: row.timelineEndMicros,
      sourceStartMicros: row.sourceInMicros,
      sourceEndMicros: row.sourceOutMicros,
      speed: row.speed,
      opacity: row.opacity,
      positionX: row.positionX,
      positionY: row.positionY,
      scale: row.scale,
      rotation: row.rotation,
      textContent: textContent,
      textStyleJson: textStyleJson,
      colorHex: colorHex,
      isSelected: false,
      isDisabled: row.isDisabled,
    );
  }

  String _rgbaToHex(NleRgbaColor color) {
    final a = (color.a * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final r = (color.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#$a$r$g$b'.toUpperCase();
  }

  MultitrackTrackType _trackType(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'audio':
        return MultitrackTrackType.audio;
      case 'text':
      case 'caption':
      case 'titles':
        return MultitrackTrackType.text;
      case 'overlay':
      case 'sticker':
      case 'image_overlay':
        return MultitrackTrackType.overlay;
      case 'adjustment':
      case 'adjustment_layer':
      case 'lut':
      case 'color':
        return MultitrackTrackType.adjustment;
      case 'video':
      case 'visual':
      case 'main':
      default:
        return MultitrackTrackType.video;
    }
  }

  MultitrackTrackRole _trackRole(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    switch (value) {
      case 'main':
      case 'main_video':
      case 'v1':
        return MultitrackTrackRole.mainVideo;
      case 'broll':
      case 'b_roll':
      case 'secondary':
        return MultitrackTrackRole.broll;
      case 'overlay':
      case 'sticker':
      case 'image_overlay':
        return MultitrackTrackRole.overlay;
      case 'text':
      case 'title':
      case 'caption':
        return MultitrackTrackRole.text;
      case 'adjustment':
      case 'lut':
      case 'color':
        return MultitrackTrackRole.adjustment;
      case 'voice':
      case 'voiceover':
      case 'dialogue':
      case 'dialog':
        return MultitrackTrackRole.voice;
      case 'music':
      case 'song':
      case 'bgm':
        return MultitrackTrackRole.music;
      case 'sfx':
      case 'sound_effect':
      case 'sound_effects':
        return MultitrackTrackRole.sfx;
      default:
        return MultitrackTrackRole.unknown;
    }
  }

  MultitrackClipType _clipType(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'video':
      case 'media':
        return MultitrackClipType.video;
      case 'image':
      case 'photo':
      case 'sticker':
      case 'overlay':
        return MultitrackClipType.image;
      case 'audio':
      case 'music':
      case 'voice':
      case 'sfx':
        return MultitrackClipType.audio;
      case 'text':
      case 'caption':
      case 'title':
        return MultitrackClipType.text;
      case 'adjustment':
      case 'lut':
      case 'color':
        return MultitrackClipType.adjustment;
      default:
        return MultitrackClipType.unknown;
    }
  }

  String _clipName(db.Clip row) {
    switch (_clipType(row.clipType)) {
      case MultitrackClipType.video:
        return 'Video Clip';
      case MultitrackClipType.image:
        return 'Image';
      case MultitrackClipType.audio:
        return 'Audio';
      case MultitrackClipType.text:
        return row.textContent != null && row.textContent!.trim().isNotEmpty
            ? row.textContent!
            : 'Text';
      case MultitrackClipType.adjustment:
        return 'Adjustment';
      case MultitrackClipType.unknown:
        return 'Clip';
    }
  }

  Color _parseColor(
    String? hex, {
    required Color fallback,
  }) {
    if (hex == null || hex.trim().isEmpty) {
      return fallback;
    }
    var clean = hex.trim().replaceAll('#', '');
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    if (clean.length != 8) {
      return fallback;
    }
    final value = int.tryParse(clean, radix: 16);
    if (value == null) {
      return fallback;
    }
    return Color(value);
  }

  Color _fallbackTrackColor(
    String trackType,
    String? role,
    int sortOrder,
  ) {
    final type = trackType.toLowerCase();
    final trackRole = (role ?? '').toLowerCase();

    if (type == 'audio') {
      if (trackRole.contains('voice')) return const Color(0xFF1DB954);
      if (trackRole.contains('music')) return const Color(0xFF00C853);
      if (trackRole.contains('sfx')) return const Color(0xFF64DD17);
      return const Color(0xFF1DB954);
    }
    if (type == 'text') {
      return const Color(0xFFFF8A00);
    }
    if (type == 'overlay') {
      return const Color(0xFF7C4DFF);
    }
    if (type == 'adjustment') {
      return const Color(0xFFB000FF);
    }
    switch (sortOrder) {
      case 1:
        return const Color(0xFF235BFF);
      case 2:
        return const Color(0xFF00B8FF);
      case 3:
        return const Color(0xFF7C4DFF);
      case 4:
        return const Color(0xFFFF8A00);
      case 5:
        return const Color(0xFFB000FF);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    if (value.trim().isEmpty) return null;
    return value;
  }
}
