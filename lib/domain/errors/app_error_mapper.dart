import 'dart:io';

import 'package:nle_editor/domain/errors/app_error.dart';

class AppErrorMapper {
  AppErrorMapper._();

  static AppError fromException(
    Object exception, {
    StackTrace? stackTrace,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    if (exception is AppException) {
      return exception.error;
    }

    final message = exception.toString();

    if (exception is FileSystemException) {
      return storageWriteFailed(
        technicalMessage: message,
        projectId: projectId,
        source: source,
        context: context,
      );
    }

    final lower = message.toLowerCase();

    if (lower.contains('permission')) {
      return permissionDenied(
        technicalMessage: message,
        projectId: projectId,
        source: source,
        context: context,
      );
    }

    if (lower.contains('no such file') ||
        lower.contains('not found') ||
        lower.contains('missing')) {
      return originalFileMissing(
        technicalMessage: message,
        projectId: projectId,
        source: source,
        context: context,
      );
    }

    if (lower.contains('codec') || lower.contains('format')) {
      return unsupportedCodec(
        technicalMessage: message,
        projectId: projectId,
        source: source,
        context: context,
      );
    }

    if (lower.contains('storage') ||
        lower.contains('space') ||
        lower.contains('disk')) {
      return storageLow(
        technicalMessage: message,
        projectId: projectId,
        source: source,
        context: context,
      );
    }

    return unknown(
      technicalMessage: message,
      projectId: projectId,
      source: source,
      context: {
        ...?context,
        'stackTrace': stackTrace?.toString(),
      },
    );
  }

  static AppError permissionDenied({
    String? technicalMessage,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      category: AppErrorCategory.permission,
      code: AppErrorCode.permissionDenied,
      severity: AppErrorSeverity.warning,
      userMessage: 'Permission is needed to continue.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Allow access in settings, then try again.',
      projectId: projectId,
      source: source,
      context: context,
      action: const AppErrorAction(
        label: 'Open Settings',
        actionId: AppErrorActionId.openSettings,
      ),
    );
  }

  static AppError mediaPermissionDenied({
    String? projectId,
    String? source,
    String? technicalMessage,
  }) {
    return AppError(
      category: AppErrorCategory.permission,
      code: AppErrorCode.mediaPermissionDenied,
      severity: AppErrorSeverity.warning,
      userMessage: 'To import your videos, allow access to your media library.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Open settings and allow media access.',
      projectId: projectId,
      source: source,
      action: const AppErrorAction(
        label: 'Open Settings',
        actionId: AppErrorActionId.openSettings,
      ),
    );
  }

  static AppError originalFileMissing({
    String? technicalMessage,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      category: AppErrorCategory.missingFile,
      code: AppErrorCode.originalFileMissing,
      severity: AppErrorSeverity.error,
      userMessage: 'The original media file is missing.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Reconnect the file or remove the missing clip.',
      projectId: projectId,
      source: source,
      context: context,
      action: const AppErrorAction(
        label: 'Reconnect',
        actionId: AppErrorActionId.reconnectMedia,
      ),
    );
  }

  static AppError unsupportedCodec({
    String? technicalMessage,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      category: AppErrorCategory.unsupportedCodec,
      code: AppErrorCode.unsupportedVideoCodec,
      severity: AppErrorSeverity.error,
      userMessage: 'This video format is not supported on your device.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Try converting the video or export using H.264.',
      projectId: projectId,
      source: source,
      context: context,
      action: const AppErrorAction(
        label: 'Use H.264',
        actionId: AppErrorActionId.useH264,
      ),
    );
  }

  static AppError unsupportedHevc({
    String? technicalMessage,
    String? projectId,
    String? source,
  }) {
    return AppError(
      category: AppErrorCategory.unsupportedCodec,
      code: AppErrorCode.unsupportedHevc,
      severity: AppErrorSeverity.warning,
      userMessage: 'HEVC is not safe on this device.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Use H.264 for better compatibility.',
      projectId: projectId,
      source: source,
      action: const AppErrorAction(
        label: 'Use H.264',
        actionId: AppErrorActionId.useH264,
      ),
    );
  }

  static AppError storageLow({
    String? technicalMessage,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      category: AppErrorCategory.storage,
      code: AppErrorCode.storageLow,
      severity: AppErrorSeverity.warning,
      userMessage: 'Storage is low. Export or proxy generation may fail.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Clear cache, delete unused files, or export at lower quality.',
      projectId: projectId,
      source: source,
      context: context,
      action: const AppErrorAction(
        label: 'Clear Cache',
        actionId: AppErrorActionId.clearCache,
      ),
    );
  }

  static AppError storageWriteFailed({
    String? technicalMessage,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      category: AppErrorCategory.storage,
      code: AppErrorCode.storageWriteFailed,
      severity: AppErrorSeverity.error,
      userMessage: 'The app could not write to storage.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Check storage permission and free space.',
      projectId: projectId,
      source: source,
      context: context,
      action: const AppErrorAction(
        label: 'Free Storage',
        actionId: AppErrorActionId.freeStorage,
      ),
    );
  }

  static AppError exportFailed({
    String? technicalMessage,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      category: AppErrorCategory.export,
      code: AppErrorCode.exportFailed,
      severity: AppErrorSeverity.error,
      userMessage: 'Export failed.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Try again, lower export quality, or use H.264.',
      projectId: projectId,
      source: source,
      context: context,
      action: const AppErrorAction(
        label: 'Lower Quality',
        actionId: AppErrorActionId.lowerExportQuality,
      ),
    );
  }

  static AppError exportOriginalMissing({
    String? technicalMessage,
    String? projectId,
    String? source,
  }) {
    return AppError(
      category: AppErrorCategory.export,
      code: AppErrorCode.exportOriginalMissing,
      severity: AppErrorSeverity.error,
      userMessage: 'Export cannot continue because an original file is missing.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Reconnect the missing file, then export again.',
      projectId: projectId,
      source: source,
      action: const AppErrorAction(
        label: 'Reconnect',
        actionId: AppErrorActionId.reconnectMedia,
      ),
    );
  }

  static AppError proxyFailed({
    String? technicalMessage,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      category: AppErrorCategory.proxy,
      code: AppErrorCode.proxyFailed,
      severity: AppErrorSeverity.warning,
      userMessage: 'Proxy generation failed.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'You can retry or continue editing at lower preview quality.',
      projectId: projectId,
      source: source,
      context: context,
      action: const AppErrorAction(
        label: 'Retry',
        actionId: AppErrorActionId.retry,
      ),
    );
  }

  static AppError thumbnailFailed({
    String? technicalMessage,
    String? projectId,
    String? source,
  }) {
    return AppError(
      category: AppErrorCategory.thumbnail,
      code: AppErrorCode.thumbnailFailed,
      severity: AppErrorSeverity.info,
      userMessage: 'Thumbnail generation failed.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Editing can continue. The app will show a placeholder.',
      projectId: projectId,
      source: source,
    );
  }

  static AppError waveformFailed({
    String? technicalMessage,
    String? projectId,
    String? source,
  }) {
    return AppError(
      category: AppErrorCategory.waveform,
      code: AppErrorCode.waveformFailed,
      severity: AppErrorSeverity.info,
      userMessage: 'Waveform generation failed.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Editing can continue. Audio may show without waveform.',
      projectId: projectId,
      source: source,
    );
  }

  static AppError invalidTimelineEdit({
    String? technicalMessage,
    String? projectId,
    String? source,
  }) {
    return AppError(
      category: AppErrorCategory.timeline,
      code: AppErrorCode.timelineInvalidEdit,
      severity: AppErrorSeverity.warning,
      userMessage: 'This timeline edit is not possible.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Try moving the clip or choosing a different edit point.',
      projectId: projectId,
      source: source,
    );
  }

  static AppError transitionNotEnoughMedia({
    String? technicalMessage,
    String? projectId,
    String? source,
  }) {
    return AppError(
      category: AppErrorCategory.timeline,
      code: AppErrorCode.transitionNotEnoughMedia,
      severity: AppErrorSeverity.warning,
      userMessage: 'Not enough media for this transition.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Trim the clips to create extra handles, then try again.',
      projectId: projectId,
      source: source,
    );
  }

  static AppError renderGraphBuildFailed({
    String? technicalMessage,
    String? projectId,
    String? source,
  }) {
    return AppError(
      category: AppErrorCategory.renderGraph,
      code: AppErrorCode.renderGraphBuildFailed,
      severity: AppErrorSeverity.error,
      userMessage: 'The project graph could not be prepared.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Save the project and reopen it.',
      projectId: projectId,
      source: source,
    );
  }

  static AppError nativeEngineFailed({
    String? technicalMessage,
    String? nativeCode,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      category: AppErrorCategory.nativeEngine,
      code: AppErrorCode.nativeEngineFailed,
      severity: AppErrorSeverity.error,
      userMessage: 'The video engine had a problem.',
      technicalMessage: technicalMessage,
      nativeCode: nativeCode,
      recoverySuggestion: 'Try again or lower preview/export quality.',
      projectId: projectId,
      source: source,
      context: context,
      action: const AppErrorAction(
        label: 'Retry',
        actionId: AppErrorActionId.retry,
      ),
    );
  }

  static AppError databaseFailed({
    String? technicalMessage,
    String? projectId,
    String? source,
  }) {
    return AppError(
      category: AppErrorCategory.database,
      code: AppErrorCode.databaseFailed,
      severity: AppErrorSeverity.error,
      userMessage: 'The project database could not be updated.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Try again. If it continues, restart the app.',
      projectId: projectId,
      source: source,
    );
  }

  static AppError unknown({
    String? technicalMessage,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      category: AppErrorCategory.unknown,
      code: AppErrorCode.unknown,
      severity: AppErrorSeverity.error,
      userMessage: 'Something went wrong.',
      technicalMessage: technicalMessage,
      recoverySuggestion: 'Try again. If it continues, restart the app.',
      projectId: projectId,
      source: source,
      context: context,
    );
  }
}
