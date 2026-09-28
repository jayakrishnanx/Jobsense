import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/managed_user.dart';
import '../../app/theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  UserAccountStatus? _statusFilter;

  void _showUserProfileSummary(ManagedUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '+91 ${user.phone} • ${user.email}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _profileRow('Registration Date', user.registrationDate),
            _profileRow('Account Status', user.status.name.toUpperCase()),
            _profileRow('Profile Completion', '${user.profileCompletion}% Complete'),
            _profileRow('Eligible Govt Jobs Matched', '${user.eligibleJobsCount} openings'),
            _profileRow('Highest Qualification', user.qualification),
            _profileRow('Reservation Category', user.category),
            _profileRow('Domicile State', user.state),
            if (user.blockReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Suspension Reason: ${user.blockReason}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.status == UserAccountStatus.active
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmBlockToggle(user);
                },
                icon: Icon(
                  user.status == UserAccountStatus.active ? Icons.block : Icons.check_circle,
                ),
                label: Text(
                  user.status == UserAccountStatus.active
                      ? 'Suspend / Block Candidate'
                      : 'Unblock Candidate',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlockToggle(ManagedUser user) {
    final reasonController = TextEditingController();
    final isBlocking = user.status == UserAccountStatus.active;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBlocking ? 'Block Candidate' : 'Unblock Candidate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBlocking
                  ? 'Are you sure you want to block ${user.name}? They will lose access to notifications and personalized matching.'
                  : 'Restore active privileges for ${user.name}?',
              style: const TextStyle(fontSize: 13),
            ),
            if (isBlocking) ...[
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Reason for blocking (e.g. Terms violation)',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocking ? Colors.red.shade700 : Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              appState.toggleUserBlock(
                user.id,
                reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBlocking
                        ? '${user.name} has been blocked.'
                        : '${user.name} has been reinstated.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(isBlocking ? 'Confirm Block' : 'Confirm Unblock'),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = appState.managedUsers.where((u) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = u.name.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.qualification.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == null || u.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
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
                    hintText: 'Search candidate by name, phone or email...',
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
                        label: Text('All Users (${appState.managedUsers.length})'),
                        selected: _statusFilter == null,
                        onSelected: (_) => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'Active (${appState.managedUsers.where((u) => u.status == UserAccountStatus.active).length})',
                        ),
                        selected: _statusFilter == UserAccountStatus.active,
                        onSelected: (_) =>
                            setState(() => _statusFilter = UserAccountStatus.active),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'Blocked (${appState.managedUsers.where((u) => u.status == UserAccountStatus.blocked).length})',
                        ),
                        selected: _statusFilter == UserAccountStatus.blocked,
                        onSelected: (_) =>
                            setState(() => _statusFilter = UserAccountStatus.blocked),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No candidate found'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isBlocked = user.status == UserAccountStatus.blocked;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isBlocked
                                ? Colors.red.withValues(alpha: 0.3)
                                : theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Avatar + Name + Status chip
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isBlocked
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : AppTheme.primaryBlue.withValues(alpha: 0.1),
                                    child: Text(
                                      user.name.substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: isBlocked ? Colors.red : AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '+91 ${user.phone} • ${user.email}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isBlocked
                                          ? Colors.red.withValues(alpha: 0.1)
                                          : Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isBlocked ? 'Blocked' : 'Active',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isBlocked ? Colors.red : Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Quick badges: Profile completion, Eligible jobs, Qualification
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Completion',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                          ),
                                          Text(
                                            '${user.profileCompletion}%',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Eligible Jobs',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                          ),
                                          Text(
                                            '${user.eligibleJobsCount} Matches',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Qualification',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                          ),
                                          Text(
                                            user.qualification.split(' ').first,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (user.blockReason != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Reason: ${user.blockReason}',
                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                ),
                              ],

                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 6),

                              // Bottom actions: View Profile, Block/Unblock
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Joined: ${user.registrationDate}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () => _showUserProfileSummary(user),
                                        child: const Text('View Profile'),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: Icon(
                                          isBlocked ? Icons.lock_open : Icons.block,
                                          size: 18,
                                          color: isBlocked ? Colors.green : Colors.red,
                                        ),
                                        tooltip: isBlocked ? 'Unblock user' : 'Block user',
                                        onPressed: () => _confirmBlockToggle(user),
                                      ),
                                    ],
                                  ),
                                ],
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
  }
}
