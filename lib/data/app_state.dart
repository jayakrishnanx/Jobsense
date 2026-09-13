import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/notification.dart';
import '../models/user.dart';
import 'dummy_data.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  final List<Job> _jobs = List.from(DummyData.jobs);
  final Set<String> _savedJobIds = {'job_001', 'job_002'};
  final List<JobNotification> _notifications = List.from(DummyData.initialNotifications);
  bool _isDarkMode = false;

  // Settings preferences
  bool _pushNotificationsEnabled = true;
  bool _eligibleAlertsOnly = true;
  bool _deadlineReminders = true;
  String _selectedLanguage = 'English';

  AppState() {
    // Default logged in with existing demo user for convenience
    _currentUser = DummyData.defaultExistingUser;
  }

  // Getters
  User? get currentUser => _currentUser;
  List<Job> get jobs => List.unmodifiable(_jobs);
  Set<String> get savedJobIds => Set.unmodifiable(_savedJobIds);
  List<JobNotification> get notifications => List.unmodifiable(_notifications);
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

  // Authentication & Profile Actions
  bool loginWithPhone(String phone) {
    if (phone.trim() == '7012823414') {
      _currentUser = DummyData.defaultExistingUser;
      notifyListeners();
      return true; // Existing user
    }
    return false; // New user
  }

  void registerUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateProfile(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
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
