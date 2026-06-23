import 'dart:convert';

class RenderGraphDiff {
  final bool changed;
  final String reason;
  final int previousHash;
  final int nextHash;

  const RenderGraphDiff({
    required this.changed,
    required this.reason,
    required this.previousHash,
    required this.nextHash,
  });
}

class RenderGraphDiffService {
  int? _lastHash;

  RenderGraphDiff check(
    Map<String, dynamic> graph, {
    required String reason,
  }) {
    final json = jsonEncode(graph);
    final hash = json.hashCode;
    final previous = _lastHash;

    final changed = previous == null || previous != hash;

    if (changed) {
      _lastHash = hash;
    }

    return RenderGraphDiff(
      changed: changed,
      reason: reason,
      previousHash: previous ?? 0,
      nextHash: hash,
    );
  }

  void reset() {
    _lastHash = null;
  }
}
