import 'package:nle_editor/domain/errors/app_error.dart';
import 'package:nle_editor/domain/errors/app_error_mapper.dart';
import 'package:nle_editor/native_bridge/native_event.dart';

class NativeErrorMapper {
  NativeErrorMapper._();

  static AppError fromNativeEvent(NativeEvent event) {
    final nativeCode = event.payload['code']?.toString();
    final technicalMessage = event.payload['message']?.toString();
    final projectId = event.projectId;

    switch (event.type) {
      case NativeEventTypes.missingFile:
        return AppErrorMapper.originalFileMissing(
          technicalMessage: technicalMessage,
          projectId: projectId,
          source: 'native_engine',
          context: event.payload,
        );

      case NativeEventTypes.decoderError:
        return AppErrorMapper.unsupportedCodec(
          technicalMessage: technicalMessage,
          projectId: projectId,
          source: 'native_decoder',
          context: event.payload,
        );

      case NativeEventTypes.memoryWarning:
        return AppError(
          category: AppErrorCategory.memory,
          code: AppErrorCode.memoryPressure,
          severity: AppErrorSeverity.warning,
          userMessage: 'Memory is getting low, so preview quality may be reduced.',
          technicalMessage: technicalMessage,
          nativeCode: nativeCode,
          recoverySuggestion: 'Close other apps or use proxy preview.',
          projectId: projectId,
          source: 'native_engine',
          context: event.payload,
        );

      case NativeEventTypes.thermalWarning:
        return AppError(
          category: AppErrorCategory.nativeEngine,
          code: 'thermal_warning',
          severity: AppErrorSeverity.warning,
          userMessage: 'Your phone is getting warm, so performance may be reduced.',
          technicalMessage: technicalMessage,
          nativeCode: nativeCode,
          recoverySuggestion: 'Let the device cool or use draft preview quality.',
          projectId: projectId,
          source: 'native_engine',
          context: event.payload,
        );

      case NativeEventTypes.exportFailed:
        return AppErrorMapper.exportFailed(
          technicalMessage: technicalMessage,
          projectId: projectId,
          source: 'native_export',
          context: event.payload,
        );

      case NativeEventTypes.proxyFailed:
        return AppErrorMapper.proxyFailed(
          technicalMessage: technicalMessage,
          projectId: projectId,
          source: 'native_proxy',
          context: event.payload,
        );

      case NativeEventTypes.engineError:
      default:
        return AppErrorMapper.nativeEngineFailed(
          technicalMessage: technicalMessage,
          nativeCode: nativeCode,
          projectId: projectId,
          source: 'native_engine',
          context: event.payload,
        );
    }
  }
}
