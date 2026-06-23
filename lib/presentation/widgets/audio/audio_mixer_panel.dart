import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/presentation/providers/audio_providers.dart';
import 'package:nle_editor/presentation/controllers/track_controls_controller.dart';
import 'package:nle_editor/presentation/providers/editor_history_providers.dart';
import 'package:nle_editor/data/repositories/track_controls_repository.dart';
import 'package:nle_editor/domain/timeline/track_graph_refresh_bridge.dart';
import 'package:nle_editor/presentation/widgets/audio/audio_meter_widget.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/track_controls_providers.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_track_header.dart';

class AudioMixerPanel extends ConsumerWidget {
  final String projectId;

  const AudioMixerPanel({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(projectAudioTracksProvider(projectId));

    return Container(
      color: AppTheme.editorBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppTheme.textMuted, size: 16),
                SizedBox(width: 8),
                Text(
                  'AUDIO MIXER',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          // Mixer Area
          Expanded(
            child: tracksAsync.when(
              data: (tracks) {
                if (tracks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Audio Tracks Available',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Individual Channels
                      ...tracks.map((track) => _MixerChannelStrip(
                            projectId: projectId,
                            track: track,
                          )),
                      
                      const SizedBox(width: 24),
                      
                      // Master Bus separator
                      Container(
                        width: 1,
                        color: AppTheme.borderSubtle,
                      ),
                      
                      const SizedBox(width: 24),
                      
                      // Master Bus Channel
                      _MasterBusStrip(projectId: projectId),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppTheme.error))),
            ),
          ),
        ],
      ),
    );
  }
}

class _MixerChannelStrip extends ConsumerStatefulWidget {
  final String projectId;
  final db.Track track;

  const _MixerChannelStrip({
    required this.projectId,
    required this.track,
  });

  @override
  ConsumerState<_MixerChannelStrip> createState() => _MixerChannelStripState();
}

class _MixerChannelStripState extends ConsumerState<_MixerChannelStrip> {
  late double _localVolume;

  @override
  void initState() {
    super.initState();
    _localVolume = widget.track.volume;
  }

  @override
  void didUpdateWidget(covariant _MixerChannelStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.volume != widget.track.volume) {
      _localVolume = widget.track.volume;
    }
  }

  void _updateVolume(double value) {
    setState(() => _localVolume = value);
  }

  Future<void> _commitVolume(double value) async {
    final dbInstance = ref.read(databaseProvider);
    await dbInstance.setTrackVolume(
      trackId: widget.track.id,
      volume: value,
    );
    await ref.read(trackGraphRefreshBridgeProvider).refreshAfterTrackChange(
      projectId: widget.projectId,
      reason: 'mixer_volume_changed',
    );
  }

  Future<void> _toggleMute() async {
    final controller = _getTrackController();
    await controller.performAction(
      trackId: widget.track.id,
      action: TrackControlAction.mute,
    );
  }

  Future<void> _toggleSolo() async {
    final controller = _getTrackController();
    await controller.performAction(
      trackId: widget.track.id,
      action: TrackControlAction.solo,
    );
  }

  TrackControlsController _getTrackController() {
    return ref.read(trackControlsControllerProvider(widget.projectId));
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = widget.track.isMuted;
    final isSolo = widget.track.isSolo;

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161A20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          // Track Name
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
              color: Color(0xFF1E232B),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.track.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Mute / Solo buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MixerButton(
                label: 'M',
                isActive: isMuted,
                activeColor: Colors.redAccent,
                onTap: _toggleMute,
              ),
              const SizedBox(width: 8),
              _MixerButton(
                label: 'S',
                isActive: isSolo,
                activeColor: Colors.amber,
                onTap: _toggleSolo,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Volume Fader
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: AppTheme.accentPrimary,
                  inactiveTrackColor: Colors.black54,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _localVolume,
                  min: 0.0,
                  max: 2.0,
                  onChanged: _updateVolume,
                  onChangeEnd: _commitVolume,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Value readout
          Text(
            (_localVolume * 100).toInt().toString(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MixerButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _MixerButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withAlpha(40) : Colors.black38,
          border: Border.all(
            color: isActive ? activeColor : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MasterBusStrip extends StatelessWidget {
  final String projectId;

  const _MasterBusStrip({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF101419),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF29D884).withAlpha(100)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
              color: Color(0xFF1E232B),
            ),
            alignment: Alignment.center,
            child: const Text(
              'MASTER',
              style: TextStyle(
                color: Color(0xFF29D884),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AudioMasterMeter(projectId: projectId),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
