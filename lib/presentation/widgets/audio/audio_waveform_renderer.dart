// 33A-PRO: Audio Engine Foundation — Waveform Renderer Widget
//
// A CustomPainter-based widget that renders audio waveform peak data
// as a filled, mirrored waveform typical of professional DAW timelines.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/presentation/providers/audio_providers.dart';

// ── Public Widget ─────────────────────────────────────────────────────────────

class AudioWaveformRenderer extends ConsumerWidget {
  final String  assetId;
  final Color   waveformColor;
  final Color   backgroundColor;
  final double  height;

  const AudioWaveformRenderer({
    super.key,
    required this.assetId,
    this.waveformColor   = const Color(0xFF29D884),
    this.backgroundColor = Colors.transparent,
    this.height          = 48,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheAsync = ref.watch(assetWaveformCacheProvider(assetId));

    return cacheAsync.when(
      loading: () => _placeholder(height, backgroundColor),
      error:   (_, __) => _errorPlaceholder(height),
      data:    (cache) {
        if (cache == null || cache.status == 'pending') {
          return _placeholder(height, backgroundColor);
        }
        if (cache.status == 'error') {
          return _errorPlaceholder(height);
        }

        final samples = _parseSamples(cache);
        if (samples.isEmpty) {
          return _placeholder(height, backgroundColor);
        }

        return SizedBox(
          height: height,
          child: CustomPaint(
            painter: _WaveformPainter(
              samples:         samples,
              waveformColor:   waveformColor,
              backgroundColor: backgroundColor,
            ),
          ),
        );
      },
    );
  }

  List<double> _parseSamples(db.AudioWaveformCache cache) {
    if (cache.samplesJson == null) return [];
    try {
      final list = jsonDecode(cache.samplesJson!) as List<dynamic>;
      return list.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return [];
    }
  }

  Widget _placeholder(double h, Color bg) {
    return Container(
      height: h,
      color: bg,
      child: const Center(
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          minHeight: 2,
        ),
      ),
    );
  }

  Widget _errorPlaceholder(double h) {
    return SizedBox(
      height: h,
      child: const Center(
        child: Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color        waveformColor;
  final Color        backgroundColor;

  const _WaveformPainter({
    required this.samples,
    required this.waveformColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final wavePaint = Paint()
      ..color = waveformColor
      ..style = PaintingStyle.fill;

    final midY     = size.height / 2;
    final colWidth = size.width / samples.length;

    for (var i = 0; i < samples.length; i++) {
      final amplitude = samples[i].abs().clamp(0.0, 1.0);
      final half      = amplitude * midY;

      final x    = i * colWidth;
      final rect = Rect.fromLTRB(
        x,
        midY - half,
        x + math.max(colWidth - 0.5, 0.5),
        midY + half,
      );
      canvas.drawRect(rect, wavePaint);
    }

    // Centre line
    final linePaint = Paint()
      ..color = waveformColor.withAlpha(40)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter old) {
    return old.samples != samples ||
        old.waveformColor != waveformColor ||
        old.backgroundColor != backgroundColor;
  }
}

// ── Inline samples renderer (for quick previews without DB) ───────────────────

class AudioWaveformInline extends StatelessWidget {
  final List<double> samples;
  final Color        color;
  final double       height;

  const AudioWaveformInline({
    super.key,
    required this.samples,
    this.color  = const Color(0xFF29D884),
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _WaveformPainter(
          samples:         samples,
          waveformColor:   color,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
