// 33A-PRO: Audio Engine Foundation — Audio Meter Widget
//
// Real-time VU / peak meter for the master audio output.
// Reads from the audioMeterProvider which is driven by native EventChannel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/audio/nle_audio_meter.dart';
import 'package:nle_editor/presentation/providers/audio_providers.dart';

// ── Master Meter Widget ───────────────────────────────────────────────────────

class AudioMasterMeter extends ConsumerStatefulWidget {
  final String projectId;

  const AudioMasterMeter({super.key, required this.projectId});

  @override
  ConsumerState<AudioMasterMeter> createState() => _AudioMasterMeterState();
}

class _AudioMasterMeterState extends ConsumerState<AudioMasterMeter> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ensureStarted();
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    _started = true;
    await ref
        .read(nativeAudioEngineServiceProvider)
        .startMeterUpdates(widget.projectId);
    if (mounted) {
      ref.read(isMeterActiveProvider(widget.projectId).notifier).state = true;
    }
  }

  @override
  void dispose() {
    ref
        .read(nativeAudioEngineServiceProvider)
        .stopMeterUpdates(widget.projectId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meterAsync = ref.watch(audioMeterProvider(widget.projectId));

    final reading = meterAsync.valueOrNull?.reading ??
        NleAudioMeterReading.silence(widget.projectId);

    return _StereoMeterBar(
      left:  reading.left,
      right: reading.right,
    );
  }
}

// ── Stereo Meter Bar ──────────────────────────────────────────────────────────

class _StereoMeterBar extends StatelessWidget {
  final NleAudioMeterChannel left;
  final NleAudioMeterChannel right;

  const _StereoMeterBar({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ChannelMeter(channel: left,  label: 'L'),
          _ChannelMeter(channel: right, label: 'R'),
        ],
      ),
    );
  }
}

class _ChannelMeter extends StatelessWidget {
  final NleAudioMeterChannel channel;
  final String               label;

  const _ChannelMeter({required this.channel, required this.label});

  @override
  Widget build(BuildContext context) {
    // Map dBFS [-60, 0] → [0, 1]
    final rms  = ((channel.rmsDb  + 60.0) / 60.0).clamp(0.0, 1.0);
    final peak = ((channel.peakDb + 60.0) / 60.0).clamp(0.0, 1.0);

    return SizedBox(
      width: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 8),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 60,
            child: _MeterBar(
              rmsLevel:   rms,
              peakLevel:  peak,
              isClipping: channel.isClipping,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeterBar extends StatelessWidget {
  final double rmsLevel;
  final double peakLevel;
  final bool   isClipping;

  const _MeterBar({
    required this.rmsLevel,
    required this.peakLevel,
    required this.isClipping,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MeterPainter(
        rmsLevel:   rmsLevel,
        peakLevel:  peakLevel,
        isClipping: isClipping,
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double rmsLevel;
  final double peakLevel;
  final bool   isClipping;

  const _MeterPainter({
    required this.rmsLevel,
    required this.peakLevel,
    required this.isClipping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white10,
    );

    // RMS fill — green → yellow → red
    final fillHeight = rmsLevel * size.height;
    final fillTop    = size.height - fillHeight;
    final fillColor  = isClipping
        ? Colors.red
        : rmsLevel > 0.9
            ? Colors.orange
            : rmsLevel > 0.7
                ? Colors.yellow
                : const Color(0xFF29D884);

    if (fillHeight > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, fillTop, size.width, fillHeight),
          const Radius.circular(2),
        ),
        Paint()..color = fillColor,
      );
    }

    // Peak hold line
    if (peakLevel > 0) {
      final peakY = size.height - peakLevel * size.height;
      canvas.drawLine(
        Offset(0, peakY),
        Offset(size.width, peakY),
        Paint()
          ..color       = isClipping ? Colors.red : Colors.white
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.rmsLevel != rmsLevel ||
      old.peakLevel != peakLevel ||
      old.isClipping != isClipping;
}

// ── Compact Volume Indicator ──────────────────────────────────────────────────

/// A simple horizontal bar showing a volume value [0.0, 2.0].
class AudioVolumeIndicator extends StatelessWidget {
  final double volume;
  final double width;
  final double height;

  const AudioVolumeIndicator({
    super.key,
    required this.volume,
    this.width  = 60,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    // Map [0, 2] to [0, 1] for display (unity at 0.5).
    final fill = (volume / 2.0).clamp(0.0, 1.0);
    return SizedBox(
      width:  width,
      height: height,
      child: Stack(
        children: [
          // Track
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:        Colors.white10,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
          // Fill
          Positioned(
            left: 0,
            top:  0,
            bottom: 0,
            width: width * fill,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: volume > 1.05
                    ? Colors.amber
                    : const Color(0xFF29D884),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
          // Unity marker
          Positioned(
            left:   width * 0.5 - 0.5,
            top:    0,
            bottom: 0,
            width:  1,
            child:  const ColoredBox(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}
