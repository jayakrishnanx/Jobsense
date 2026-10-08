import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/scraped_job.dart';
import '../../models/scraper.dart';
import '../../app/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;

  const AdminDashboardScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final theme = Theme.of(context);
        final admin = appState.currentAdmin;
        final scrapers = appState.scrapers;
        final scrapedJobs = appState.scrapedJobs;
        final totalJobsCollected = scrapers.fold<int>(0, (sum, s) => sum + s.jobsCollected);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('JobSense Admin'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Sync with Backend',
                onPressed: () {
                  appState.syncWithBackend();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Synchronizing with live backend...'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live Connected',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome & System Supervision Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryLightBlue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Supervision Console: ${admin?.name ?? "Admin"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Live Government Job Aggregator & Eligibility Engine',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _headerStat('Active Sources', '${appState.totalScrapers} Portals'),
                            _headerDivider(),
                            _headerStat('Jobs Collected', '$totalJobsCollected Notices'),
                            _headerDivider(),
                            _headerStat('Alerts Ready', '${appState.notifications.length} Alerts'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section Header: Core Metrics
                const Text(
                  'System Overview (Live MongoDB Data)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // 4 Grid Metric Cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _metricCard(
                      context,
                      title: 'Total Users',
                      value: '${appState.managedUsers.length}',
                      subtitle: 'Registered candidates',
                      icon: Icons.people_outline,
                      color: AppTheme.primaryBlue,
                      onTap: () => onNavigateToTab?.call(3),
                    ),
                    _metricCard(
                      context,
                      title: 'Total Active Jobs',
                      value: '${appState.jobs.length}',
                      subtitle: 'Verified opportunities',
                      icon: Icons.work_outline,
                      color: const Color(0xFF0D9488),
                      onTap: () => onNavigateToTab?.call(2),
                    ),
                    _metricCard(
                      context,
                      title: 'Active Scrapers',
                      value: '${appState.activeScrapersCount}',
                      subtitle: 'Live crawlers ready',
                      icon: Icons.sync,
                      color: const Color(0xFF10B981),
                      onTap: () => onNavigateToTab?.call(1),
                    ),
                    _metricCard(
                      context,
                      title: 'Pending Review',
                      value: '${appState.pendingScrapedJobsCount}',
                      subtitle: 'Scraped jobs queue',
                      icon: Icons.hourglass_top,
                      color: const Color(0xFFF59E0B),
                      onTap: () => onNavigateToTab?.call(2),
                    ),
                  ],
                ),


            const SizedBox(height: 28),

            // Section Header: Scraper Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Scraper Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateToTab?.call(1),
                  child: const Text('Manage All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: scrapers.take(4).length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final scraper = scrapers[index];
                  final isFailed = scraper.status == ScraperStatus.failed;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isFailed
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      child: Icon(
                        isFailed ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                        color: isFailed ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      scraper.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      isFailed ? (scraper.lastError ?? 'Timeout') : 'Collected ${scraper.jobsCollected} jobs • ${scraper.lastRun}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isFailed ? Colors.red.shade700 : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFailed
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scraper.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFailed ? Colors.red : Colors.green.shade800,
                        ),
                      ),
                    ),
                    onTap: () => onNavigateToTab?.call(1),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Section Header: Pending Scraped Jobs Queue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Pending Scraped Jobs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${appState.pendingScrapedJobsCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => onNavigateToTab?.call(2),
                  child: const Text('Review All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...scrapedJobs
                .where((j) => j.reviewStatus == ScrapedJobReviewStatus.pending)
                .take(3)
                .map((job) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.pending_actions, color: Color(0xFFD97706), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.organization,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    job.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${job.vacancies} • Ends: ${job.lastDate}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                              child: const Text('Approve', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    )),

            const SizedBox(height: 24),

            // Quick Administration Section List
            const Text(
              'Administration Modules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _adminModuleTile(
              context,
              icon: Icons.language,
              title: 'Scraper Management',
              subtitle: 'Monitor and run government website crawlers',
              onTap: () => onNavigateToTab?.call(1),
            ),
            _adminModuleTile(
              context,
              icon: Icons.fact_check_outlined,
              title: 'Scraped Jobs Moderation',
              subtitle: 'Review, edit, and approve extracted announcements',
              onTap: () => onNavigateToTab?.call(2),
            ),
            _adminModuleTile(
              context,
              icon: Icons.people_outline,
              title: 'User Management',
              subtitle: 'Supervise candidates, eligibility matches, and account states',
              onTap: () => onNavigateToTab?.call(3),
            ),
            _adminModuleTile(
              context,
              icon: Icons.article_outlined,
              title: 'System Audit Logs',
              subtitle: 'Trace scraper operations, alert batches, and errors',
              onTap: () => onNavigateToTab?.call(4),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _headerDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminModuleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}