import 'dart:convert';

import 'package:uuid/uuid.dart';

class AppErrorCategory {
  AppErrorCategory._();

  static const String permission = 'permission';
  static const String missingFile = 'missing_file';
  static const String unsupportedCodec = 'unsupported_codec';
  static const String corruptedMedia = 'corrupted_media';
  static const String storage = 'storage';
  static const String memory = 'memory';
  static const String export = 'export';
  static const String proxy = 'proxy';
  static const String thumbnail = 'thumbnail';
  static const String waveform = 'waveform';
  static const String audio = 'audio';
  static const String timeline = 'timeline';
  static const String renderGraph = 'render_graph';
  static const String nativeEngine = 'native_engine';
  static const String database = 'database';
  static const String settings = 'settings';
  static const String unknown = 'unknown';
}

class AppErrorSeverity {
  AppErrorSeverity._();

  static const String info = 'info';
  static const String warning = 'warning';
  static const String error = 'error';
  static const String critical = 'critical';
}

class AppErrorCode {
  AppErrorCode._();

  static const String permissionDenied = 'permission_denied';
  static const String mediaPermissionDenied = 'media_permission_denied';
  static const String microphonePermissionDenied = 'microphone_permission_denied';
  static const String gallerySavePermissionDenied = 'gallery_save_permission_denied';

  static const String originalFileMissing = 'original_file_missing';
  static const String filePathExpired = 'file_path_expired';
  static const String reconnectRequired = 'reconnect_required';

  static const String unsupportedVideoCodec = 'unsupported_video_codec';
  static const String unsupportedAudioCodec = 'unsupported_audio_codec';
  static const String unsupportedHevc = 'unsupported_hevc';
  static const String unsupportedTenBit = 'unsupported_10_bit';
  static const String unsupportedHdr = 'unsupported_hdr';

  static const String corruptedMedia = 'corrupted_media';
  static const String mediaReadFailed = 'media_read_failed';
  static const String metadataReadFailed = 'metadata_read_failed';

  static const String storageLow = 'storage_low';
  static const String storageWriteFailed = 'storage_write_failed';
  static const String cacheClearFailed = 'cache_clear_failed';

  static const String memoryPressure = 'memory_pressure';
  static const String previewMemoryFailed = 'preview_memory_failed';

  static const String exportFailed = 'export_failed';
  static const String exportCancelled = 'export_cancelled';
  static const String exportInterrupted = 'export_interrupted';
  static const String exportEncoderFailed = 'export_encoder_failed';
  static const String exportMuxerFailed = 'export_muxer_failed';
  static const String exportOriginalMissing = 'export_original_missing';

  static const String proxyFailed = 'proxy_failed';
  static const String proxyCancelled = 'proxy_cancelled';
  static const String proxyStorageInsufficient = 'proxy_storage_insufficient';

  static const String thumbnailFailed = 'thumbnail_failed';
  static const String waveformFailed = 'waveform_failed';

  static const String audioDecodeFailed = 'audio_decode_failed';
  static const String audioMixFailed = 'audio_mix_failed';

  static const String timelineInvalidEdit = 'timeline_invalid_edit';
  static const String transitionNotEnoughMedia = 'transition_not_enough_media';
  static const String clipNotFound = 'clip_not_found';

  static const String renderGraphBuildFailed = 'render_graph_build_failed';
  static const String nativeEngineFailed = 'native_engine_failed';
  static const String nativeBridgeFailed = 'native_bridge_failed';

  static const String databaseFailed = 'database_failed';
  static const String unknown = 'unknown';
}

class AppErrorAction {
  final String label;
  final String actionId;
  final Map<String, dynamic> payload;

  const AppErrorAction({
    required this.label,
    required this.actionId,
    this.payload = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'actionId': actionId,
      'payload': payload,
    };
  }

  factory AppErrorAction.fromJson(Map<String, dynamic> json) {
    return AppErrorAction(
      label: json['label'] as String? ?? 'Action',
      actionId: json['actionId'] as String? ?? 'unknown',
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}

class AppErrorActionId {
  AppErrorActionId._();

  static const String retry = 'retry';
  static const String reconnectMedia = 'reconnect_media';
  static const String openSettings = 'open_settings';
  static const String clearCache = 'clear_cache';
  static const String lowerExportQuality = 'lower_export_quality';
  static const String useH264 = 'use_h264';
  static const String freeStorage = 'free_storage';
  static const String dismiss = 'dismiss';
  static const String viewDetails = 'view_details';
}

class AppError {
  final String id;
  final String category;
  final String code;
  final String severity;

  final String userMessage;
  final String? technicalMessage;
  final String? recoverySuggestion;

  final String? projectId;
  final String? source;
  final String? nativeCode;

  final AppErrorAction? action;

  final Map<String, dynamic> context;
  final DateTime createdAt;

  AppError({
    String? id,
    required this.category,
    required this.code,
    required this.severity,
    required this.userMessage,
    this.technicalMessage,
    this.recoverySuggestion,
    this.projectId,
    this.source,
    this.nativeCode,
    this.action,
    Map<String, dynamic>? context,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        context = context ?? {},
        createdAt = createdAt ?? DateTime.now();

  bool get isCritical => severity == AppErrorSeverity.critical;

  bool get isUserRecoverable => action != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'code': code,
      'severity': severity,
      'userMessage': userMessage,
      'technicalMessage': technicalMessage,
      'recoverySuggestion': recoverySuggestion,
      'projectId': projectId,
      'source': source,
      'nativeCode': nativeCode,
      'action': action?.toJson(),
      'context': context,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class AppException implements Exception {
  final AppError error;

  const AppException(this.error);

  @override
  String toString() {
    return error.userMessage;
  }
}
