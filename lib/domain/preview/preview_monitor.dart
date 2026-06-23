// lib/domain/preview/preview_monitor.dart

/// 29F: Identifies which preview monitor is in use.
///
/// SOURCE  = raw media from the media bin (in/out point picker).
/// PROGRAM = final edited timeline preview.
enum PreviewMonitor {
  source,
  program,
}

extension PreviewMonitorX on PreviewMonitor {
  String get commandValue {
    switch (this) {
      case PreviewMonitor.source:
        return 'source';
      case PreviewMonitor.program:
        return 'program';
    }
  }

  String get label {
    switch (this) {
      case PreviewMonitor.source:
        return 'Source';
      case PreviewMonitor.program:
        return 'Program';
    }
  }

  static PreviewMonitor fromRaw(String? raw) {
    if (raw == 'source') return PreviewMonitor.source;
    return PreviewMonitor.program;
  }
}
