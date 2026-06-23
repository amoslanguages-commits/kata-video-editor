import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/device_qa/device_qa_models.dart';
import 'package:nle_editor/presentation/providers/device_qa_controller.dart';

/// Debug panel for 29E: Android Device Compatibility QA.
///
/// Runs device compatibility checks across Android version, codecs,
/// EGL, memory, and thermal state. Shows a full capability summary +
/// per-issue list.
class DeviceQaPanel extends ConsumerWidget {
  const DeviceQaPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state      = ref.watch(deviceQaControllerProvider);
    final controller = ref.read(deviceQaControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        _DeviceQaHeader(report: state.qaReport),
        const SizedBox(height: PremiumSpacing.md),

        // ── Action buttons ───────────────────────────────────────────────────
        Wrap(
          spacing:    PremiumSpacing.sm,
          runSpacing: PremiumSpacing.sm,
          children: [
            _QaActionButton(
              label:   'Full Device QA',
              icon:    Icons.phonelink_setup_rounded,
              running: state.action is DeviceQaRunningFullQa,
              onTap:   state.loading ? null : controller.runFullQa,
            ),
            _QaActionButton(
              label:   'Capabilities Only',
              icon:    Icons.memory_rounded,
              running: state.action is DeviceQaRunningCapabilities,
              onTap:   state.loading ? null : controller.collectCapabilities,
            ),
            _QaActionButton(
              label:   'Memory Probe (128MB)',
              icon:    Icons.speed_rounded,
              running: state.action is DeviceQaRunningMemoryProbe,
              onTap:   state.loading
                  ? null
                  : () => controller.runMemoryProbe(allocateMb: 128),
            ),
            _ClearButton(
              onTap: state.loading ? null : controller.clear,
            ),
          ],
        ),
        const SizedBox(height: PremiumSpacing.md),

        // ── Content ──────────────────────────────────────────────────────────
        if (state.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (state.error != null)
          _ErrorBanner(message: state.error!)
        else if (!state.hasReport &&
            state.capabilityReport == null &&
            state.memoryResult == null)
          const _EmptyState()
        else
          Expanded(
            child: ListView(
              children: [
                // QA Report
                if (state.qaReport != null) ...[
                  _QaReportSection(report: state.qaReport!),
                  const SizedBox(height: PremiumSpacing.lg),
                ],

                // Capability summary (if collected standalone)
                if (state.capabilityReport != null &&
                    state.qaReport == null) ...[
                  _CapabilitySummary(cap: state.capabilityReport!),
                  const SizedBox(height: PremiumSpacing.lg),
                ],

                // Memory probe result
                if (state.memoryResult != null)
                  _MemoryProbeCard(result: state.memoryResult!),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DeviceQaHeader extends StatelessWidget {
  final DeviceQaReport? report;

  const _DeviceQaHeader({this.report});

  @override
  Widget build(BuildContext context) {
    final Color  color;
    final String label;
    final IconData icon;

    if (report == null) {
      color = AppTheme.textMuted;
      label = '29E: Device Compatibility QA';
      icon  = Icons.devices_rounded;
    } else if (report!.passed) {
      color = AppTheme.success;
      label = '29E: Device QA Passed ✓  (${report!.warningCount} warnings)';
      icon  = Icons.verified_rounded;
    } else {
      color = AppTheme.error;
      label = '29E: Device QA Failed — ${report!.failCount} issue(s)';
      icon  = Icons.error_rounded;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:      color,
              fontSize:   15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _QaActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool running;
  final VoidCallback? onTap;

  const _QaActionButton({
    required this.label,
    required this.icon,
    required this.running,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical:   PremiumSpacing.sm,
          horizontal: PremiumSpacing.md,
        ),
        decoration: BoxDecoration(
          color: running
              ? AppTheme.accentPrimary.withOpacity(0.20)
              : onTap != null
                  ? AppTheme.accentPrimary.withOpacity(0.10)
                  : AppTheme.textMuted.withOpacity(0.06),
          borderRadius: BorderRadius.circular(PremiumRadius.md),
          border: Border.all(
            color: running
                ? AppTheme.accentPrimary.withOpacity(0.60)
                : AppTheme.accentPrimary.withOpacity(0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            running
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: AppTheme.accentPrimary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color:      AppTheme.textPrimary,
                fontSize:   12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ClearButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(PremiumSpacing.sm),
        decoration: BoxDecoration(
          color:        AppTheme.error.withOpacity(0.10),
          borderRadius: BorderRadius.circular(PremiumRadius.md),
          border:       Border.all(color: AppTheme.error.withOpacity(0.30)),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: const [
          Icon(Icons.phonelink_off_rounded, color: AppTheme.textMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No device report yet.\nTap "Full Device QA" to run checks.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color:        AppTheme.error.withOpacity(0.10),
        borderRadius: BorderRadius.circular(PremiumRadius.md),
        border:       Border.all(color: AppTheme.error.withOpacity(0.35)),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.error, height: 1.4)),
    );
  }
}

// ── Full QA Report Section ─────────────────────────────────────────────────

class _QaReportSection extends StatelessWidget {
  final DeviceQaReport report;
  const _QaReportSection({required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CapabilitySummary(cap: report.capabilityReport),
        const SizedBox(height: PremiumSpacing.md),
        _SectionLabel(label: 'QA Checks (${report.issues.length})'),
        const SizedBox(height: PremiumSpacing.sm),
        ...report.issues.map((issue) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: _IssueRow(issue: issue),
        )),
      ],
    );
  }
}

class _CapabilitySummary extends StatelessWidget {
  final DeviceCapabilityReport cap;
  const _CapabilitySummary({required this.cap});

  @override
  Widget build(BuildContext context) {
    final tierColor = switch (cap.deviceTier) {
      DeviceTier.lowEnd   => AppTheme.error,
      DeviceTier.midRange => AppTheme.warning,
      DeviceTier.highEnd  => AppTheme.success,
      DeviceTier.unknown  => AppTheme.textMuted,
    };

    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color:        tierColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border:       Border.all(color: tierColor.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smartphone_rounded, color: tierColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${cap.brand} ${cap.model}',
                  style: TextStyle(
                    color:      tierColor,
                    fontSize:   14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        tierColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cap.tierLabel,
                  style: TextStyle(
                    color:      tierColor,
                    fontSize:   11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetaGrid([
            ('Android', '${cap.androidRelease} (SDK ${cap.androidSdk})'),
            ('RAM',     '${cap.totalMemoryMb} MB total · ${cap.availableMemoryMb} MB free'),
            ('CPUs',    '${cap.cpuCoreCount} cores'),
            ('H.264',   cap.codec.hasH264Encoder ? '✅ Encoder' : '❌ No encoder'),
            ('AAC',     cap.codec.hasAacEncoder   ? '✅ Encoder' : '❌ No encoder'),
            ('1080p',   cap.codec.supports1080pExport ? '✅' : '⚠️ Uncertain'),
            ('4K',      cap.codec.supports4kExport ? '✅' : '—'),
            ('EGL',     cap.egl.eglAvailable ? '✅ ${cap.egl.glesVersion}' : '❌ Unavailable'),
            ('Texture', '${cap.egl.maxTextureSize}px max'),
            ('Thermal', cap.thermal.currentStatus),
            ('Preview', cap.recommendation.previewQuality),
            ('Export',  '${cap.recommendation.maxExportWidth}×${cap.recommendation.maxExportHeight} @ ${cap.recommendation.maxFrameRate.toStringAsFixed(0)}fps'),
          ]),
          if (cap.recommendation.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...cap.recommendation.notes.map(
              (n) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $n',
                  style: const TextStyle(
                    color:    AppTheme.textMuted,
                    fontSize: 11,
                    height:   1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  final List<(String, String)> entries;
  const _MetaGrid(this.entries);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing:    PremiumSpacing.md,
      runSpacing: 6,
      children: entries.map((e) => _MetaChip(label: e.$1, value: e.$2)).toList(),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color:      AppTheme.textSecondary,
            fontSize:   11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color:      AppTheme.textSecondary,
        fontSize:   12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final DeviceQaIssue issue;
  const _IssueRow({required this.issue});

  @override
  Widget build(BuildContext context) {
    final Color   color;
    final IconData icon;

    if (issue.isFail) {
      color = AppTheme.error;
      icon  = Icons.cancel_rounded;
    } else if (issue.isWarning) {
      color = AppTheme.warning;
      icon  = Icons.warning_amber_rounded;
    } else {
      color = AppTheme.success;
      icon  = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: PremiumSpacing.md),
      decoration: BoxDecoration(
        color:        const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(PremiumRadius.md),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.id,
                  style: const TextStyle(
                    color:      AppTheme.textSecondary,
                    fontSize:   10,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  issue.message,
                  style: const TextStyle(
                    color:    AppTheme.textPrimary,
                    fontSize: 12,
                    height:   1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Memory Probe Card ─────────────────────────────────────────────────────────

class _MemoryProbeCard extends StatelessWidget {
  final MemoryPressureResult result;
  const _MemoryProbeCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.survived ? AppTheme.success : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border:       Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.survived
                    ? Icons.memory_rounded
                    : Icons.warning_amber_rounded,
                color: color, size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                result.survived
                    ? '🧠 Memory Probe: Survived'
                    : '💥 Memory Probe: OOM',
                style: TextStyle(
                  color:      color,
                  fontWeight: FontWeight.w900,
                  fontSize:   13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(result.message, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            'Allocated: ${result.allocatedMb} MB  |  '
            'Before: ${result.beforeAvailableMb} MB  |  '
            'After: ${result.afterAvailableMb} MB',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
