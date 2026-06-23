import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';

enum TrackControlAction {
  mute,
  solo,
  lock,
  hide,
  rename,
  heightUp,
  heightDown,
  resetHeight,
}

class TimelineTrackHeader extends StatelessWidget {
  final MultitrackTrack track;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<TrackControlAction> onControl;

  const TimelineTrackHeader({
    super.key,
    required this.track,
    required this.selected,
    required this.onTap,
    required this.onControl,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? AppTheme.accentPrimary : AppTheme.borderSubtle;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentPrimary.withValues(alpha: 0.10)
              : const Color(0xFF0D1320),
          border: Border(
            right: BorderSide(color: borderColor),
            bottom: const BorderSide(color: AppTheme.borderSubtle),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showControls = constraints.maxHeight >= 54;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: showControls ? 24 : 20,
                        decoration: BoxDecoration(
                          color: track.color,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: track.color.withValues(alpha: 0.45),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Tooltip(
                          message: track.name,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              if (showControls)
                                Text(
                                  _shortName(track.name),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 8,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      _TrackMenuButton(
                        track: track,
                        onControl: onControl,
                      ),
                    ],
                  ),
                ),
                if (showControls) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeaderButton(
                        label: 'M',
                        tooltip: 'Mute track',
                        active: track.isMuted,
                        onTap: () => onControl(TrackControlAction.mute),
                      ),
                      _HeaderButton(
                        label: 'S',
                        tooltip: 'Solo track',
                        active: track.isSolo,
                        onTap: () => onControl(TrackControlAction.solo),
                      ),
                      _HeaderIconButton(
                        tooltip: track.isLocked ? 'Unlock track' : 'Lock track',
                        icon: track.isLocked
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        active: track.isLocked,
                        activeColor: AppTheme.warning,
                        onTap: () => onControl(TrackControlAction.lock),
                      ),
                      _HeaderIconButton(
                        tooltip: track.isHidden ? 'Show track' : 'Hide track',
                        icon: track.isHidden
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        active: track.isHidden,
                        activeColor: AppTheme.error,
                        onTap: () => onControl(TrackControlAction.hide),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _shortName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Track';
    return clean;
  }
}

class _TrackMenuButton extends StatelessWidget {
  final MultitrackTrack track;
  final ValueChanged<TrackControlAction> onControl;

  const _TrackMenuButton({
    required this.track,
    required this.onControl,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TrackControlAction>(
      padding: EdgeInsets.zero,
      tooltip: 'Track options',
      color: const Color(0xFF111827),
      icon: const Icon(
        Icons.more_horiz_rounded,
        size: 16,
        color: AppTheme.textMuted,
      ),
      onSelected: onControl,
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: TrackControlAction.rename,
            child: _TrackMenuItem(
              icon: Icons.drive_file_rename_outline_rounded,
              label: 'Rename',
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: TrackControlAction.heightUp,
            child: _TrackMenuItem(
              icon: Icons.keyboard_arrow_up_rounded,
              label: 'Taller',
            ),
          ),
          const PopupMenuItem(
            value: TrackControlAction.heightDown,
            child: _TrackMenuItem(
              icon: Icons.keyboard_arrow_down_rounded,
              label: 'Shorter',
            ),
          ),
          const PopupMenuItem(
            value: TrackControlAction.resetHeight,
            child: _TrackMenuItem(
              icon: Icons.restart_alt_rounded,
              label: 'Reset height',
            ),
          ),
        ];
      },
    );
  }
}

class _TrackMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrackMenuItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppTheme.accentPrimary : const Color(0xFF172033),
            borderRadius: BorderRadius.circular(5),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          icon,
          size: 15,
          color: active ? activeColor : AppTheme.textMuted,
        ),
      ),
    );
  }
}
