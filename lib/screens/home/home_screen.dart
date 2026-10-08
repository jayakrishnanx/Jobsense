import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../widgets/job_card.dart';
import '../../widgets/profile_completion_card.dart';
import '../jobs/job_details_screen.dart';
import '../jobs/jobs_screen.dart';
import '../jobs/saved_jobs_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final unreadCount = appState.unreadNotificationCount;

        final List<Widget> pages = [
          HomeDashboard(
            onViewAllJobs: () => _onTabSelected(1),
            onViewAllAlerts: () => _onTabSelected(2),
          ),
          const JobsScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onTabSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: 'Jobs',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.notifications),
                ),
                label: 'Alerts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeDashboard extends StatefulWidget {
  final VoidCallback onViewAllJobs;
  final VoidCallback onViewAllAlerts;

  const HomeDashboard({
    super.key,
    required this.onViewAllJobs,
    required this.onViewAllAlerts,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final PageController _eligiblePageController =
      PageController(viewportFraction: 0.88);
  final PageController _recentPageController =
      PageController(viewportFraction: 0.88);
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoScrollTimer == null || !_autoScrollTimer!.isActive) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final eligibleCount = appState.eligibleJobs.length;
      final recentCount = appState.jobs.length;
      _autoScrollNext(_eligiblePageController, eligibleCount);
      _autoScrollNext(_recentPageController, recentCount);
    });
  }

  void _autoScrollNext(PageController controller, int itemCount) {
    if (!controller.hasClients || itemCount <= 1 || !mounted) return;
    final currentPage = controller.page?.round() ?? controller.initialPage;
    final nextPage = (currentPage + 1) % itemCount;
    controller.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _pageNext(PageController controller, int itemCount) {
    if (!controller.hasClients || itemCount <= 1) return;
    final currentPage = controller.page?.round() ?? controller.initialPage;
    final nextPage = (currentPage + 1) % itemCount;
    controller.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _pagePrev(PageController controller, int itemCount) {
    if (!controller.hasClients || itemCount <= 1) return;
    final currentPage = controller.page?.round() ?? controller.initialPage;
    final prevPage = (currentPage - 1 + itemCount) % itemCount;
    controller.animateToPage(
      prevPage,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _eligiblePageController.dispose();
    _recentPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = appState.currentUser;
    final eligibleJobs = appState.eligibleJobs;
    final unreadAlerts = appState.unreadNotificationCount;
    final savedCount = appState.savedJobs.length;

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
            const Text('JobSense'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_outlined),
            tooltip: 'Saved Jobs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedJobsScreen()),
              );
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: unreadAlerts > 0,
              label: Text('$unreadAlerts'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Alerts',
            onPressed: widget.onViewAllAlerts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.syncWithBackend(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.name.split(' ').first ?? 'Candidate'} 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You have ${eligibleJobs.length} verified jobs matching your profile',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Profile Completion Card (only displayed if profile is incomplete < 100%)
              if (user != null && user.completionPercentage < 100) ...[
                ProfileCompletionCard(
                  user: user,
                  onCompleteTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      title: 'Eligible Jobs',
                      count: '${eligibleJobs.length}',
                      icon: Icons.verified,
                      iconColor: const Color(0xFF10B981),
                      onTap: widget.onViewAllJobs,
                      context: context,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      title: 'New Alerts',
                      count: '$unreadAlerts',
                      icon: Icons.notification_important,
                      iconColor: const Color(0xFFF59E0B),
                      onTap: widget.onViewAllAlerts,
                      context: context,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      title: 'Saved',
                      count: '$savedCount',
                      icon: Icons.bookmark,
                      iconColor: const Color(0xFF2B6CB0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SavedJobsScreen()),
                        );
                      },
                      context: context,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // SECTION: Eligible Jobs Preview (Horizontal with Arrow Navigation)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Eligible Job Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Scroll Left
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Scroll left',
                    onPressed: () => _pagePrev(_eligiblePageController, eligibleJobs.length),
                  ),
                  // Scroll Right
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Scroll right',
                    onPressed: () => _pageNext(_eligiblePageController, eligibleJobs.length),
                  ),
                  TextButton(
                    onPressed: widget.onViewAllJobs,
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 265,
                child: eligibleJobs.isEmpty
                    ? const Center(
                        child: Text(
                          'No eligible jobs found for your profile',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    : PageView.builder(
                        controller: _eligiblePageController,
                        padEnds: false,
                        physics: const BouncingScrollPhysics(),
                        itemCount: eligibleJobs.length,
                        itemBuilder: (context, index) {
                          final job = eligibleJobs[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: JobCard(
                              margin: EdgeInsets.zero,
                              job: job,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JobDetailsScreen(job: job),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // SECTION: All Recent Opportunities (Horizontal with Arrow Navigation)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recently Added Opportunities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Scroll Left
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Scroll left',
                    onPressed: () => _pagePrev(_recentPageController, appState.jobs.length),
                  ),
                  // Scroll Right
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Scroll right',
                    onPressed: () => _pageNext(_recentPageController, appState.jobs.length),
                  ),
                  TextButton(
                    onPressed: widget.onViewAllJobs,
                    child: const Text('Explore'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 265,
                child: PageView.builder(
                  controller: _recentPageController,
                  padEnds: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: appState.jobs.length,
                  itemBuilder: (context, index) {
                    final job = appState.jobs.reversed.toList()[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: JobCard(
                        margin: EdgeInsets.zero,
                        job: job,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobDetailsScreen(job: job),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}