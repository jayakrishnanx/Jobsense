import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_card.dart';
import '../jobs/job_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilterIndex = 0; // 0 = Unread First, 1 = All

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_outlined),
            tooltip: 'Mark all as read',
            onPressed: () {
              appState.markAllNotificationsAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final allNotifs = appState.notifications;
          final unreadCount = appState.unreadNotificationCount;
          final displayedNotifs = _selectedFilterIndex == 0
              ? allNotifs.where((n) => !n.isRead).toList()
              : allNotifs;

          return Column(
            children: [
              // Segmented Filter Bar: Unread First vs All
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _filterChip(
                      label: 'Unread ($unreadCount)',
                      isSelected: _selectedFilterIndex == 0,
                      onTap: () => setState(() => _selectedFilterIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'All (${allNotifs.length})',
                      isSelected: _selectedFilterIndex == 1,
                      onTap: () => setState(() => _selectedFilterIndex = 1),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Notifications List or Empty State
              Expanded(
                child: displayedNotifs.isEmpty
                    ? EmptyState(
                        icon: _selectedFilterIndex == 0
                            ? Icons.mark_email_read_outlined
                            : Icons.notifications_none_outlined,
                        title: _selectedFilterIndex == 0
                            ? 'No Unread Alerts'
                            : 'No Notifications',
                        message: _selectedFilterIndex == 0
                            ? 'You are all caught up! Tap below or select "All" to view past job notifications.'
                            : 'You will receive notifications whenever a new government job matches your qualifications.',
                        actionText: _selectedFilterIndex == 0
                            ? 'View All Notifications'
                            : null,
                        onActionPressed: _selectedFilterIndex == 0
                            ? () => setState(() => _selectedFilterIndex = 1)
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedNotifs.length,
                        itemBuilder: (context, index) {
                          final notif = displayedNotifs[index];
                          return NotificationCard(
                            notification: notif,
                            onTap: () {
                              // Mark as read
                              appState.markNotificationAsRead(notif.id);

                              // Navigate to corresponding Job details
                              final job = appState.getJobById(notif.jobId);
                              if (job != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JobDetailsScreen(job: job),
                                  ),
                                );
                              }
                            },
                            onDelete: () {
                              appState.deleteNotification(notif.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification removed'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}