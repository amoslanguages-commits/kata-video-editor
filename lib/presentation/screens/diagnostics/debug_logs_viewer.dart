import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/errors/app_error.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class DebugLogsViewer extends ConsumerStatefulWidget {
  const DebugLogsViewer({super.key});

  @override
  ConsumerState<DebugLogsViewer> createState() => _DebugLogsViewerState();
}

class _DebugLogsViewerState extends ConsumerState<DebugLogsViewer> {
  String _searchQuery = '';
  String? _filterSeverity;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsStream = ref.watch(debugLogServiceProvider).watchRecentLogs();

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list_rounded,
              color: _filterSeverity != null
                  ? AppTheme.accentPrimary
                  : AppTheme.textSecondary,
            ),
            tooltip: 'Filter by severity',
            color: AppTheme.surfaceDark,
            onSelected: (v) => setState(() => _filterSeverity = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: AppErrorSeverity.critical,
                child: Text('Critical'),
              ),
              const PopupMenuItem(
                value: AppErrorSeverity.error,
                child: Text('Error'),
              ),
              const PopupMenuItem(
                value: AppErrorSeverity.warning,
                child: Text('Warning'),
              ),
              const PopupMenuItem(
                value: AppErrorSeverity.info,
                child: Text('Info'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear resolved logs',
            onPressed: () async {
              final count =
                  await ref.read(debugLogServiceProvider).clearResolvedLogs();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cleared $count resolved logs.')),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search logs…',
                hintStyle:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<AppErrorLog>>(
        stream: logsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentPrimary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading logs: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.error),
              ),
            );
          }

          var logs = snapshot.data ?? [];

          // Apply severity filter.
          if (_filterSeverity != null) {
            logs = ref
                .read(debugLogServiceProvider)
                .filterBySeverity(logs, _filterSeverity!);
          }

          // Apply search.
          if (_searchQuery.isNotEmpty) {
            logs = ref.read(debugLogServiceProvider).search(logs, _searchQuery);
          }

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.done_all_rounded,
                    color: AppTheme.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No logs match your search.'
                        : 'No logs found. The app is clean!',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              return _LogEntryTile(
                log: logs[i],
                onDismiss: () async {
                  await ref
                      .read(debugLogServiceProvider)
                      .markResolved(logs[i].id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Log Entry Tile ────────────────────────────────────────────────────────────

class _LogEntryTile extends StatelessWidget {
  final AppErrorLog log;
  final VoidCallback onDismiss;

  const _LogEntryTile({required this.log, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _severityStyle(log.severity);
    final ts = log.createdAt;
    final timeLabel =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: log.isResolved
              ? AppTheme.borderSubtle.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 18),
        title: Text(
          log.userMessage,
          style: TextStyle(
            color: log.isResolved ? AppTheme.textMuted : AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            decoration: log.isResolved
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${log.category} • ${log.code} • $timeLabel',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!log.isResolved)
              IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: AppTheme.textMuted),
                tooltip: 'Mark resolved',
                onPressed: onDismiss,
              ),
          ],
        ),
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        iconColor: AppTheme.textMuted,
        collapsedIconColor: AppTheme.textMuted,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.technicalMessage != null) ...[
                  const Text(
                    'Technical Details',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.editorBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      log.technicalMessage!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (log.recoverySuggestion != null) ...[
                  const Text(
                    'Recovery Suggestion',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.recoverySuggestion!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    _MetaChip(label: log.severity),
                    const SizedBox(width: 6),
                    _MetaChip(label: log.category),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text:
                              '[${log.severity}] ${log.category}/${log.code}\n'
                              '${log.userMessage}\n'
                              '${log.technicalMessage ?? ''}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard.')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _severityStyle(String severity) {
    switch (severity) {
      case AppErrorSeverity.critical:
        return (AppTheme.error, Icons.error_rounded);
      case AppErrorSeverity.error:
        return (AppTheme.error, Icons.cancel_rounded);
      case AppErrorSeverity.warning:
        return (AppTheme.warning, Icons.warning_amber_rounded);
      default:
        return (AppTheme.accentPrimary, Icons.info_rounded);
    }
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOverlay,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
