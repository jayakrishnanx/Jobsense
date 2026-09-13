import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/job.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/job_card.dart';
import '../../widgets/job_filter_sheet.dart';
import 'job_details_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Deadline'; // 'Deadline', 'Latest', 'Vacancies'
  JobFilterCriteria _filterCriteria = JobFilterCriteria();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobFilterSheet(
        initialCriteria: _filterCriteria,
        onApply: (newCriteria) {
          setState(() {
            _filterCriteria = newCriteria;
          });
        },
      ),
    );
  }

  List<Job> _getFilteredJobs(List<Job> allJobs) {
    final user = appState.currentUser;

    return allJobs.where((job) {
      // 1. Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = job.title.toLowerCase().contains(query);
        final matchesOrg = job.organization.toLowerCase().contains(query);
        final matchesQual = job.qualification.toLowerCase().contains(query);
        final matchesLoc = job.location.toLowerCase().contains(query);
        if (!matchesTitle && !matchesOrg && !matchesQual && !matchesLoc) {
          return false;
        }
      }

      // 2. Sector / Type filter
      if (_filterCriteria.jobType != 'All' &&
          job.jobType.toLowerCase() != _filterCriteria.jobType.toLowerCase()) {
        return false;
      }

      // 3. Qualification filter
      if (_filterCriteria.qualification != 'All' &&
          !job.qualification.toLowerCase().contains(_filterCriteria.qualification.toLowerCase())) {
        return false;
      }

      // 4. Location filter
      if (_filterCriteria.location != 'All') {
        final loc = job.location.toLowerCase();
        final filterLoc = _filterCriteria.location.toLowerCase();
        if (!loc.contains(filterLoc) && !loc.contains('all india')) {
          return false;
        }
      }

      // 5. Category filter
      if (_filterCriteria.category != 'All') {
        if (!job.category.toLowerCase().contains(_filterCriteria.category.toLowerCase()) &&
            !job.category.toLowerCase().contains('all')) {
          return false;
        }
      }

      // 6. Eligible Only
      if (_filterCriteria.eligibleOnly) {
        if (!job.checkEligibility(user).isEligible) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_sortBy == 'Vacancies') {
          return b.vacancies.compareTo(a.vacancies);
        } else if (_sortBy == 'Latest') {
          return b.applicationStartDate.compareTo(a.applicationStartDate);
        } else {
          // Default: Deadline
          return a.lastDate.compareTo(b.lastDate);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Jobs'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_filterCriteria.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter Jobs',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, department, qualification...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),

          // Active filter row & Sort dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Active filter indicator
                if (_filterCriteria.hasActiveFilters)
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 14),
                    label: const Text('Clear Filters'),
                    onPressed: () {
                      setState(() {
                        _filterCriteria.reset();
                      });
                    },
                  )
                else
                  Text(
                    'All Notifications',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),

                // Sort Dropdown
                Row(
                  children: [
                    const Icon(Icons.sort, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Deadline', child: Text('Deadline')),
                        DropdownMenuItem(value: 'Latest', child: Text('Latest Added')),
                        DropdownMenuItem(value: 'Vacancies', child: Text('Vacancies')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Jobs List
          Expanded(
            child: ListenableBuilder(
              listenable: appState,
              builder: (context, _) {
                final filteredJobs = _getFilteredJobs(appState.jobs);

                if (filteredJobs.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No Jobs Found',
                    message: _searchQuery.isNotEmpty
                        ? 'No government job notifications match "$_searchQuery". Try different keywords.'
                        : 'No jobs match your currently applied filters.',
                    actionText: _filterCriteria.hasActiveFilters || _searchQuery.isNotEmpty
                        ? 'Reset All Filters'
                        : null,
                    onActionPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _filterCriteria.reset();
                      });
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    final job = filteredJobs[index];
                    return JobCard(
                      job: job,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobDetailsScreen(job: job),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}