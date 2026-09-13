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
  final ScrollController _eligibleScrollController = ScrollController();
  final ScrollController _recentScrollController = ScrollController();

  @override
  void dispose() {
    _eligibleScrollController.dispose();
    _recentScrollController.dispose();
    super.dispose();
  }

  void _scrollRight(ScrollController controller) {
    if (controller.hasClients) {
      final target = (controller.offset + 324)
          .clamp(0.0, controller.position.maxScrollExtent);
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollLeft(ScrollController controller) {
    if (controller.hasClients) {
      final target = (controller.offset - 324)
          .clamp(0.0, controller.position.maxScrollExtent);
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.work_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
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
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
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
                  const Text(
                    'Eligible Job Alerts',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Scroll Left
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Scroll left',
                    onPressed: () => _scrollLeft(_eligibleScrollController),
                  ),
                  // Scroll Right
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Scroll right',
                    onPressed: () => _scrollRight(_eligibleScrollController),
                  ),
                  TextButton(
                    onPressed: widget.onViewAllJobs,
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  controller: _eligibleScrollController,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: eligibleJobs.length,
                  itemBuilder: (context, index) {
                    final job = eligibleJobs[index];
                    return JobCard(
                      width: 310,
                      margin: const EdgeInsets.only(right: 14),
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
              ),

              const SizedBox(height: 16),

              // SECTION: All Recent Opportunities (Horizontal with Arrow Navigation)
              Row(
                children: [
                  const Text(
                    'Recently Added Opportunities',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Scroll Left
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Scroll left',
                    onPressed: () => _scrollLeft(_recentScrollController),
                  ),
                  // Scroll Right
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Scroll right',
                    onPressed: () => _scrollRight(_recentScrollController),
                  ),
                  TextButton(
                    onPressed: widget.onViewAllJobs,
                    child: const Text('Explore'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 240,
                child: ListView.builder(
                  controller: _recentScrollController,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: appState.jobs.length,
                  itemBuilder: (context, index) {
                    final job = appState.jobs.reversed.toList()[index];
                    return JobCard(
                      width: 310,
                      margin: const EdgeInsets.only(right: 14),
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