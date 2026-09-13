import 'package:flutter_test/flutter_test.dart';
import 'package:jobsense/app/app.dart';
import 'package:jobsense/data/app_state.dart';
import 'package:jobsense/models/user.dart';

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
    });
  });
}
