import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/scraped_job.dart';
import '../../app/theme.dart';

class ScrapedJobsScreen extends StatefulWidget {
  const ScrapedJobsScreen({super.key});

  @override
  State<ScrapedJobsScreen> createState() => _ScrapedJobsScreenState();
}

class _ScrapedJobsScreenState extends State<ScrapedJobsScreen> {
  String _searchQuery = '';
  ScrapedJobReviewStatus? _selectedStatus;

  void _showRejectDialog(ScrapedJob job) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Scraped Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify reason for rejecting "${job.title}":',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Duplicate listing, invalid portal, expired post',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              appState.rejectScrapedJob(
                job.id,
                reason.isEmpty ? 'Marked invalid by Administrator' : reason,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Job "${job.title}" rejected.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reject Job'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ScrapedJob job) {
    final titleController = TextEditingController(text: job.title);
    final orgController = TextEditingController(text: job.organization);
    final vacanciesController = TextEditingController(text: job.vacancies);
    final lastDateController = TextEditingController(text: job.lastDate);
    final salaryController = TextEditingController(text: job.salary);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Extracted Job Metadata'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: orgController,
                decoration: const InputDecoration(labelText: 'Organization'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vacanciesController,
                decoration: const InputDecoration(labelText: 'Vacancies / Posts'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lastDateController,
                decoration: const InputDecoration(labelText: 'Application Last Date'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: 'Salary Scale'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = job.copyWith(
                title: titleController.text.trim(),
                organization: orgController.text.trim(),
                vacancies: vacanciesController.text.trim(),
                lastDate: lastDateController.text.trim(),
                salary: salaryController.text.trim(),
              );
              Navigator.pop(ctx);
              appState.editScrapedJob(updated);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Job information successfully updated.'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showJobDetails(ScrapedJob job) {
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
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Text(
              job.organization,
              style: TextStyle(fontSize: 14, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _infoRow('Scraped Source', job.source),
            _infoRow('Location', job.location),
            _infoRow('Vacancies', job.vacancies),
            _infoRow('Qualification', job.qualification),
            _infoRow('Salary / Pay', job.salary),
            _infoRow('Last Date', job.lastDate),
            _infoRow('Scraped Timestamp', job.scrapedDate),
            _infoRow('Review Status', job.reviewStatus.name.toUpperCase()),
            if (job.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rejection Reason: ${job.rejectionReason}',
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 20),
            if (job.reviewStatus == ScrapedJobReviewStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRejectDialog(job);
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                      onPressed: () {
                        Navigator.pop(ctx);
                        appState.approveScrapedJob(job.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${job.title}" approved and published to candidate engine!'),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Approve & Publish'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobs = appState.scrapedJobs.where((j) {
      final matchesQuery = j.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          j.organization.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == null || j.reviewStatus == _selectedStatus;
      return matchesQuery && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scraped Jobs Moderation'),
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
                    hintText: 'Search scraped jobs or organizations...',
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
                        label: Text('All (${appState.scrapedJobs.length})'),
                        selected: _selectedStatus == null,
                        onSelected: (_) => setState(() => _selectedStatus = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Pending Review (${appState.pendingScrapedJobsCount})'),
                        selected: _selectedStatus == ScrapedJobReviewStatus.pending,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = ScrapedJobReviewStatus.pending),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Approved (${appState.approvedScrapedJobsCount})'),
                        selected: _selectedStatus == ScrapedJobReviewStatus.approved,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = ScrapedJobReviewStatus.approved),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Rejected'),
                        selected: _selectedStatus == ScrapedJobReviewStatus.rejected,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = ScrapedJobReviewStatus.rejected),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scraped Jobs List
          Expanded(
            child: jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No scraped jobs found for this filter'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];

                      Color statusColor;
                      String statusText;
                      IconData statusIcon;

                      switch (job.reviewStatus) {
                        case ScrapedJobReviewStatus.pending:
                          statusColor = const Color(0xFFF59E0B);
                          statusText = 'Pending Review';
                          statusIcon = Icons.hourglass_top_rounded;
                          break;
                        case ScrapedJobReviewStatus.approved:
                          statusColor = const Color(0xFF10B981);
                          statusText = 'Approved & Live';
                          statusIcon = Icons.verified_rounded;
                          break;
                        case ScrapedJobReviewStatus.rejected:
                          statusColor = const Color(0xFFEF4444);
                          statusText = 'Rejected';
                          statusIcon = Icons.cancel_outlined;
                          break;
                        case ScrapedJobReviewStatus.expired:
                          statusColor = Colors.grey;
                          statusText = 'Expired';
                          statusIcon = Icons.event_busy_rounded;
                          break;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Source portal + Status badge
                              Row(
                                children: [
                                  Icon(Icons.link, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      job.organization,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 12, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text(
                                job.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Quick chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _metaChip(Icons.school_outlined, job.qualification),
                                  _metaChip(Icons.location_on_outlined, job.location),
                                  _metaChip(Icons.group_outlined, job.vacancies),
                                  _metaChip(Icons.calendar_today_outlined, 'Ends: ${job.lastDate}'),
                                ],
                              ),

                              if (job.rejectionReason != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Reason: ${job.rejectionReason}',
                                    style: const TextStyle(fontSize: 11, color: Colors.red),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              // Actions
                              Row(
                                children: [
                                  Text(
                                    'Scraped: ${job.scrapedDate}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Edit extracted metadata',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _showEditDialog(job),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'Delete invalid job',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Scraped Job'),
                                          content: Text('Remove "${job.title}" permanently?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                appState.deleteScrapedJob(job.id);
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  if (job.reviewStatus == ScrapedJobReviewStatus.pending) ...[
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => _showRejectDialog(job),
                                      child: const Text('Reject'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () {
                                        appState.approveScrapedJob(job.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('"${job.title}" approved and published!'),
                                            backgroundColor: Colors.green.shade700,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: const Text('Approve'),
                                    ),
                                  ] else ...[
                                    TextButton(
                                      onPressed: () => _showJobDetails(job),
                                      child: const Text('View Full Info'),
                                    ),
                                  ],
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

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
