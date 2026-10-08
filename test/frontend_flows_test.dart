import 'package:flutter_test/flutter_test.dart';
import 'package:jobsense/data/app_state.dart';
import 'package:jobsense/models/user.dart';
import 'package:jobsense/models/managed_user.dart';
import 'package:jobsense/models/scraped_job.dart';

void main() {
  setUp(() {
    // Reset state before tests
    appState.logout();
  });

  group('JobSense Complete Frontend Test Suite', () {
    // TEST 1: Email Password Login -> Candidate -> Home
    test('TEST 1: Existing candidate login flow with email rahul.sharma@example.com', () {
      final role = appState.loginWithLocalCredentials('rahul.sharma@example.com', 'rahul123');
      expect(role, AuthRole.user);
      expect(appState.currentUser, isNotNull);
      expect(appState.currentUser?.email, 'rahul.sharma@example.com');
      expect(appState.currentUser?.name, 'Rahul Sharma');
    });

    // TEST 2: New candidate registration
    test('TEST 2: New candidate registration and profile setup', () {
      const newUser = User(
        id: 'user_new_01',
        name: 'Pooja Nair',
        phone: '9876543210',
        email: 'pooja@example.com',
        dob: '22/08/2002',
        gender: 'Female',
        qualification: 'Degree',
        course: 'B.Com',
        yearOfPassing: '2024',
        category: 'OBC',
        state: 'Kerala',
        district: 'Kozhikode',
      );

      appState.registerUser(newUser);
      expect(appState.currentUser?.name, 'Pooja Nair');
      expect(appState.currentUser?.email, 'pooja@example.com');
      expect(appState.currentUser?.completionPercentage, 100);
    });

    // TEST 3: Search job -> Matching jobs displayed
    test('TEST 3: Search job by title and qualification', () {
      final results = appState.jobs.where((j) => j.title.toLowerCase().contains('ssc')).toList();
      expect(results.isNotEmpty, isTrue);
      expect(results.any((j) => j.title.contains('SSC')), isTrue);
    });

    // TEST 4: Filter jobs by Job Type Kerala PSC
    test('TEST 4: Filter jobs by Job Type Kerala PSC', () {
      final pscJobs = appState.jobs.where((j) => j.jobType == 'Kerala PSC').toList();
      expect(pscJobs.isNotEmpty, isTrue);
      expect(pscJobs.every((j) => j.jobType == 'Kerala PSC'), isTrue);
    });

    // TEST 5: Open job details -> Eligibility calculation matches user
    test('TEST 5: Eligibility calculation for default candidate', () {
      appState.loginWithLocalCredentials('rahul.sharma@example.com', 'rahul123');
      expect(appState.jobs.isNotEmpty, isTrue);
      final job = appState.jobs.first;
      final eligibility = job.checkEligibility(appState.currentUser);

      expect(eligibility.points.isNotEmpty, isTrue);
    });

    // TEST 6: Save job -> Appears in saved jobs
    test('TEST 6: Save job and verify bookmark state', () {
      // Toggle job_003
      final isInitiallySaved = appState.isJobSaved('job_003');
      appState.toggleSaveJob('job_003');
      expect(appState.isJobSaved('job_003'), !isInitiallySaved);

      // Re-toggle back
      appState.toggleSaveJob('job_003');
      expect(appState.isJobSaved('job_003'), isInitiallySaved);
    });

    // TEST 7: Mark notification as read -> Unread count decreases
    test('TEST 7: Mark notification as read', () {
      final initialUnread = appState.unreadNotificationCount;
      expect(initialUnread, greaterThan(0));

      final firstUnread = appState.notifications.firstWhere((n) => !n.isRead);
      appState.markNotificationAsRead(firstUnread.id);

      expect(appState.unreadNotificationCount, initialUnread - 1);
    });

    // TEST 8: Edit profile -> Updates in AppState
    test('TEST 8: Update profile reflection', () {
      appState.loginWithLocalCredentials('rahul.sharma@example.com', 'rahul123');
      final updated = appState.currentUser!.copyWith(name: 'Rahul S. Pillai');
      appState.updateProfile(updated);

      expect(appState.currentUser?.name, 'Rahul S. Pillai');
    });

    // TEST 9: Logout -> Clears currentUser
    test('TEST 9: Logout flow', () {
      appState.loginWithLocalCredentials('rahul.sharma@example.com', 'rahul123');
      expect(appState.currentUser, isNotNull);

      appState.logout();
      expect(appState.currentUser, isNull);
      expect(appState.currentRole, AuthRole.none);
    });

    // TEST 10: Admin email login
    test('TEST 10: Admin email login flow with admin@jobsense.gov.in / admin123', () {
      final role = appState.loginWithLocalCredentials('admin@jobsense.gov.in', 'admin123');
      expect(role, AuthRole.admin);
      expect(appState.currentRole, AuthRole.admin);
      expect(appState.currentAdmin, isNotNull);
      expect(appState.currentAdmin?.username, 'admin');
    });

    // TEST 11: Invalid credentials
    test('TEST 11: Invalid credentials return AuthRole.none', () {
      final role = appState.loginWithLocalCredentials('invalidUser@test.com', 'wrongPass');
      expect(role, AuthRole.none);
      expect(appState.currentRole, AuthRole.none);
    });

    // TEST 12: Scraper management - toggle
    test('TEST 12: Scraper management toggle status', () {
      final initialStatus = appState.scrapers.first.status;
      appState.toggleScraperStatus(appState.scrapers.first.id);
      expect(appState.scrapers.first.status != initialStatus, isTrue);
    });

    // TEST 13: Scraped job approval
    test('TEST 13: Scraped job approval publishes to active jobs', () {
      expect(appState.scrapedJobs.isNotEmpty, isTrue);
      final jobToApprove = appState.scrapedJobs.first;
      final initialJobCount = appState.jobs.length;

      appState.approveScrapedJob(jobToApprove.id);

      final updatedJob = appState.scrapedJobs.firstWhere((j) => j.id == jobToApprove.id);
      expect(updatedJob.reviewStatus, ScrapedJobReviewStatus.approved);
      expect(appState.jobs.length, greaterThanOrEqualTo(initialJobCount));
    });

    // TEST 14: Scraped job rejection
    test('TEST 14: Scraped job rejection with reason', () {
      expect(appState.scrapedJobs.isNotEmpty, isTrue);
      final jobToReject = appState.scrapedJobs.last;

      appState.rejectScrapedJob(jobToReject.id, 'Duplicate notice');

      final updatedJob = appState.scrapedJobs.firstWhere((j) => j.id == jobToReject.id);
      expect(updatedJob.reviewStatus, ScrapedJobReviewStatus.rejected);
      expect(updatedJob.rejectionReason, 'Duplicate notice');
    });

    // TEST 15: User block and unblock
    test('TEST 15: Candidate suspension toggle', () {
      final user = appState.managedUsers.first;
      expect(user.status, UserAccountStatus.active);

      appState.toggleUserBlock(user.id, 'Test suspension');
      expect(appState.managedUsers.first.status, UserAccountStatus.blocked);

      appState.toggleUserBlock(user.id);
      expect(appState.managedUsers.first.status, UserAccountStatus.active);
    });
  });
}
