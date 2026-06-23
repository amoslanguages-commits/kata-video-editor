import 'dart:collection';

class LruCacheEntry<T> {
  final String key;
  final T value;
  final int costBytes;
  final DateTime createdAt;

  LruCacheEntry({
    required this.key,
    required this.value,
    required this.costBytes,
    required this.createdAt,
  });
}

class LruMemoryCache<T> {
  final int maxCostBytes;
  final void Function(T value)? onEvict;

  final _entries = LinkedHashMap<String, LruCacheEntry<T>>();

  int _currentCostBytes = 0;

  LruMemoryCache({
    required this.maxCostBytes,
    this.onEvict,
  });

  int get currentCostBytes => _currentCostBytes;
  int get length => _entries.length;
  bool get isEmpty => _entries.isEmpty;

  T? get(String key) {
    final entry = _entries.remove(key);

    if (entry == null) return null;

    _entries[key] = entry;

    return entry.value;
  }

  void put({
    required String key,
    required T value,
    required int costBytes,
  }) {
    remove(key);

    final entry = LruCacheEntry<T>(
      key: key,
      value: value,
      costBytes: costBytes,
      createdAt: DateTime.now(),
    );

    _entries[key] = entry;
    _currentCostBytes += costBytes;

    _trim();
  }

  void remove(String key) {
    final removed = _entries.remove(key);

    if (removed == null) return;

    _currentCostBytes -= removed.costBytes;
    onEvict?.call(removed.value);
  }

  void clear() {
    if (onEvict != null) {
      for (final entry in _entries.values) {
        onEvict!(entry.value);
      }
    }

    _entries.clear();
    _currentCostBytes = 0;
  }

  void reduceTo(int newMaxCostBytes) {
    while (_currentCostBytes > newMaxCostBytes && _entries.isNotEmpty) {
      final firstKey = _entries.keys.first;
      remove(firstKey);
    }
  }

  void _trim() {
    while (_currentCostBytes > maxCostBytes && _entries.isNotEmpty) {
      final firstKey = _entries.keys.first;
      remove(firstKey);
    }
  }
}
