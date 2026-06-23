import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:nle_editor/core/performance/lru_memory_cache.dart';

class ThumbnailMemoryCache {
  final LruMemoryCache<ui.Image> _cache;

  ThumbnailMemoryCache({
    int maxBytes = 96 * 1024 * 1024,
  }) : _cache = LruMemoryCache<ui.Image>(
          maxCostBytes: maxBytes,
          onEvict: (image) => image.dispose(),
        );

  ui.Image? get(String key) => _cache.get(key);

  void put({
    required String key,
    required ui.Image image,
  }) {
    final cost = image.width * image.height * 4;

    _cache.put(
      key: key,
      value: image,
      costBytes: cost,
    );
  }

  void clear() => _cache.clear();

  void enterLowMemoryMode() {
    _cache.reduceTo(24 * 1024 * 1024);
  }
}

class WaveformMemoryCache {
  final LruMemoryCache<Float32List> _cache;

  WaveformMemoryCache({
    int maxBytes = 32 * 1024 * 1024,
  }) : _cache = LruMemoryCache<Float32List>(
          maxCostBytes: maxBytes,
        );

  Float32List? get(String key) => _cache.get(key);

  void put({
    required String key,
    required Float32List samples,
  }) {
    _cache.put(
      key: key,
      value: samples,
      costBytes: samples.lengthInBytes,
    );
  }

  void clear() => _cache.clear();

  void enterLowMemoryMode() {
    _cache.reduceTo(8 * 1024 * 1024);
  }
}
