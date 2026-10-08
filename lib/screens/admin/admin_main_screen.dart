import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import 'admin_dashboard_screen.dart';
import 'scraper_management_screen.dart';
import 'scraped_jobs_screen.dart';
import 'user_management_screen.dart';
import 'system_logs_screen.dart';
import 'admin_settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  final int initialIndex;

  const AdminMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

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
        final isWideScreen = MediaQuery.of(context).size.width >= 720;

        final List<Widget> pages = [
          AdminDashboardScreen(
            onNavigateToTab: _onTabSelected,
          ),
          const ScraperManagementScreen(),
          const ScrapedJobsScreen(),
          const UserManagementScreen(),
          const SystemLogsScreen(),
          const AdminSettingsScreen(),
        ];

        if (isWideScreen) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onTabSelected,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.language),
                      selectedIcon: Icon(Icons.language),
                      label: Text('Scrapers'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.fact_check_outlined),
                      selectedIcon: Icon(Icons.fact_check),
                      label: Text('Scraped Jobs'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Users'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.article_outlined),
                      selectedIcon: Icon(Icons.article),
                      label: Text('Logs'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout: Bottom NavigationBar + quick Settings shortcut
        final pendingCount = appState.pendingScrapedJobsCount;
        final failedCount = appState.failedScrapersCount;

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
            onDestinationSelected: _onTabSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: failedCount > 0,
                  backgroundColor: Colors.red,
                  label: Text('$failedCount'),
                  child: const Icon(Icons.language),
                ),
                selectedIcon: Badge(
                  isLabelVisible: failedCount > 0,
                  backgroundColor: Colors.red,
                  label: Text('$failedCount'),
                  child: const Icon(Icons.language),
                ),
                label: 'Scrapers',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  backgroundColor: const Color(0xFFF59E0B),
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.fact_check_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingCount > 0,
                  backgroundColor: const Color(0xFFF59E0B),
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.fact_check),
                ),
                label: 'Jobs',
              ),
              const NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Users',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
