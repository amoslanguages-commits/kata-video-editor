import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({
    required this.delay,
  });

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  Future<void> runAsync(Future<void> Function() action) async {
    _timer?.cancel();

    final completer = Completer<void>();

    _timer = Timer(delay, () async {
      try {
        await action();
        if (!completer.isCompleted) completer.complete();
      } catch (e, stack) {
        if (!completer.isCompleted) completer.completeError(e, stack);
      }
    });

    return completer.future;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}

class Throttler {
  final Duration interval;

  DateTime? _lastRun;
  Timer? _trailingTimer;
  void Function()? _trailingAction;

  Throttler({
    required this.interval,
  });

  void run(
    void Function() action, {
    bool trailing = true,
  }) {
    final now = DateTime.now();

    if (_lastRun == null || now.difference(_lastRun!) >= interval) {
      _lastRun = now;
      action();
      return;
    }

    if (!trailing) return;

    _trailingAction = action;
    _trailingTimer?.cancel();

    final remaining = interval - now.difference(_lastRun!);

    _trailingTimer = Timer(remaining, () {
      _lastRun = DateTime.now();
      final pending = _trailingAction;
      _trailingAction = null;
      pending?.call();
    });
  }

  void cancel() {
    _trailingTimer?.cancel();
    _trailingTimer = null;
    _trailingAction = null;
  }

  void dispose() {
    cancel();
  }
}
