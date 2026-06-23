import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/rendering/render_graph_validator.dart';
import 'package:nle_editor/presentation/providers/multitrack_render_graph_providers.dart';

class RenderGraphDebugViewer extends ConsumerWidget {
  final String projectId;

  const RenderGraphDebugViewer({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphAsync = ref.watch(projectRenderGraphJsonProvider(projectId));
    final validationAsync = ref.watch(projectRenderGraphValidationProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Validation Status Header ─────────────────────────────────────
        validationAsync.when(
          loading: () => const _StatusLoadingBanner(),
          error: (err, _) => _StatusErrorBanner(message: 'Validation failed: $err'),
          data: (result) => _ValidationResultBanner(result: result),
        ),

        // ── 2. JSON Body ────────────────────────────────────────────────────
        Expanded(
          child: graphAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (err, _) => Center(
              child: Text(
                'Failed to load graph JSON: $err',
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
            data: (jsonMap) {
              final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonMap);

              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(PremiumSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.all(PremiumSpacing.md),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(PremiumRadius.sm),
                          border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
                        ),
                        child: SelectableText(
                          prettyJson,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: PremiumSpacing.lg,
                    right: PremiumSpacing.lg,
                    child: _CopyButton(text: prettyJson),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _StatusLoadingBanner extends StatelessWidget {
  const _StatusLoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      margin: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(PremiumRadius.xs),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          SizedBox(width: PremiumSpacing.md),
          Text(
            'Validating render graph...',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatusErrorBanner extends StatelessWidget {
  final String message;

  const _StatusErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      margin: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(PremiumRadius.xs),
        border: Border.all(color: AppTheme.error.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: PremiumSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppTheme.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationResultBanner extends StatelessWidget {
  final RenderGraphValidationResult result;

  const _ValidationResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final issues = result.issues;

    if (issues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(PremiumSpacing.md),
        margin: const EdgeInsets.all(PremiumSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(PremiumRadius.xs),
          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 18),
            SizedBox(width: PremiumSpacing.md),
            Text(
              'Graph Validation Passed (Clean)',
              style: TextStyle(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final errors = issues.where((i) => i.isError).toList();
    final warnings = issues.where((i) => !i.isError).toList();

    final Color statusColor = errors.isNotEmpty ? AppTheme.error : AppTheme.warning;
    final IconData statusIcon = errors.isNotEmpty ? Icons.cancel_outlined : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      margin: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PremiumRadius.xs),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: PremiumSpacing.md),
              Text(
                errors.isNotEmpty ? 'Graph Validation Failed' : 'Graph Validation Warnings',
                style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${errors.length} Errors • ${warnings.length} Warnings',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: PremiumSpacing.sm),
          ...issues.map((issue) {
            final color = issue.isError ? AppTheme.error : AppTheme.warning;
            return Padding(
              padding: const EdgeInsets.only(top: PremiumSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: PremiumSpacing.sm),
                  Expanded(
                    child: Text(
                      '${issue.code}: ${issue.message}',
                      style: TextStyle(fontSize: 12, color: color.withOpacity(0.85)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;

  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: PremiumMotion.fast,
      child: ElevatedButton.icon(
        key: ValueKey(_copied),
        style: ElevatedButton.styleFrom(
          backgroundColor: _copied ? AppTheme.success : AppTheme.surfaceOverlay,
          foregroundColor: _copied ? Colors.white : AppTheme.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: PremiumSpacing.md, vertical: PremiumSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PremiumRadius.xs),
          ),
        ),
        icon: Icon(
          _copied ? Icons.check_rounded : Icons.copy_rounded,
          size: 14,
          color: _copied ? Colors.white : AppTheme.textSecondary,
        ),
        label: Text(
          _copied ? 'Copied!' : 'Copy JSON',
          style: const TextStyle(fontSize: 12),
        ),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: widget.text));
          setState(() => _copied = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _copied = false);
            }
          });
        },
      ),
    );
  }
}
