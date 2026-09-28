import 'package:flutter_test/flutter_test.dart';
import 'package:jobsense/app/app.dart';
import 'package:jobsense/data/app_state.dart';
import 'package:jobsense/models/user.dart';
import 'package:jobsense/models/managed_user.dart';
import 'package:jobsense/models/scraped_job.dart';
import 'package:jobsense/models/scraper.dart';

void main() {
  setUp(() {
    // Reset state before tests
    appState.logout();
  });

  group('JobSense Complete Frontend Test Suite', () {
    // TEST 1: Phone: 7012823414, OTP: 123456 -> Existing user -> Home
    test('TEST 1: Existing user login flow with 7012823414', () {
      final isExisting = appState.loginWithPhone('7012823414');
      expect(isExisting, isTrue);
      expect(appState.currentUser, isNotNull);
      expect(appState.currentUser?.phone, '7012823414');
      expect(appState.currentUser?.name, 'Rahul Sharma');
    });

    // TEST 2: Phone: 9876543210, OTP: 123456 -> New user -> Registration -> Home
    test('TEST 2: New user flow with 9876543210 and registration', () {
      final isExisting = appState.loginWithPhone('9876543210');
      expect(isExisting, isFalse);

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
      expect(appState.currentUser?.phone, '9876543210');
      expect(appState.currentUser?.completionPercentage, 100);
    });

    // TEST 3 & 4: Login & Phone validation test
    testWidgets('TEST 3 & 4: Login validation for empty phone', (WidgetTester tester) async {
      await tester.pumpWidget(const JobSenseApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap Get OTP with empty field
      await tester.tap(find.text('Get OTP'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter your phone number'), findsOneWidget);
    });

    // TEST 6: Search job -> Matching jobs displayed
    test('TEST 6: Search job by title and qualification', () {
      final results = appState.jobs.where((j) => j.title.toLowerCase().contains('ssc')).toList();
      expect(results.isNotEmpty, isTrue);
      expect(results.any((j) => j.title.contains('SSC')), isTrue);
    });

    // TEST 7: Apply filter -> Filtered jobs displayed
    test('TEST 7: Filter jobs by Job Type Banking', () {
      final bankingJobs = appState.jobs.where((j) => j.jobType == 'Banking').toList();
      expect(bankingJobs.isNotEmpty, isTrue);
      expect(bankingJobs.every((j) => j.jobType == 'Banking'), isTrue);
    });

    // TEST 8: Open job details -> Eligibility calculation matches user
    test('TEST 8: Eligibility calculation for default candidate', () {
      appState.loginWithPhone('7012823414');
      final sscJob = appState.jobs.firstWhere((j) => j.id == 'job_001');
      final eligibility = sscJob.checkEligibility(appState.currentUser);

      expect(eligibility.isEligible, isTrue);
      expect(eligibility.points.length, greaterThanOrEqualTo(3));

      // Higher qualification (Degree) satisfies 10th level job (Kerala PSC LDC)
      final ldcJob = appState.jobs.firstWhere((j) => j.id == 'job_009');
      final ldcEligibility = ldcJob.checkEligibility(appState.currentUser);
      expect(ldcEligibility.isEligible, isTrue);
      expect(ldcEligibility.points.first.isMet, isTrue);
    });

    // TEST 9: Save job -> Appears in saved jobs
    test('TEST 9: Save job and verify bookmark state', () {
      expect(appState.isJobSaved('job_003'), isFalse);
      appState.toggleSaveJob('job_003');
      expect(appState.isJobSaved('job_003'), isTrue);
      expect(appState.savedJobs.any((j) => j.id == 'job_003'), isTrue);

      // Unsave
      appState.toggleSaveJob('job_003');
      expect(appState.isJobSaved('job_003'), isFalse);
    });

    // TEST 10: Mark notification as read -> Unread count decreases
    test('TEST 10: Mark notification as read', () {
      final initialUnread = appState.unreadNotificationCount;
      expect(initialUnread, greaterThan(0));

      final firstUnread = appState.notifications.firstWhere((n) => !n.isRead);
      appState.markNotificationAsRead(firstUnread.id);

      expect(appState.unreadNotificationCount, initialUnread - 1);
    });

    // TEST 11: Edit profile -> Updates in AppState
    test('TEST 11: Update profile reflection', () {
      appState.loginWithPhone('7012823414');
      final updated = appState.currentUser!.copyWith(name: 'Rahul S. Pillai');
      appState.updateProfile(updated);

      expect(appState.currentUser?.name, 'Rahul S. Pillai');
    });

    // TEST 12: Logout -> Clears currentUser
    test('TEST 12: Logout flow', () {
      appState.loginWithPhone('7012823414');
      expect(appState.currentUser, isNotNull);

      appState.logout();
      expect(appState.currentUser, isNull);
      expect(appState.currentRole, AuthRole.none);
    });

    // TEST 13: Admin username login
    test('TEST 13: Admin username login flow with admin / admin123', () {
      final role = appState.loginWithUsername('admin', 'admin123');
      expect(role, AuthRole.admin);
      expect(appState.currentRole, AuthRole.admin);
      expect(appState.currentAdmin, isNotNull);
      expect(appState.currentAdmin?.username, 'admin');
    });

    // TEST 14: User username login
    test('TEST 14: User username login flow with rahul / rahul123', () {
      final role = appState.loginWithUsername('rahul', 'rahul123');
      expect(role, AuthRole.user);
      expect(appState.currentRole, AuthRole.user);
      expect(appState.currentUser, isNotNull);
      expect(appState.currentUser?.name, 'Rahul Sharma');
    });

    // TEST 15: Invalid username credentials
    test('TEST 15: Invalid credentials return AuthRole.none', () {
      final role = appState.loginWithUsername('invalidUser', 'wrongPass');
      expect(role, AuthRole.none);
      expect(appState.currentRole, AuthRole.none);
    });

    // TEST 16: Admin mobile OTP login
    test('TEST 16: Admin phone login flow with 9999999999', () {
      final isExisting = appState.loginWithPhone('9999999999');
      expect(isExisting, isTrue);
      expect(appState.currentRole, AuthRole.admin);
      expect(appState.currentAdmin, isNotNull);
    });

    // TEST 17: Scraper management - toggle and execute
    test('TEST 17: Scraper management toggle and manual execution', () async {
      final initialStatus = appState.scrapers.first.status;
      appState.toggleScraperStatus(appState.scrapers.first.id);
      expect(appState.scrapers.first.status != initialStatus, isTrue);

      final initialJobsCollected = appState.scrapers.first.jobsCollected;
      await appState.runScraper(appState.scrapers.first.id);
      expect(appState.scrapers.first.jobsCollected, greaterThan(initialJobsCollected));
      expect(appState.scrapers.first.status, ScraperStatus.active);
    });

    // TEST 18: Scraped job approval
    test('TEST 18: Scraped job approval publishes to active jobs', () {
      final pendingJob = appState.scrapedJobs.firstWhere(
        (j) => j.reviewStatus == ScrapedJobReviewStatus.pending,
      );
      final initialJobCount = appState.jobs.length;

      appState.approveScrapedJob(pendingJob.id);

      final updatedJob = appState.scrapedJobs.firstWhere((j) => j.id == pendingJob.id);
      expect(updatedJob.reviewStatus, ScrapedJobReviewStatus.approved);
      expect(appState.jobs.length, initialJobCount + 1);
    });

    // TEST 19: Scraped job rejection
    test('TEST 19: Scraped job rejection with reason', () {
      final pendingJob = appState.scrapedJobs.firstWhere(
        (j) => j.reviewStatus == ScrapedJobReviewStatus.pending,
      );

      appState.rejectScrapedJob(pendingJob.id, 'Duplicate notice');

      final updatedJob = appState.scrapedJobs.firstWhere((j) => j.id == pendingJob.id);
      expect(updatedJob.reviewStatus, ScrapedJobReviewStatus.rejected);
      expect(updatedJob.rejectionReason, 'Duplicate notice');
    });

    // TEST 20: User block and unblock
    test('TEST 20: Candidate suspension toggle', () {
      final user = appState.managedUsers.first;
      expect(user.status, UserAccountStatus.active);

      appState.toggleUserBlock(user.id, 'Test suspension');
      expect(appState.managedUsers.first.status, UserAccountStatus.blocked);

      appState.toggleUserBlock(user.id);
      expect(appState.managedUsers.first.status, UserAccountStatus.active);
    });
  });
}
