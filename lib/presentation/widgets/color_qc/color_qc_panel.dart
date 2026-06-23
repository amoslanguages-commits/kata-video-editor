// lib/presentation/widgets/color_qc/color_qc_panel.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/domain/color_qc/color_qc_models.dart';
import 'package:nle_editor/presentation/providers/color_qc_providers.dart';

class ColorQcPanel extends ConsumerStatefulWidget {
  final String projectId;

  const ColorQcPanel({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  ConsumerState<ColorQcPanel> createState() => _ColorQcPanelState();
}

class _ColorQcPanelState extends ConsumerState<ColorQcPanel> {
  @override
  void initState() {
    super.initState();
    // Run checks on init
    Future.microtask(() {
      ref.read(colorQcControllerProvider(widget.projectId).notifier).runAllChecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(colorQcControllerProvider(widget.projectId));
    final notifier = ref.read(colorQcControllerProvider(widget.projectId).notifier);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.cyanAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Color QA & Stabilization Panel',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (state.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Run all checks',
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        onPressed: state.isLoading ? null : notifier.runAllChecks,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),

              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                  ),
                  child: Text(
                    'Error running checks: ${state.error}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),

              // Status Card
              _buildStatusCard(state),
              const SizedBox(height: 16),

              // List Issues
              Expanded(
                child: _buildIssuesList(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ColorQcState state) {
    final passed = state.passed;
    final totalIssues = state.issueCount;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: passed
              ? [Colors.teal.withOpacity(0.25), Colors.cyan.withOpacity(0.1)]
              : [Colors.deepOrange.withOpacity(0.25), Colors.purple.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (passed ? Colors.tealAccent : Colors.deepOrangeAccent).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.verified_user : Icons.warning_amber_rounded,
            color: passed ? Colors.tealAccent : Colors.deepOrangeAccent,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed ? 'Color Engine Validated' : 'Validation Issues Found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  passed
                      ? 'All stages (order, schema, output compatibility) are fully verified and stable.'
                      : 'Detected $totalIssues active issue(s) that require stabilization adjustments.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesList(ColorQcState state) {
    final issues = <ColorQaIssue>[];
    if (state.localReport != null) issues.addAll(state.localReport!.issues);
    if (state.nativeReport != null) issues.addAll(state.nativeReport!.issues);
    if (state.shaderReport != null) issues.addAll(state.shaderReport!.issues);
    if (state.memoryReport != null) issues.addAll(state.memoryReport!.issues);

    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.done_all_rounded, color: Colors.tealAccent, size: 48),
            SizedBox(height: 8),
            Text(
              'No QA anomalies detected.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        final isBlocker = issue.severity == ColorQaSeverity.releaseBlocker;
        final isError = issue.severity == ColorQaSeverity.error;
        final isWarning = issue.severity == ColorQaSeverity.warning;

        final Color color = isBlocker
            ? Colors.redAccent
            : isError
                ? Colors.deepOrangeAccent
                : isWarning
                    ? Colors.amberAccent
                    : Colors.cyanAccent;

        return Card(
          color: Colors.white.withOpacity(0.03),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isBlocker
                      ? Icons.gavel_rounded
                      : isWarning
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              issue.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              issue.severity.name.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Area: ${issue.area.name.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        issue.message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      if (issue.suggestedFix != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                              children: [
                                const TextSpan(
                                  text: 'Suggested Fix: ',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: issue.suggestedFix),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
