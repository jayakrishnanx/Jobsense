import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.work, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('About JobSense'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JobSense v1.0.0 (Frontend Prototype)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'JobSense is a personalized government job notification platform developed for job seekers. '
              'It filters notifications collected from official government portals (UPSC, SSC, State PSCs, RRB, Banking) '
              'and notifies candidates based on their qualification, age, and state criteria.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Developed by an MCA student learning Flutter.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select App Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'മലയാളം (Malayalam)', 'हिन्दी (Hindi)'].map((lang) {
            final isSelected = appState.selectedLanguage.startsWith(lang.split(' ').first);
            return ListTile(
              title: Text(lang),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              onTap: () {
                appState.setLanguage(lang);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language set to $lang'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of JobSense?'),
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
              Navigator.pop(ctx);
              appState.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section
              _buildHeader('APPEARANCE & THEME'),
              Card(
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: appState.isDarkMode,
                  onChanged: (val) {
                    appState.toggleTheme(val);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Notifications Section
              _buildHeader('NOTIFICATIONS & ALERTS'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive instant alerts when jobs are published'),
                      secondary: const Icon(Icons.notifications_active_outlined),
                      value: appState.pushNotificationsEnabled,
                      onChanged: (val) {
                        appState.setPushNotifications(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Only Eligible Job Alerts'),
                      subtitle: const Text('Hide notifications for jobs you do not qualify for'),
                      secondary: const Icon(Icons.filter_alt_outlined),
                      value: appState.eligibleAlertsOnly,
                      onChanged: (val) {
                        appState.setEligibleAlertsOnly(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Deadline Reminders'),
                      subtitle: const Text('Get notified 3 days before application closure'),
                      secondary: const Icon(Icons.alarm_outlined),
                      value: appState.deadlineReminders,
                      onChanged: (val) {
                        appState.setDeadlineReminders(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Preferences Section
              _buildHeader('GENERAL PREFERENCES'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.translate_outlined),
                      title: const Text('App Language'),
                      subtitle: Text(appState.selectedLanguage),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLanguageDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Legal & About Section
              _buildHeader('LEGAL & INFORMATION'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showInfoDialog(
                        context,
                        'Privacy Policy',
                        'JobSense respects your privacy. We collect educational information '
                        '(degree, age, passing year, category, state) solely to evaluate your eligibility '
                        'against official government recruitment notifications. Your information is never sold to third parties.',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showInfoDialog(
                        context,
                        'Terms of Service',
                        'JobSense acts as an informational aggregator and eligibility-checker for government job vacancies. '
                        'Candidates are advised to cross-verify all eligibility conditions and application deadlines with official government gazettes and websites before applying.',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About JobSense'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout Account'),
                onPressed: () => _confirmLogout(context),
              ),

              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
