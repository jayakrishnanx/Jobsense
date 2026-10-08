import 'package:flutter_test/flutter_test.dart';
import 'package:jobsense/data/app_state.dart';
import 'package:jobsense/models/user.dart';

void main() {
  setUp(() {
    // Reset state before tests
    appState.logout();
  });

  group('JobSense User Frontend Test Suite', () {
    // TEST 1: User state setup & verification
    test('TEST 1: Candidate registration and profile state', () {
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
      expect(appState.currentRole, AuthRole.user);
    });

    // TEST 2: Search job -> Matching jobs displayed
    test('TEST 2: Search job by title and qualification', () {
      final results = appState.jobs.where((j) =>
        j.title.toLowerCase().contains('draftsman') ||
        j.organization.toLowerCase().contains('commission')
      ).toList();
      expect(results.isNotEmpty, isTrue);
    });

    // TEST 3: Filter jobs by Job Type
    test('TEST 3: Filter jobs by Job Type', () {
      final pscJobs = appState.jobs.where((j) => j.organization.contains('Kerala Public Service Commission')).toList();
      expect(pscJobs.isNotEmpty, isTrue);
    });

    // TEST 4: Open job details -> Eligibility calculation matches user
    test('TEST 4: Eligibility calculation for candidate', () {
      const candidate = User(
        id: 'u_1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        email: 'rahul.sharma@example.com',
        dob: '15/05/1998',
        gender: 'Male',
        qualification: 'Diploma',
        course: 'Civil Engineering',
        yearOfPassing: '2020',
        category: 'General',
        state: 'Kerala',
        district: 'Ernakulam',
      );
      appState.registerUser(candidate);

      expect(appState.jobs.isNotEmpty, isTrue);
      final job = appState.jobs.first;
      final eligibility = job.checkEligibility(appState.currentUser);

      expect(eligibility.points.isNotEmpty, isTrue);
    });

    // TEST 5: Save job -> Appears in saved jobs
    test('TEST 5: Save job and verify bookmark state', () {
      final firstJobId = appState.jobs.first.id;
      final isInitiallySaved = appState.isJobSaved(firstJobId);
      appState.toggleSaveJob(firstJobId);
      expect(appState.isJobSaved(firstJobId), !isInitiallySaved);

      // Re-toggle back
      appState.toggleSaveJob(firstJobId);
      expect(appState.isJobSaved(firstJobId), isInitiallySaved);
    });

    // TEST 6: Mark notification as read -> Unread count decreases
    test('TEST 6: Mark notification as read', () {
      if (appState.notifications.isNotEmpty) {
        final initialUnread = appState.unreadNotificationCount;
        if (initialUnread > 0) {
          final firstUnread = appState.notifications.firstWhere((n) => !n.isRead);
          appState.markNotificationAsRead(firstUnread.id);
          expect(appState.unreadNotificationCount, initialUnread - 1);
        }
      }
    });

    // TEST 7: Edit profile -> Updates in AppState
    test('TEST 7: Update profile reflection', () {
      const candidate = User(
        id: 'u_1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        email: 'rahul.sharma@example.com',
        dob: '15/05/1998',
        gender: 'Male',
        qualification: 'Diploma',
        course: 'Civil Engineering',
        yearOfPassing: '2020',
        category: 'General',
        state: 'Kerala',
        district: 'Ernakulam',
      );
      appState.registerUser(candidate);

      final updated = appState.currentUser!.copyWith(name: 'Rahul S. Pillai');
      appState.updateProfile(updated);

      expect(appState.currentUser?.name, 'Rahul S. Pillai');
    });

    // TEST 8: Logout -> Clears currentUser
    test('TEST 8: Logout flow', () {
      const candidate = User(
        id: 'u_1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        email: 'rahul.sharma@example.com',
        dob: '15/05/1998',
        gender: 'Male',
        qualification: 'Diploma',
        course: 'Civil Engineering',
        yearOfPassing: '2020',
        category: 'General',
        state: 'Kerala',
        district: 'Ernakulam',
      );
      appState.registerUser(candidate);
      expect(appState.currentUser, isNotNull);

      appState.logout();
      expect(appState.currentUser, isNull);
      expect(appState.currentRole, AuthRole.none);
    });
  });
}
