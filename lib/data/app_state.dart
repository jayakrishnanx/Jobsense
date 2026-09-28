import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../models/job.dart';
import '../models/managed_user.dart';
import '../models/notification.dart';
import '../models/scraped_job.dart';
import '../models/scraper.dart';
import '../models/system_log.dart';
import '../models/user.dart';
import 'dummy_data.dart';

enum AuthRole { none, user, admin }

class AppState extends ChangeNotifier {
  User? _currentUser;
  AdminUser? _currentAdmin;
  AuthRole _currentRole = AuthRole.user; // Default demo session

  final List<Job> _jobs = List.from(DummyData.jobs);
  final Set<String> _savedJobIds = {'job_001', 'job_002'};
  final List<JobNotification> _notifications = List.from(DummyData.initialNotifications);

  // Admin datasets
  final List<Scraper> _scrapers = List.from(DummyData.initialScrapers);
  final List<ScrapedJob> _scrapedJobs = List.from(DummyData.initialScrapedJobs);
  final List<ManagedUser> _managedUsers = List.from(DummyData.initialManagedUsers);
  final List<SystemLog> _systemLogs = List.from(DummyData.initialSystemLogs);

  bool _isDarkMode = false;

  // Settings preferences
  bool _pushNotificationsEnabled = true;
  bool _eligibleAlertsOnly = true;
  bool _deadlineReminders = true;
  String _selectedLanguage = 'English';

  AppState() {
    // Default logged in with existing demo user for convenience
    _currentUser = DummyData.defaultExistingUser;
    _currentRole = AuthRole.user;
  }

  // Getters
  User? get currentUser => _currentUser;
  AdminUser? get currentAdmin => _currentAdmin;
  AuthRole get currentRole => _currentRole;

  List<Job> get jobs => List.unmodifiable(_jobs);
  Set<String> get savedJobIds => Set.unmodifiable(_savedJobIds);
  List<JobNotification> get notifications => List.unmodifiable(_notifications);

  // Admin getters
  List<Scraper> get scrapers => List.unmodifiable(_scrapers);
  List<ScrapedJob> get scrapedJobs => List.unmodifiable(_scrapedJobs);
  List<ManagedUser> get managedUsers => List.unmodifiable(_managedUsers);
  List<SystemLog> get systemLogs => List.unmodifiable(_systemLogs);

  int get totalScrapers => _scrapers.length;
  int get activeScrapersCount => _scrapers.where((s) => s.status == ScraperStatus.active).length;
  int get failedScrapersCount => _scrapers.where((s) => s.status == ScraperStatus.failed).length;
  int get pendingScrapedJobsCount => _scrapedJobs.where((s) => s.reviewStatus == ScrapedJobReviewStatus.pending).length;
  int get approvedScrapedJobsCount => _scrapedJobs.where((s) => s.reviewStatus == ScrapedJobReviewStatus.approved).length;

  bool get isDarkMode => _isDarkMode;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get eligibleAlertsOnly => _eligibleAlertsOnly;
  bool get deadlineReminders => _deadlineReminders;
  String get selectedLanguage => _selectedLanguage;

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  List<Job> get savedJobs =>
      _jobs.where((j) => _savedJobIds.contains(j.id)).toList();

  List<Job> get eligibleJobs {
    if (_currentUser == null) return _jobs;
    return _jobs.where((j) => j.checkEligibility(_currentUser).isEligible).toList();
  }

  Job? getJobById(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);

  // Authentication Actions

  /// Mobile OTP login:
  /// - '7012823414' -> Existing User
  /// - '9999999999' -> Demo Admin
  /// - Any other -> New User (returns false)
  bool loginWithPhone(String phone) {
    final cleaned = phone.trim();
    if (cleaned == '7012823414') {
      _currentUser = DummyData.defaultExistingUser;
      _currentAdmin = null;
      _currentRole = AuthRole.user;
      notifyListeners();
      return true; // Existing user
    } else if (cleaned == '9999999999') {
      _currentAdmin = DummyData.defaultAdmin;
      _currentUser = null;
      _currentRole = AuthRole.admin;
      addSystemLog(SystemLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: 'Just now',
        eventType: 'Authentication',
        description: 'Admin phone OTP session verified (+91 9999999999).',
        level: LogLevel.success,
        source: 'Auth System',
      ));
      notifyListeners();
      return true; // Existing admin
    }
    _currentRole = AuthRole.none;
    return false; // New user -> proceeds to Registration
  }

  /// Username + Password login:
  /// - 'admin' / 'admin123' -> Admin
  /// - 'rahul' / 'rahul123' -> User
  /// - Invalid credentials -> returns AuthRole.none
  AuthRole loginWithUsername(String username, String password) {
    final u = username.trim().toLowerCase();
    final p = password.trim();

    if (u == 'admin' && p == 'admin123') {
      _currentRole = AuthRole.admin;
      _currentAdmin = DummyData.defaultAdmin;
      _currentUser = null;
      addSystemLog(SystemLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: 'Just now',
        eventType: 'Authentication',
        description: 'Admin signed in with credentials (admin).',
        level: LogLevel.success,
        source: 'Auth System',
      ));
      notifyListeners();
      return AuthRole.admin;
    } else if (u == 'rahul' && p == 'rahul123') {
      _currentRole = AuthRole.user;
      _currentUser = DummyData.defaultExistingUser;
      _currentAdmin = null;
      addSystemLog(SystemLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: 'Just now',
        eventType: 'Authentication',
        description: 'User signed in with credentials (rahul).',
        level: LogLevel.info,
        source: 'Auth System',
      ));
      notifyListeners();
      return AuthRole.user;
    }

    return AuthRole.none;
  }

  void registerUser(User user) {
    _currentUser = user;
    _currentRole = AuthRole.user;
    _currentAdmin = null;
    notifyListeners();
  }

  void updateProfile(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _currentAdmin = null;
    _currentRole = AuthRole.none;
    notifyListeners();
  }

  // Bookmarking / Saved Jobs
  void toggleSaveJob(String jobId) {
    if (_savedJobIds.contains(jobId)) {
      _savedJobIds.remove(jobId);
    } else {
      _savedJobIds.add(jobId);
    }
    notifyListeners();
  }

  // Notifications
  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // Admin Actions: Scrapers
  void toggleScraperStatus(String id) {
    final index = _scrapers.indexWhere((s) => s.id == id);
    if (index != -1) {
      final current = _scrapers[index];
      final newStatus = current.status == ScraperStatus.active
          ? ScraperStatus.inactive
          : ScraperStatus.active;
      _scrapers[index] = current.copyWith(status: newStatus);

      addSystemLog(SystemLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: 'Just now',
        eventType: 'Scraper Config',
        description: '${current.name} was ${newStatus == ScraperStatus.active ? "enabled" : "disabled"} by Admin.',
        level: LogLevel.info,
        source: current.name,
      ));

      notifyListeners();
    }
  }

  Future<void> runScraper(String id) async {
    final index = _scrapers.indexWhere((s) => s.id == id);
    if (index != -1) {
      final current = _scrapers[index];
      // Simulate run latency
      await Future.delayed(const Duration(milliseconds: 900));

      final newJobsCount = current.jobsCollected + 2;
      _scrapers[index] = current.copyWith(
        status: ScraperStatus.active,
        lastRun: 'Just now',
        jobsCollected: newJobsCount,
        lastError: null,
      );

      addSystemLog(SystemLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: 'Just now',
        eventType: 'Scraper Run',
        description: 'Manual run executed for ${current.name}. 2 new announcements detected.',
        level: LogLevel.success,
        source: current.name,
      ));

      notifyListeners();
    }
  }

  // Admin Actions: Scraped Jobs Review
  void approveScrapedJob(String id) {
    final index = _scrapedJobs.indexWhere((j) => j.id == id);
    if (index != -1) {
      final scraped = _scrapedJobs[index];
      _scrapedJobs[index] = scraped.copyWith(
        reviewStatus: ScrapedJobReviewStatus.approved,
        rejectionReason: null,
      );

      // Create new live job from approved scraped job if not existing
      final liveJobId = 'live_${scraped.id}';
      if (!_jobs.any((j) => j.id == liveJobId)) {
        final newLiveJob = Job(
          id: liveJobId,
          title: scraped.title,
          organization: scraped.organization,
          department: 'Approved Government Notice',
          jobType: 'Central / State Govt',
          location: scraped.location,
          vacancies: scraped.vacancies,
          qualification: scraped.qualification,
          courseRequirements: 'Relevant qualification required',
          ageMin: 18,
          ageMax: 35,
          category: 'All Categories',
          experience: 'Fresher / Experienced',
          applicationStartDate: scraped.scrapedDate,
          lastDate: scraped.lastDate,
          applicationFee: 'As per official notification',
          selectionProcess: 'Computer Based Test / Interview',
          salary: scraped.salary,
          description: '${scraped.title} released by ${scraped.organization}. Verified and approved by JobSense Administration.',
          officialNotificationUrl: scraped.officialUrl,
        );
        _jobs.insert(0, newLiveJob);
      }

      addSystemLog(SystemLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: 'Just now',
        eventType: 'Job Approval',
        description: 'Approved scraped job: "${scraped.title}". Pushed to candidate eligibility matching.',
        level: LogLevel.success,
        source: 'Job Moderation',
      ));

      notifyListeners();
    }
  }

  void rejectScrapedJob(String id, [String? reason]) {
    final index = _scrapedJobs.indexWhere((j) => j.id == id);
    if (index != -1) {
      final scraped = _scrapedJobs[index];
      _scrapedJobs[index] = scraped.copyWith(
        reviewStatus: ScrapedJobReviewStatus.rejected,
        rejectionReason: reason ?? 'Rejected by Admin review',
      );

      addSystemLog(SystemLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: 'Just now',
        eventType: 'Job Rejection',
        description: 'Rejected job announcement: "${scraped.title}". Reason: ${reason ?? "Criteria not satisfied"}.',
        level: LogLevel.warning,
        source: 'Job Moderation',
      ));

      notifyListeners();
    }
  }

  void editScrapedJob(ScrapedJob updatedJob) {
    final index = _scrapedJobs.indexWhere((j) => j.id == updatedJob.id);
    if (index != -1) {
      _scrapedJobs[index] = updatedJob;

      addSystemLog(SystemLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: 'Just now',
        eventType: 'Job Edit',
        description: 'Admin modified metadata for job "${updatedJob.title}".',
        level: LogLevel.info,
        source: 'Job Moderation',
      ));

      notifyListeners();
    }
  }

  void deleteScrapedJob(String id) {
    final job = _scrapedJobs.firstWhere((j) => j.id == id, orElse: () => _scrapedJobs.first);
    _scrapedJobs.removeWhere((j) => j.id == id);

    addSystemLog(SystemLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: 'Just now',
      eventType: 'Job Deletion',
      description: 'Removed scraped job entry: "${job.title}".',
      level: LogLevel.warning,
      source: 'Job Moderation',
    ));

    notifyListeners();
  }

  // Admin Actions: Users
  void toggleUserBlock(String userId, [String? reason]) {
    final index = _managedUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _managedUsers[index];
      final newStatus = user.status == UserAccountStatus.active
          ? UserAccountStatus.blocked
          : UserAccountStatus.active;

      _managedUsers[index] = user.copyWith(
        status: newStatus,
        blockReason: newStatus == UserAccountStatus.blocked ? (reason ?? 'Suspended by Admin') : null,
      );

      addSystemLog(SystemLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: 'Just now',
        eventType: 'User Status',
        description: 'Candidate ${user.name} (${user.phone}) account status changed to ${newStatus.name.toUpperCase()}.',
        level: newStatus == UserAccountStatus.blocked ? LogLevel.warning : LogLevel.success,
        source: 'User Management',
      ));

      notifyListeners();
    }
  }

  // Admin Actions: Logs
  void addSystemLog(SystemLog log) {
    _systemLogs.insert(0, log);
    if (_systemLogs.length > 50) {
      _systemLogs.removeLast();
    }
    notifyListeners();
  }

  void clearSystemLogs() {
    _systemLogs.clear();
    notifyListeners();
  }

  // Settings
  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  void setPushNotifications(bool val) {
    _pushNotificationsEnabled = val;
    notifyListeners();
  }

  void setEligibleAlertsOnly(bool val) {
    _eligibleAlertsOnly = val;
    notifyListeners();
  }

  void setDeadlineReminders(bool val) {
    _deadlineReminders = val;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }
}

// Global shared instance for the app
final AppState appState = AppState();
