import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:photo_manager/photo_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:nle_editor/domain/errors/app_error_mapper.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/domain/services/error_reporting_service.dart';

class AppPermissionService {
  final ErrorReportingService errorReportingService;

  AppPermissionService({
    required this.errorReportingService,
  });

  int? _androidApiLevel;

  Future<int> _getAndroidApiLevel() async {
    if (!Platform.isAndroid) return 1000;
    if (_androidApiLevel != null) return _androidApiLevel!;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _androidApiLevel = androidInfo.version.sdkInt;
    } catch (e) {
      _androidApiLevel = 33; // Default to 13+ if it fails
    }
    return _androidApiLevel!;
  }

  Future<ph.Permission> _getMediaPermission(ph.Permission granularPermission) async {
    final apiLevel = await _getAndroidApiLevel();
    if (apiLevel < 33) {
      return ph.Permission.storage;
    }
    return granularPermission;
  }

  Future<AppPermissionState> check(String type) async {
    switch (type) {
      case AppPermissionType.mediaLibrary:
        return _checkMediaLibrary();

      case AppPermissionType.gallerySave:
        return _checkGallerySave();

      case AppPermissionType.microphone:
        return _checkPermissionHandler(
          type: type,
          permission: ph.Permission.microphone,
        );

      case AppPermissionType.notifications:
        return _checkPermissionHandler(
          type: type,
          permission: ph.Permission.notification,
        );

      case AppPermissionType.mediaImages:
        return _checkPermissionHandler(
          type: type,
          permission: await _getMediaPermission(ph.Permission.photos),
        );

      case AppPermissionType.mediaVideos:
        return _checkPermissionHandler(
          type: type,
          permission: await _getMediaPermission(ph.Permission.videos),
        );

      case AppPermissionType.mediaAudio:
        return _checkPermissionHandler(
          type: type,
          permission: await _getMediaPermission(ph.Permission.audio),
        );

      default:
        return AppPermissionState.unknown(type).copyWith(
          status: AppPermissionStatusValue.notSupported,
          canRequestAgain: false,
        );
    }
  }

  Future<AppPermissionState> request(
    String type, {
    String? projectId,
    String? source,
    bool reportIfDenied = true,
  }) async {
    switch (type) {
      case AppPermissionType.mediaLibrary:
        return _requestMediaLibrary(
          projectId: projectId,
          source: source,
          reportIfDenied: reportIfDenied,
        );

      case AppPermissionType.gallerySave:
        return _requestGallerySave(
          projectId: projectId,
          source: source,
          reportIfDenied: reportIfDenied,
        );

      case AppPermissionType.microphone:
        return _requestPermissionHandler(
          type: type,
          permission: ph.Permission.microphone,
          projectId: projectId,
          source: source,
          reportIfDenied: reportIfDenied,
        );

      case AppPermissionType.notifications:
        return _requestPermissionHandler(
          type: type,
          permission: ph.Permission.notification,
          projectId: projectId,
          source: source,
          reportIfDenied: reportIfDenied,
        );

      case AppPermissionType.mediaImages:
        return _requestPermissionHandler(
          type: type,
          permission: await _getMediaPermission(ph.Permission.photos),
          projectId: projectId,
          source: source,
          reportIfDenied: reportIfDenied,
        );

      case AppPermissionType.mediaVideos:
        return _requestPermissionHandler(
          type: type,
          permission: await _getMediaPermission(ph.Permission.videos),
          projectId: projectId,
          source: source,
          reportIfDenied: reportIfDenied,
        );

      case AppPermissionType.mediaAudio:
        return _requestPermissionHandler(
          type: type,
          permission: await _getMediaPermission(ph.Permission.audio),
          projectId: projectId,
          source: source,
          reportIfDenied: reportIfDenied,
        );

      default:
        final state = AppPermissionState.unknown(type).copyWith(
          status: AppPermissionStatusValue.notSupported,
          canRequestAgain: false,
        );

        return state;
    }
  }

  Future<AppPermissionState> ensure(
    String type, {
    String? projectId,
    String? source,
  }) async {
    final current = await check(type);

    if (current.hasAccess) {
      return current;
    }

    return request(
      type,
      projectId: projectId,
      source: source,
    );
  }

  Future<bool> ensureHasAccess(
    String type, {
    String? projectId,
    String? source,
  }) async {
    final state = await ensure(
      type,
      projectId: projectId,
      source: source,
    );

    return state.hasAccess;
  }

  Future<bool> openSettings() {
    return ph.openAppSettings();
  }

  Future<void> openPhotoManagerSettings() async {
    await PhotoManager.openSetting();
  }

  Future<void> presentLimitedMediaPicker() async {
    await PhotoManager.presentLimited();
  }

  Future<AppPermissionState> _checkMediaLibrary() async {
    final ps = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );

    return _mapPhotoManagerState(
      type: AppPermissionType.mediaLibrary,
      state: ps,
    );
  }

  Future<AppPermissionState> _requestMediaLibrary({
    String? projectId,
    String? source,
    bool reportIfDenied = true,
  }) async {
    final ps = await PhotoManager.requestPermissionExtend();

    final state = _mapPhotoManagerState(
      type: AppPermissionType.mediaLibrary,
      state: ps,
    );

    if (!state.hasAccess && reportIfDenied) {
      await errorReportingService.report(
        AppErrorMapper.mediaPermissionDenied(
          projectId: projectId,
          source: source ?? 'permission_service',
          technicalMessage: 'PhotoManager permission state: ${ps.name}',
        ),
      );
    }

    return state;
  }

  Future<AppPermissionState> _checkGallerySave() async {
    final ps = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );

    return _mapPhotoManagerState(
      type: AppPermissionType.gallerySave,
      state: ps,
    );
  }

  Future<AppPermissionState> _requestGallerySave({
    String? projectId,
    String? source,
    bool reportIfDenied = true,
  }) async {
    final ps = await PhotoManager.requestPermissionExtend();

    final state = _mapPhotoManagerState(
      type: AppPermissionType.gallerySave,
      state: ps,
    );

    if (!state.hasAccess && reportIfDenied) {
      await errorReportingService.report(
        AppErrorMapper.permissionDenied(
          projectId: projectId,
          source: source ?? 'permission_service',
          technicalMessage: 'Gallery save permission state: ${ps.name}',
        ),
      );
    }

    return state;
  }

  AppPermissionState _mapPhotoManagerState({
    required String type,
    required PermissionState state,
  }) {
    final status = state.isAuth
        ? AppPermissionStatusValue.granted
        : state == PermissionState.limited || state.hasAccess
            ? AppPermissionStatusValue.limited
            : AppPermissionStatusValue.denied;

    final hasAccess = state.isAuth || state.hasAccess;

    return AppPermissionState(
      type: type,
      status: status,
      canRequestAgain: !hasAccess,
      shouldOpenSettings: false, // Let the OS prompt first. PhotoManager will just fail if permanently denied.
      hasLimitedAccess: status == AppPermissionStatusValue.limited,
      checkedAt: DateTime.now(),
      platformRawStatus: state.name,
    );
  }

  Future<AppPermissionState> _checkPermissionHandler({
    required String type,
    required ph.Permission permission,
  }) async {
    final status = await permission.status;

    return _mapPermissionHandlerStatus(
      type: type,
      status: status,
    );
  }

  Future<AppPermissionState> _requestPermissionHandler({
    required String type,
    required ph.Permission permission,
    String? projectId,
    String? source,
    bool reportIfDenied = true,
  }) async {
    final status = await permission.request();

    final state = _mapPermissionHandlerStatus(
      type: type,
      status: status,
    );

    if (!state.hasAccess && reportIfDenied) {
      await errorReportingService.report(
        AppErrorMapper.permissionDenied(
          projectId: projectId,
          source: source ?? 'permission_service',
          technicalMessage: 'Permission $type status: ${status.name}',
        ),
      );
    }

    return state;
  }

  AppPermissionState _mapPermissionHandlerStatus({
    required String type,
    required ph.PermissionStatus status,
  }) {
    String appStatus;

    if (status.isGranted) {
      appStatus = AppPermissionStatusValue.granted;
    } else if (status.isLimited) {
      appStatus = AppPermissionStatusValue.limited;
    } else if (status.isPermanentlyDenied) {
      appStatus = AppPermissionStatusValue.permanentlyDenied;
    } else if (status.isRestricted) {
      appStatus = AppPermissionStatusValue.restricted;
    } else if (status.isDenied) {
      appStatus = AppPermissionStatusValue.denied;
    } else {
      appStatus = AppPermissionStatusValue.unknown;
    }

    return AppPermissionState(
      type: type,
      status: appStatus,
      canRequestAgain: status.isDenied,
      shouldOpenSettings: status.isPermanentlyDenied || status.isRestricted,
      hasLimitedAccess: status.isLimited,
      checkedAt: DateTime.now(),
      platformRawStatus: status.name,
    );
  }
}
