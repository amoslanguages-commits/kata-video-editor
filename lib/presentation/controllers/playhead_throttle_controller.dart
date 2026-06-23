import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/performance/performance_timers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class PlayheadThrottleController {
  final Ref ref;
  final Throttler _throttler;

  PlayheadThrottleController({
    required this.ref,
    Duration interval = const Duration(milliseconds: 33),
  }) : _throttler = Throttler(interval: interval);

  void onNativePlayhead(int playheadMicros) {
    _throttler.run(() {
      ref.read(editorStateProvider.notifier).setNativePlayhead(playheadMicros);
    });
  }

  void dispose() {
    _throttler.dispose();
  }
}
