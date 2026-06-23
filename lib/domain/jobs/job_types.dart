class JobTypes {
  JobTypes._();

  static const String thumbnail = 'thumbnail';
  static const String waveform = 'waveform';
  static const String proxy = 'proxy';
  static const String export = 'export';
  static const String cacheCleanup = 'cache_cleanup';
  static const String mediaScan = 'media_scan';
}

class JobStatus {
  JobStatus._();

  static const String queued = 'queued';
  static const String waiting = 'waiting';
  static const String running = 'running';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';
  static const String paused = 'paused';
}
