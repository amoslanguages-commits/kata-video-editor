import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_event.dart';

/// Controls the native preview texture surface for one project.
///
/// Responsibilities:
///  - Creates/disposes the native [SurfaceTexture] via [NativeBridgeContract].
///  - Attaches the texture to the project session on receipt of
///    [NativeEventTypes.previewSurfaceReady].
///  - Listens to [NativeEventTypes.playheadChanged] events and re-renders the
///    placeholder frame so the preview updates during native clock playback.
class NativePreviewTextureController {
  final String projectId;
  final NativeBridgeContract nativeBridge;

  int? _textureId;
  bool _isInitialized = false;
  StreamSubscription<NativeEvent>? _eventSub;

  /// Notifies listeners whenever the Flutter-side textureId changes.
  final ValueNotifier<int?> textureIdNotifier = ValueNotifier<int?>(null);

  NativePreviewTextureController({
    required this.projectId,
    required this.nativeBridge,
  }) {
    _eventSub = nativeBridge.events.listen(_handleNativeEvent);
  }

  int? get textureId => _textureId;
  bool get isInitialized => _isInitialized;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize(int width, int height) async {
    if (_isInitialized) return;

    final result = await nativeBridge.createPreviewTexture(
      projectId: projectId,
      width: width,
      height: height,
    );

    if (!result.accepted) {
      throw StateError(result.message ?? 'Failed to create preview texture.');
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> resize(int width, int height) async {
    final tid = _textureId;
    if (tid == null) return;

    await nativeBridge.resizePreviewTexture(
      textureId: tid,
      width: width,
      height: height,
    );
  }

  Future<void> renderPlaceholder({
    required String label,
    required int playheadMicros,
  }) async {
    final tid = _textureId;
    if (tid == null) return;

    await nativeBridge.renderPreviewPlaceholder(
      textureId: tid,
      label: label,
      playheadMicros: playheadMicros,
    );
  }

  Future<void> dispose() async {
    _eventSub?.cancel();
    _eventSub = null;

    final tid = _textureId;
    if (tid != null) {
      _textureId = null;
      textureIdNotifier.value = null;
      await nativeBridge.disposePreviewTexture(textureId: tid);
    }
  }

  // ── Native event handling ─────────────────────────────────────────────────

  void _handleNativeEvent(NativeEvent event) {
    // Filter events that belong to a different project (if projectId is set)
    if (event.projectId != null && event.projectId != projectId) return;

    switch (event.type) {
      case NativeEventTypes.previewSurfaceReady:
        final tid = event.payload['textureId'];
        if (tid is int) {
          _textureId = tid;
          textureIdNotifier.value = tid;
          _isInitialized = true;

          // Once ready, attach the surface to the project session
          nativeBridge
              .attachPreviewTexture(
                projectId: projectId,
                textureId: tid,
              )
              .ignore();
        }

      case NativeEventTypes.playheadChanged:
        // The native clock ticks at ~60fps; re-render the placeholder so the
        // preview canvas reflects the new playhead position.
        final micros = (event.payload['playheadMicros'] as num?)?.toInt();
        if (micros != null) {
          renderPlaceholder(
            label: 'Native Preview',
            playheadMicros: micros,
          ).ignore();
        }
    }
  }
}
