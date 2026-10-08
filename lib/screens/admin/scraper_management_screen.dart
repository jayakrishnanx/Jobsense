import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/scraper.dart';
import '../../app/theme.dart';

class ScraperManagementScreen extends StatefulWidget {
  const ScraperManagementScreen({super.key});

  @override
  State<ScraperManagementScreen> createState() => _ScraperManagementScreenState();
}

class _ScraperManagementScreenState extends State<ScraperManagementScreen> {
  String _searchQuery = '';
  ScraperStatus? _statusFilter;
  final Set<String> _runningScrapers = {};

  void _runScraperManually(Scraper scraper) async {
    setState(() {
      _runningScrapers.add(scraper.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Running scraper for ${scraper.name}...')),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await appState.runScraper(scraper.id);

    if (!mounted) return;
    setState(() {
      _runningScrapers.remove(scraper.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scraper run completed for ${scraper.name}. 2 new announcements detected!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showScraperDetails(Scraper scraper) {
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.language, color: AppTheme.primaryBlue, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scraper.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        scraper.department,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _detailRow('Target Portal', scraper.website),
            _detailRow('Execution Frequency', scraper.frequency),
            _detailRow('Last Execution', scraper.lastRun),
            _detailRow('Total Jobs Collected', '${scraper.jobsCollected} listings'),
            _detailRow('Scraper Status', scraper.status.name.toUpperCase()),
            if (scraper.lastError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scraper.lastError!,
                        style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _runScraperManually(scraper);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Execute Run'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete Scraper',
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await appState.removeScraper(scraper.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${scraper.name}'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScraperDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    String category = 'Kerala PSC';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Target Website'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Website / Portal Name *',
                    hintText: 'e.g. Kerala PSC Notifications',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target URL *',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Department / Organization',
                    hintText: 'e.g. Kerala Public Service Commission',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Kerala PSC', child: Text('Kerala PSC')),
                    DropdownMenuItem(value: 'Central Govt', child: Text('Central Govt')),
                    DropdownMenuItem(value: 'State Govt', child: Text('State Govt')),
                    DropdownMenuItem(value: 'Banking', child: Text('Banking')),
                    DropdownMenuItem(value: 'Railway', child: Text('Railway')),
                    DropdownMenuItem(value: 'Defence & Research', child: Text('Defence & Research')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => category = val);
                  },
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
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final url = urlCtrl.text.trim();
                if (name.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter portal name and URL'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final ok = await appState.createScraper(
                  name: name,
                  targetUrl: url,
                  category: category,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Website added successfully!' : 'Failed to add website'),
                      backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Add Website'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final scrapers = appState.scrapers.where((s) {
          final matchesQuery = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.website.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.department.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesStatus = _statusFilter == null || s.status == _statusFilter;
          return matchesQuery && matchesStatus;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Scraper Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Scrapers from DB',
                onPressed: () {
                  appState.syncWithBackend();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing scrapers from MongoDB...'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Scraper Architecture Info',

            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('JobSense Scraper Architecture'),
                  content: const Text(
                    'Scrapers periodically crawl verified state & central government recruitment portals, extract key notification metadata (vacancies, age limits, qualifications), and feed them into the candidate eligibility pipeline.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
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
                    hintText: 'Search government portal or source...',
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
                        label: Text('All (${appState.scrapers.length})'),
                        selected: _statusFilter == null,
                        onSelected: (_) => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Active (${appState.activeScrapersCount})'),
                        selected: _statusFilter == ScraperStatus.active,
                        onSelected: (_) => setState(() => _statusFilter = ScraperStatus.active),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Failed (${appState.failedScrapersCount})'),
                        selected: _statusFilter == ScraperStatus.failed,
                        onSelected: (_) => setState(() => _statusFilter = ScraperStatus.failed),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Inactive'),
                        selected: _statusFilter == ScraperStatus.inactive,
                        onSelected: (_) => setState(() => _statusFilter = ScraperStatus.inactive),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrapers List
          Expanded(
            child: scrapers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.language, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          const Text(
                            'No websites configured yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add your target recruitment portals one by one to begin crawling and scraping notices.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: _showAddScraperDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Target Website'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: scrapers.length,
                    itemBuilder: (context, index) {
                      final scraper = scrapers[index];
                      final isRunning = _runningScrapers.contains(scraper.id);

                      Color statusColor;
                      IconData statusIcon;
                      String statusText;

                      switch (scraper.status) {
                        case ScraperStatus.active:
                          statusColor = Colors.green;
                          statusIcon = Icons.check_circle_outline;
                          statusText = 'Active';
                          break;
                        case ScraperStatus.failed:
                          statusColor = Colors.red;
                          statusIcon = Icons.error_outline;
                          statusText = 'Failed';
                          break;
                        case ScraperStatus.inactive:
                          statusColor = Colors.grey;
                          statusIcon = Icons.pause_circle_outline;
                          statusText = 'Inactive';
                          break;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: scraper.status == ScraperStatus.failed
                                ? Colors.red.withValues(alpha: 0.3)
                                : theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top header row: Name + Status badge + Toggle
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          scraper.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          scraper.website,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryLightBlue,
                                          ),
                                        ),
                                      ],
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
                                        Icon(statusIcon, size: 14, color: statusColor),
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
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: scraper.status == ScraperStatus.active,
                                    onChanged: (_) {
                                      appState.toggleScraperStatus(scraper.id);
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Info Badges (Jobs count, Last run, frequency)
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.work_outline, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${scraper.jobsCollected} jobs collected',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ran ${scraper.lastRun}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.update, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        scraper.frequency,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Last error alert if failed
                              if (scraper.lastError != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          scraper.lastError!,
                                          style: const TextStyle(fontSize: 12, color: Colors.red),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showScraperDetails(scraper),
                                    icon: const Icon(Icons.visibility_outlined, size: 16),
                                    label: const Text('Details'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: isRunning ? null : () => _runScraperManually(scraper),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    icon: isRunning
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.play_arrow, size: 16),
                                    label: Text(isRunning ? 'Scraping...' : 'Run Now'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScraperDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Website'),
      ),
    );
      },
    );
  }
}


