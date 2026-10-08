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
  String _selectedBoard = 'All'; // 'All', 'PSC', 'SSC', 'UPSC', 'Railway', 'Banking'
  int _selectedTab = 0; // 0: All, 1: Eligible, 2: Not Eligible
  JobFilterCriteria _filterCriteria = JobFilterCriteria();

  static const List<Map<String, dynamic>> _boardOptions = [
    {'code': 'All', 'name': 'All Portals / Boards', 'label': 'All Boards', 'icon': Icons.apps_rounded},
    {'code': 'PSC', 'name': 'Kerala PSC', 'label': 'Kerala PSC', 'icon': Icons.account_balance_rounded},
    {'code': 'SSC', 'name': 'SSC (Staff Selection)', 'label': 'SSC', 'icon': Icons.apartment_rounded},
    {'code': 'UPSC', 'name': 'UPSC (Civil Services)', 'label': 'UPSC', 'icon': Icons.stars_rounded},
    {'code': 'Railway', 'name': 'Railway / RRB', 'label': 'Railway', 'icon': Icons.train_rounded},
    {'code': 'Banking', 'name': 'Banking / IBPS', 'label': 'Banking', 'icon': Icons.account_balance_wallet_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState.syncWithBackend();
    });
  }

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
      final isEligible = job.checkEligibility(user).isEligible;

      // Segment tab separation
      if (_selectedTab == 1 && !isEligible) return false;
      if (_selectedTab == 2 && isEligible) return false;

      // 1. Board / Portal Filter (PSC, SSC, UPSC, Railway, Banking)
      if (_selectedBoard != 'All') {
        final org = job.organization.toLowerCase();
        final url = job.officialNotificationUrl.toLowerCase();
        final jid = job.id.toLowerCase();
        final title = job.title.toLowerCase();

        if (_selectedBoard == 'PSC') {
          final isPsc = org.contains('psc') ||
              org.contains('kerala public') ||
              url.contains('keralapsc') ||
              jid.startsWith('kpsc') ||
              title.contains('cat. no') ||
              title.contains('kpsc');
          if (!isPsc) return false;
        } else if (_selectedBoard == 'SSC') {
          final isSsc = org.contains('ssc') ||
              org.contains('staff selection') ||
              url.contains('ssc.') ||
              jid.startsWith('ssc') ||
              title.contains('ssc');
          if (!isSsc) return false;
        } else if (_selectedBoard == 'UPSC') {
          final isUpsc = org.contains('upsc') ||
              org.contains('union public') ||
              url.contains('upsc') ||
              jid.startsWith('upsc') ||
              title.contains('upsc');
          if (!isUpsc) return false;
        } else if (_selectedBoard == 'Railway') {
          final isRailway = org.contains('railway') ||
              org.contains('rrb') ||
              url.contains('rrb') ||
              jid.startsWith('rrb') ||
              title.contains('railway');
          if (!isRailway) return false;
        } else if (_selectedBoard == 'Banking') {
          final isBanking = org.contains('bank') ||
              org.contains('ibps') ||
              org.contains('sbi') ||
              title.contains('bank');
          if (!isBanking) return false;
        }
      }

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = job.title.toLowerCase().contains(query);
        final matchesOrg = job.organization.toLowerCase().contains(query);
        final matchesQual = job.qualification.toLowerCase().contains(query);
        final matchesLoc = job.location.toLowerCase().contains(query);
        final matchesDept = job.department.toLowerCase().contains(query);
        if (!matchesTitle && !matchesOrg && !matchesQual && !matchesLoc && !matchesDept) {
          return false;
        }
      }

      // 3. Sector / Type filter
      if (_filterCriteria.jobType != 'All' &&
          job.jobType.toLowerCase() != _filterCriteria.jobType.toLowerCase()) {
        return false;
      }

      // 4. Qualification filter
      if (_filterCriteria.qualification != 'All' &&
          !job.qualification.toLowerCase().contains(_filterCriteria.qualification.toLowerCase())) {
        return false;
      }

      // 5. Location filter
      if (_filterCriteria.location != 'All') {
        final loc = job.location.toLowerCase();
        final filterLoc = _filterCriteria.location.toLowerCase();
        if (!loc.contains(filterLoc) && !loc.contains('all india')) {
          return false;
        }
      }

      // 6. Category filter
      if (_filterCriteria.category != 'All') {
        if (!job.category.toLowerCase().contains(_filterCriteria.category.toLowerCase()) &&
            !job.category.toLowerCase().contains('all')) {
          return false;
        }
      }

      // 7. Eligible Only
      if (_filterCriteria.eligibleOnly && !isEligible) {
        return false;
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
    final user = appState.currentUser;
    final allJobs = appState.jobs;
    final eligibleCount = allJobs.where((j) => j.checkEligibility(user).isEligible).length;
    final notEligibleCount = allJobs.length - eligibleCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search title, category no, qualification...',
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

          // Horizontal Board Quick Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _boardOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final opt = _boardOptions[index];
                final isSelected = _selectedBoard == opt['code'];
                return ChoiceChip(
                  avatar: Icon(
                    opt['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : theme.colorScheme.primary,
                  ),
                  label: Text(opt['label'] as String),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedBoard = opt['code'] as String);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // 3-Way Segmented Tabs (All / Eligible / Not Eligible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, 'All (${allJobs.length})', Icons.dashboard_outlined),
                  _buildTabButton(1, 'Eligible ($eligibleCount)', Icons.check_circle_outline),
                  _buildTabButton(2, 'Other ($notEligibleCount)', Icons.info_outline),
                ],
              ),
            ),
          ),

          // Board Dropdown Selector & Sort Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Board Dropdown Selector
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedBoard != 'All'
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBoard,
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        items: _boardOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt['code'] as String,
                            child: Row(
                              children: [
                                Icon(opt['icon'] as IconData, size: 15, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    opt['name'] as String,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBoard = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Sort Dropdown
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Deadline',
                          child: Row(
                            children: [
                              Icon(Icons.event_outlined, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text('Deadline'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Latest',
                          child: Row(
                            children: [
                              Icon(Icons.new_releases_outlined, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text('Latest'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Vacancies',
                          child: Row(
                            children: [
                              Icon(Icons.people_alt_outlined, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text('Vacancies'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active filter indicator if any
          if (_filterCriteria.hasActiveFilters || _selectedBoard != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  if (_selectedBoard != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        avatar: const Icon(Icons.account_balance, size: 14),
                        label: Text('Board: $_selectedBoard'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() => _selectedBoard = 'All');
                        },
                      ),
                    ),
                  if (_filterCriteria.hasActiveFilters)
                    ActionChip(
                      avatar: const Icon(Icons.close, size: 14),
                      label: const Text('Clear Filter Sheet'),
                      onPressed: () {
                        setState(() {
                          _filterCriteria.reset();
                        });
                      },
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
                  return RefreshIndicator(
                    onRefresh: () => appState.syncWithBackend(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyState(
                          icon: _selectedTab == 1
                              ? Icons.verified_user_outlined
                              : Icons.search_off_rounded,
                          title: _selectedTab == 1
                              ? 'No Eligible Jobs For Profile'
                              : 'No Jobs Found',
                          message: _selectedTab == 1
                              ? 'None of the active notifications match your current qualification (${user?.qualification ?? "Unspecified"}). Switch to "All (${allJobs.length})" to view all openings.'
                              : _searchQuery.isNotEmpty
                                  ? 'No government job notifications match "$_searchQuery". Try different keywords.'
                                  : 'No jobs match your currently applied filters.',
                          actionText: _selectedTab == 1
                              ? 'View All Notifications'
                              : (_filterCriteria.hasActiveFilters || _searchQuery.isNotEmpty
                                  ? 'Reset All Filters'
                                  : 'Refresh Notifications'),
                          onActionPressed: () {
                            setState(() {
                              _selectedBoard = 'All';
                              if (_selectedTab == 1) {
                                _selectedTab = 0;
                              } else {
                                _searchController.clear();
                                _searchQuery = '';
                                _filterCriteria.reset();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => appState.syncWithBackend(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}