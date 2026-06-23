import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/errors/app_error.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/errors/app_error_dialog.dart';

class ErrorLogScreen extends ConsumerWidget {
  const ErrorLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(recentErrorLogsProvider);

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(errorLogRepositoryProvider).clearResolved();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cleared resolved logs.')),
                );
              }
            },
            child: const Text('Clear Resolved'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear All Logs',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: AppTheme.surfaceDark,
                    surfaceTintColor: Colors.transparent,
                    title: const Text('Clear all logs?'),
                    content: const Text(
                      'This removes diagnostic logs only. It does not delete projects or media.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                await ref.read(errorLogRepositoryProvider).clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cleared all diagnostic logs.')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No diagnostic logs yet.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _ErrorLogTile(log: logs[index]);
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentPrimary),
          );
        },
        error: (err, stack) {
          return Center(
            child: Text(
              'Could not load logs: $err',
              style: const TextStyle(color: AppTheme.error),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorLogTile extends ConsumerStatefulWidget {
  final AppErrorLog log;

  const _ErrorLogTile({
    required this.log,
  });

  @override
  ConsumerState<_ErrorLogTile> createState() => _ErrorLogTileState();
}

class _ErrorLogTileState extends ConsumerState<_ErrorLogTile> {
  bool _expanded = false;

  AppErrorAction? _decodeAction(String payload) {
    if (payload == '{}') return null;
    try {
      final Map<String, dynamic> json = jsonDecode(payload);
      return AppErrorAction.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeContext(String payload) {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = _decodeAction(widget.log.actionPayload);
    final contextMap = _decodeContext(widget.log.contextJson);
    final severityColor = _colorForSeverity(widget.log.severity);
    final timeStr = widget.log.createdAt.toLocal().toString().substring(11, 19);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: widget.log.isResolved
              ? AppTheme.borderSubtle
              : severityColor.withValues(alpha: 0.3),
          width: widget.log.isResolved ? 0.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            leading: Icon(
              _iconForCategory(widget.log.category),
              color: widget.log.isResolved ? AppTheme.textMuted : severityColor,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.log.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: widget.log.isResolved ? AppTheme.textMuted : severityColor,
                    ),
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.log.userMessage,
                style: TextStyle(
                  color: widget.log.isResolved ? AppTheme.textSecondary : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: widget.log.isResolved ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            trailing: widget.log.isResolved
                ? const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 20)
                : IconButton(
                    icon: const Icon(Icons.radio_button_off_rounded, size: 20, color: AppTheme.textMuted),
                    tooltip: 'Mark Resolved',
                    onPressed: () async {
                      await ref
                          .read(errorReportingServiceProvider)
                          .markResolved(widget.log.id);
                    },
                  ),
          ),
          if (_expanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0),
              child: Divider(height: 1, color: AppTheme.borderSubtle),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DiagnosticRow(label: 'Error Code', value: widget.log.code),
                  if (widget.log.nativeCode != null)
                    _DiagnosticRow(label: 'Native Code', value: widget.log.nativeCode!),
                  if (widget.log.source != null)
                    _DiagnosticRow(label: 'Source', value: widget.log.source!),
                  if (widget.log.technicalMessage != null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Technical message:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        widget.log.technicalMessage!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  if (contextMap.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Context metadata:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(contextMap),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                  if (action != null && !widget.log.isResolved) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: severityColor,
                          foregroundColor: widget.log.severity == AppErrorSeverity.warning ? Colors.black : Colors.white,
                        ),
                        onPressed: () {
                          // Display Dialog with action trigger
                          final errorModel = AppError(
                            id: widget.log.id,
                            category: widget.log.category,
                            code: widget.log.code,
                            severity: widget.log.severity,
                            userMessage: widget.log.userMessage,
                            technicalMessage: widget.log.technicalMessage,
                            recoverySuggestion: widget.log.recoverySuggestion,
                            projectId: widget.log.projectId,
                            source: widget.log.source,
                            nativeCode: widget.log.nativeCode,
                            action: action,
                            context: contextMap,
                          );

                          AppErrorDialog.show(context, errorModel);
                        },
                        child: Text('Resolve Action: ${action.label}'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case AppErrorCategory.permission:
        return Icons.lock_rounded;
      case AppErrorCategory.missingFile:
        return Icons.link_off_rounded;
      case AppErrorCategory.unsupportedCodec:
        return Icons.movie_filter_rounded;
      case AppErrorCategory.storage:
        return Icons.storage_rounded;
      case AppErrorCategory.export:
        return Icons.upload_file_rounded;
      case AppErrorCategory.proxy:
        return Icons.movie_creation_outlined;
      case AppErrorCategory.timeline:
        return Icons.timeline_rounded;
      case AppErrorCategory.nativeEngine:
        return Icons.memory_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  Color _colorForSeverity(String severity) {
    switch (severity) {
      case AppErrorSeverity.info:
        return AppTheme.accentPrimary;
      case AppErrorSeverity.warning:
        return AppTheme.warning;
      case AppErrorSeverity.critical:
      case AppErrorSeverity.error:
      default:
        return AppTheme.error;
    }
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;

  const _DiagnosticRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
