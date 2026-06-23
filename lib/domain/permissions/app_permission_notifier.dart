import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/domain/services/app_permission_service.dart';

class AppPermissionNotifier
    extends StateNotifier<Map<String, AsyncValue<AppPermissionState>>> {
  final AppPermissionService service;

  AppPermissionNotifier({
    required this.service,
  }) : super({});

  Future<AppPermissionState> check(String type) async {
    state = {
      ...state,
      type: const AsyncValue.loading(),
    };

    try {
      final result = await service.check(type);

      state = {
        ...state,
        type: AsyncValue.data(result),
      };

      return result;
    } catch (e, stack) {
      state = {
        ...state,
        type: AsyncValue.error(e, stack),
      };

      rethrow;
    }
  }

  Future<AppPermissionState> request(
    String type, {
    String? projectId,
    String? source,
  }) async {
    state = {
      ...state,
      type: const AsyncValue.loading(),
    };

    try {
      final result = await service.request(
        type,
        projectId: projectId,
        source: source,
      );

      state = {
        ...state,
        type: AsyncValue.data(result),
      };

      return result;
    } catch (e, stack) {
      state = {
        ...state,
        type: AsyncValue.error(e, stack),
      };

      rethrow;
    }
  }
}
