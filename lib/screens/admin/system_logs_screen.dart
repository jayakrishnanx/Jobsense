import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/system_log.dart';

class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  String _searchQuery = '';
  LogLevel? _levelFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final logs = appState.systemLogs.where((l) {
          final matchesQuery = l.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              l.eventType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (l.source?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          final matchesLevel = _levelFilter == null || l.level == _levelFilter;
          return matchesQuery && matchesLevel;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('System Audit Logs'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Logs from MongoDB',
                onPressed: () {
                  appState.syncWithBackend();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('System logs refreshed from backend.'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Logs',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear All System Logs'),
                  content: const Text('Are you sure you want to clear the system audit log history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(ctx);
                        appState.clearSystemLogs();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('System logs cleared.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search logs by event, description or source...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('All (${appState.systemLogs.length})'),
                        selected: _levelFilter == null,
                        onSelected: (_) => setState(() => _levelFilter = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'Success (${appState.systemLogs.where((l) => l.level == LogLevel.success).length})',
                        ),
                        selected: _levelFilter == LogLevel.success,
                        onSelected: (_) => setState(() => _levelFilter = LogLevel.success),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'Warnings (${appState.systemLogs.where((l) => l.level == LogLevel.warning).length})',
                        ),
                        selected: _levelFilter == LogLevel.warning,
                        onSelected: (_) => setState(() => _levelFilter = LogLevel.warning),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'Errors (${appState.systemLogs.where((l) => l.level == LogLevel.error).length})',
                        ),
                        selected: _levelFilter == LogLevel.error,
                        onSelected: (_) => setState(() => _levelFilter = LogLevel.error),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Info'),
                        selected: _levelFilter == LogLevel.info,
                        onSelected: (_) => setState(() => _levelFilter = LogLevel.info),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Log list
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No system logs recorded'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];

                      Color iconColor;
                      IconData iconData;
                      Color bgBadgeColor;

                      switch (log.level) {
                        case LogLevel.success:
                          iconColor = Colors.green;
                          iconData = Icons.check_circle_outline;
                          bgBadgeColor = Colors.green.withValues(alpha: 0.1);
                          break;
                        case LogLevel.warning:
                          iconColor = const Color(0xFFF59E0B);
                          iconData = Icons.warning_amber_rounded;
                          bgBadgeColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
                          break;
                        case LogLevel.error:
                          iconColor = Colors.red;
                          iconData = Icons.error_outline;
                          bgBadgeColor = Colors.red.withValues(alpha: 0.1);
                          break;
                        case LogLevel.info:
                          iconColor = Colors.blue;
                          iconData = Icons.info_outline;
                          bgBadgeColor = Colors.blue.withValues(alpha: 0.1);
                          break;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: bgBadgeColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(iconData, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            log.eventType.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                        if (log.source != null) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '• ${log.source}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        Text(
                                          log.timestamp,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      log.description,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
      },
    );
  }
}

